Describe 'BigZ.Tweaks com adaptador em memória' {
    BeforeAll {
        $root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
        Import-Module (Join-Path $root 'shared/modules/BigZ.Tweaks/BigZ.Tweaks.psd1') -Force -ErrorAction Stop

        function Get-TestTweakFixture {
            param(
                [string]$Id = 'explorer.show-extensions',
                [string]$Name = 'HideFileExt',
                [int]$Value = 0,
                [string[]]$DependsOn = @(),
                [string[]]$ConflictsWith = @()
            )
            [pscustomobject]@{
                schemaVersion = 1
                id = $Id
                description = 'Teste de preferência.'
                risk = 'low'
                securityImpact = 'none'
                source = 'https://example.test/preference'
                editions = @('dev', 'balanced')
                phase = 'online'
                scope = 'currentUser'
                requires = @{ builds = @(26200); architectures = @('x64'); admin = $false }
                dependsOn = $DependsOn
                conflictsWith = $ConflictsWith
                action = [pscustomobject]@{
                    type = 'registry.setValue'
                    key = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                    name = $Name
                    valueType = 'DWord'
                    value = $Value
                }
                verify = @{ type = 'registry.matchesAction' }
                rollback = @{ type = 'restoreSnapshot' }
                restart = 'none'
            }
        }

        function Save-TestTweak {
            param($Tweak, [string]$Directory)
            $Tweak | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $Directory "$($Tweak.id).json") -Encoding UTF8
        }

        function Get-TestBackendFixture {
            $memory = @{
                Values = @{ HideFileExt = 1; Hidden = 2 }
                Calls = [Collections.Generic.List[string]]::new()
                Failure = ''
                JournalPath = ''
                MissingKey = $false
                ValueType = 'DWord'
            }

            $reader = {
                param($Action)
                if ($memory.MissingKey) {
                    return [pscustomobject]@{ KeyExists = $false; Exists = $false; ValueType = $null; Value = $null }
                }
                if ($memory.Values.ContainsKey($Action.name)) {
                    return [pscustomobject]@{
                        KeyExists = $true; Exists = $true; ValueType = $memory.ValueType; Value = $memory.Values[$Action.name]
                    }
                }
                [pscustomobject]@{ KeyExists = $true; Exists = $false; ValueType = $null; Value = $null }
            }.GetNewClosure()

            $writer = {
                param($Action, $State)
                $memory.Calls.Add($Action.name)
                if ($memory.JournalPath) {
                    $journal = Get-Content -LiteralPath $memory.JournalPath -Raw -Encoding UTF8 | ConvertFrom-Json
                    if ('Prepared' -notin $journal.Entries.Status -and 'Reverting' -notin $journal.Entries.Status) {
                        throw 'MUTACAO SEM DIARIO'
                    }
                }
                if ($memory.Failure -eq 'before') { throw 'Falha simulada antes da escrita.' }
                if ($State.Exists) {
                    $memory.Values[$Action.name] = $State.Value
                }
                else {
                    $memory.Values.Remove($Action.name)
                }
                if ($memory.Failure -eq 'after') { throw 'Falha simulada após a escrita.' }
            }.GetNewClosure()

            [pscustomobject]@{
                Memory = $memory
                Adapter = [pscustomobject]@{
                    TargetId = "fake:$([guid]::NewGuid())"
                    Context = [pscustomobject]@{ Build = 26200; Architecture = 'x64'; WindowsEdition = 'Professional' }
                    ReadState = $reader
                    WriteState = $writer
                }
            }
        }
    }

    BeforeEach {
        $journalPath = Join-Path $TestDrive "$([guid]::NewGuid()).json"
        $tweak = Get-TestTweakFixture
        $backend = Get-TestBackendFixture
        $backend.Memory.JournalPath = $journalPath
        $planOptions = @{
            CatalogPath = Join-Path $TestDrive ([guid]::NewGuid().ToString())
            Edition = 'dev'
            Id = $tweak.id
            Adapter = $backend.Adapter
        }
        [void][IO.Directory]::CreateDirectory($planOptions.CatalogPath)
        Save-TestTweak $tweak $planOptions.CatalogPath
    }

    It 'planeja em modo declarativo sem acessar o adaptador' {
        $backend.Adapter.ReadState = { throw 'Leitura inesperada' }
        $plan = Get-BigZTweakPlan @planOptions -DeclarationOnly
        $plan.IsValid | Should Be $true
        $plan.CanApply | Should Be $false
        $plan.Items[0].Status | Should Be 'Declared'
        $plan.Items[0].Source | Should Be $tweak.source
    }

    It 'mostra o estado e preserva registro falso e diário em dry-run e WhatIf' {
        $plan = Invoke-BigZTweak @planOptions -DryRun -JournalPath $journalPath
        $plan.Items[0].Current.Value | Should Be 1
        $plan.Items[0].Desired.Value | Should Be 0
        (Test-BigZTweak @planOptions).Satisfied | Should Be $false
        $null = Invoke-BigZTweak @planOptions -WhatIf -JournalPath $journalPath
        $backend.Memory.Calls.Count | Should Be 0
        (Test-Path -LiteralPath $journalPath) | Should Be $false
    }

    It 'persiste snapshot antes de aplicar, verifica e reverte o valor original' {
        $result = Invoke-BigZTweak @planOptions -JournalPath $journalPath
        $result.Succeeded | Should Be $true
        $result.Entries[0].Before.Value | Should Be 1
        (Test-BigZTweak @planOptions).Satisfied | Should Be $true
        $undo = Undo-BigZTweak -JournalPath $journalPath -Adapter $backend.Adapter
        $undo.Succeeded | Should Be $true
        $backend.Memory.Values.HideFileExt | Should Be 1
    }

    It 'reverte um valor originalmente ausente e é idempotente ao reaplicar o mesmo diário' {
        $backend.Memory.Values.Remove('HideFileExt')
        $null = Invoke-BigZTweak @planOptions -JournalPath $journalPath
        $same = Invoke-BigZTweak @planOptions -JournalPath $journalPath
        $same.Entries[0].Before.Exists | Should Be $false
        $backend.Memory.Calls.Count | Should Be 1
        $null = Undo-BigZTweak -JournalPath $journalPath -Adapter $backend.Adapter
        $null = Undo-BigZTweak -JournalPath $journalPath -Adapter $backend.Adapter
        $backend.Memory.Values.ContainsKey('HideFileExt') | Should Be $false
        $backend.Memory.Calls.Count | Should Be 2
    }

    It 'preserva um valor que já estava no estado desejado' {
        $backend.Memory.Values.HideFileExt = 0
        $result = Invoke-BigZTweak @planOptions -JournalPath $journalPath
        $result.Entries[0].Status | Should Be 'NoChange'
        $null = Undo-BigZTweak -JournalPath $journalPath -Adapter $backend.Adapter
        $backend.Memory.Calls.Count | Should Be 0
    }

    It 'preserva alterações externas e informa conflito' {
        $null = Invoke-BigZTweak @planOptions -JournalPath $journalPath
        $backend.Memory.Values.HideFileExt = 9
        $preview = Undo-BigZTweak -JournalPath $journalPath -Adapter $backend.Adapter -DryRun
        $preview.Entries[0].Current.Value | Should Be 9
        $undo = Undo-BigZTweak -JournalPath $journalPath -Adapter $backend.Adapter
        $undo.Succeeded | Should Be $false
        $undo.Diagnostics[0].Id | Should Be $tweak.id
        $backend.Memory.Values.HideFileExt | Should Be 9
    }

    It 'retoma após a escrita interrompida com o snapshot original' {
        $backend.Memory.Failure = 'after'
        { Invoke-BigZTweak @planOptions -JournalPath $journalPath } | Should Throw
        $journal = Get-Content -LiteralPath $journalPath -Raw | ConvertFrom-Json
        $journal.Entries[0].Status | Should Be 'Prepared'
        $journal.Entries[0].Before.Value | Should Be 1
        $backend.Memory.Failure = ''
        $retry = Invoke-BigZTweak @planOptions -JournalPath $journalPath
        $retry.Entries[0].Status | Should Be 'Applied'
        $backend.Memory.Calls.Count | Should Be 1
        $null = Undo-BigZTweak -JournalPath $journalPath -Adapter $backend.Adapter
        $backend.Memory.Values.HideFileExt | Should Be 1
    }

    It 'retoma uma reversão interrompida sem escrever duas vezes' {
        $null = Invoke-BigZTweak @planOptions -JournalPath $journalPath
        $backend.Memory.Failure = 'after'
        { Undo-BigZTweak -JournalPath $journalPath -Adapter $backend.Adapter } | Should Throw
        $journal = Get-Content -LiteralPath $journalPath -Raw | ConvertFrom-Json
        $journal.Intent | Should Be 'revert'
        $journal.Entries[0].Status | Should Be 'Reverting'
        $backend.Memory.Failure = ''
        { Invoke-BigZTweak @planOptions -JournalPath $journalPath } | Should Throw
        $undo = Undo-BigZTweak -JournalPath $journalPath -Adapter $backend.Adapter
        $undo.Succeeded | Should Be $true
        $backend.Memory.Values.HideFileExt | Should Be 1
        $backend.Memory.Calls.Count | Should Be 2
    }

    It 'reserva Appx para declaração offline e rejeita pacote protegido' {
        $tweak.phase = 'offline'
        $tweak.scope = 'image'
        $tweak.requires.admin = $true
        $tweak.action = @{ type = 'appx.deprovision'; packageName = 'Microsoft.BingNews' }
        $tweak.verify.type = 'appx.absent'
        $tweak.rollback.type = 'rebuildImage'
        Save-TestTweak $tweak $planOptions.CatalogPath
        $preview = Get-BigZTweakPlan @planOptions -Phase offline -DeclarationOnly
        $preview.IsValid | Should Be $true
        $preview.CanApply | Should Be $false
        { Get-BigZTweakPlan @planOptions -Phase offline } | Should Throw
        $tweak.action.packageName = 'Microsoft.WindowsStore'
        Save-TestTweak $tweak $planOptions.CatalogPath
        { Get-BigZTweakPlan @planOptions -Phase offline -DeclarationOnly } | Should Throw
    }

    It 'ordena dependências ao aplicar e desfaz na ordem inversa' {
        $child = Get-TestTweakFixture -Id 'explorer.show-hidden' -Name Hidden -Value 1 -DependsOn $tweak.id
        Save-TestTweak $child $planOptions.CatalogPath
        $planOptions.Id = @($child.id, $tweak.id)
        $result = Invoke-BigZTweak @planOptions -JournalPath $journalPath
        $result.Entries[0].Id | Should Be $tweak.id
        $null = Undo-BigZTweak -JournalPath $journalPath -Adapter $backend.Adapter
        ($backend.Memory.Calls -join ',') | Should Be 'HideFileExt,Hidden,Hidden,HideFileExt'
    }

    It 'rejeita ciclo, referência ausente e conflito' {
        $peer = Get-TestTweakFixture -Id 'explorer.show-hidden' -Name Hidden -Value 1 -DependsOn $tweak.id
        $tweak.dependsOn = @($peer.id)
        Save-TestTweak $tweak $planOptions.CatalogPath
        { Get-BigZTweakPlan @planOptions -DeclarationOnly } | Should Throw
        Save-TestTweak $peer $planOptions.CatalogPath
        { Get-BigZTweakPlan @planOptions -DeclarationOnly } | Should Throw
        $tweak.dependsOn = @()
        $tweak.conflictsWith = @($peer.id)
        Save-TestTweak $tweak $planOptions.CatalogPath
        $planOptions.Id = $peer.id
        (Get-BigZTweakPlan @planOptions -DeclarationOnly).IsValid | Should Be $false
    }

    It 'bloqueia risco alto e redução de proteção também no plano declarativo' {
        $tweak.risk = 'high'
        Save-TestTweak $tweak $planOptions.CatalogPath
        (Get-BigZTweakPlan @planOptions -DeclarationOnly).IsValid | Should Be $false
        $tweak.risk = 'low'
        $tweak.securityImpact = 'reducesProtection'
        Save-TestTweak $tweak $planOptions.CatalogPath
        (Get-BigZTweakPlan @planOptions -DeclarationOnly).IsValid | Should Be $false
        { Invoke-BigZTweak @planOptions -JournalPath $journalPath } | Should Throw
        $backend.Memory.Calls.Count | Should Be 0
    }

    It 'rejeita campo desconhecido, comando livre e alvo protegido' {
        $tweak | Add-Member -NotePropertyName script -NotePropertyValue 'exemplo'
        Save-TestTweak $tweak $planOptions.CatalogPath
        { Get-BigZTweakPlan @planOptions -DeclarationOnly } | Should Throw
        $tweak.PSObject.Properties.Remove('script')
        $tweak.action.type = 'powershell.run'
        Save-TestTweak $tweak $planOptions.CatalogPath
        { Get-BigZTweakPlan @planOptions -DeclarationOnly } | Should Throw
        $tweak.action.type = 'registry.setValue'
        $tweak.action.key = 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender'
        Save-TestTweak $tweak $planOptions.CatalogPath
        { Get-BigZTweakPlan @planOptions -DeclarationOnly } | Should Throw
    }

    It 'bloqueia chave ausente e tipo original que não pode restaurar' {
        $backend.Memory.MissingKey = $true
        (Get-BigZTweakPlan @planOptions).CanApply | Should Be $false
        $backend.Memory.MissingKey = $false
        $backend.Memory.ValueType = 'String'
        (Get-BigZTweakPlan @planOptions).CanApply | Should Be $false
    }

    It 'recusa reverter um diário criado por outro alvo' {
        $null = Invoke-BigZTweak @planOptions -JournalPath $journalPath
        $other = Get-TestBackendFixture
        { Undo-BigZTweak -JournalPath $journalPath -Adapter $other.Adapter } | Should Throw
        $other.Memory.Calls.Count | Should Be 0
    }
}
