function Read-BigZJson {
    param([string]$Path)
    Get-Content -LiteralPath $Path -Encoding UTF8 -Raw | ConvertFrom-Json -ErrorAction Stop
}

function Read-BigZCatalog {
    param([string]$Root)

    $apps = Read-BigZJson (Join-Path $Root 'toolbox/catalog/apps.json')
    $profiles = Read-BigZJson (Join-Path $Root 'toolbox/catalog/profiles.json')
    $design = Read-BigZJson (Join-Path $Root 'design/presets-shell-toolbox.json')
    $tweakPath = Join-Path $Root 'shared/tweaks'
    $tweaks = @(Get-ChildItem -LiteralPath $tweakPath -Filter '*.json' -File |
        Sort-Object Name | ForEach-Object { Read-BigZJson $_.FullName })

    if ($apps.schemaVersion -ne 1 -or $profiles.schemaVersion -ne 1) {
        throw 'A versão do catálogo ou dos perfis não é compatível.'
    }
    foreach ($entry in $apps.apps) {
        if ($entry.schemaVersion -ne 1 -or $entry.phase -ne 'online' -or
            $entry.risk -notin @('low', 'medium') -or $entry.securityImpact -ne 'none' -or
            $entry.delivery.provider -notin @('winget', 'official-link')) {
            throw "Aplicativo com contrato ou política incompatível: $($entry.id)."
        }
        if ($entry.delivery.provider -eq 'winget' -and
            ($entry.delivery.source -ne 'winget' -or $entry.delivery.scope -notin @('user', 'machine'))) {
            throw "Origem ou escopo WinGet incompatível: $($entry.id)."
        }
    }
    $tweaks = @($tweaks | Where-Object { $_.phase -eq 'online' })
    foreach ($tweak in $tweaks) {
        if ($tweak.schemaVersion -ne 1) {
            throw "A versão do ajuste $($tweak.id) não é compatível."
        }
    }

    $toolApps = @{
        open_shell = 'open-shell'
        nilesoft_shell = 'nilesoft-shell'
        translucenttb = 'translucenttb'
    }
    $designEditions = @{ dev = 'DEV'; balanced = 'Balanced'; 'full-performance' = 'Full Performance' }
    $presets = foreach ($profile in $profiles.profiles) {
        $editionName = $designEditions[$profile.id]
        $definition = $design.editions.PSObject.Properties[$editionName].Value
        foreach ($setting in $definition.defaults.PSObject.Properties) {
            $tool = $design.tools.PSObject.Properties[$setting.Name].Value
            $preset = @($tool.presets | Where-Object { $_.id -eq $setting.Value.presetId })
            if ($preset.Count -ne 1 -or -not $toolApps.ContainsKey($setting.Name)) {
                throw "Preset visual desconhecido para $editionName."
            }
            $preset = $preset[0]
            $native = $preset.PSObject.Properties['configParams'] -and
                $preset.configParams.PSObject.Properties['enabled'] -and -not $preset.configParams.enabled
            $dependencies = @()
            if (-not $native) { $dependencies = @($toolApps[$setting.Name]) }
            $risk = if ($native) { 'low' } else { 'medium' }
            $configParams = if ($preset.PSObject.Properties['configParams']) { $preset.configParams }
            $asset = $null
            if ($preset.PSObject.Properties['configFile']) { $asset = $preset.configFile }
            [pscustomobject]@{
                id = $preset.id
                name = $preset.name
                description = $preset.description
                editions = @($profile.id)
                risk = $risk
                dependsOn = $dependencies
                conflictsWith = @()
                defaultSelected = [bool]$setting.Value.enabled
                configParams = $configParams
                asset = $asset
                assetAvailable = [bool]($asset -and (Test-Path -LiteralPath (Join-Path (Join-Path $Root 'design') $asset) -PathType Leaf))
            }
        }
    }

    $index = @{}
    $lists = [ordered]@{ app = @($apps.apps); tweak = $tweaks; preset = @($presets) }
    foreach ($kind in $lists.Keys) {
        foreach ($entry in $lists[$kind]) {
            if (-not $entry.id -or $index.ContainsKey($entry.id)) {
                throw "ID ausente ou duplicado no catálogo: $($entry.id)."
            }
            $index[$entry.id] = [pscustomobject]@{ Kind = $kind; Entry = $entry }
        }
    }

    [pscustomobject]@{
        Index = $index
        Lists = $lists
        Profiles = @($profiles.profiles)
        TweakPath = $tweakPath
        EnginePath = Join-Path $Root 'shared/modules/BigZ.Tweaks/BigZ.Tweaks.psd1'
    }
}

function Get-BigZDefaultIds {
    param($Catalog, [string]$Edition)

    $profile = $Catalog.Profiles | Where-Object { $_.id -eq $Edition }
    $profile.firstUseAppDefaults
    $profile.firstUseDefaults
    $Catalog.Lists.preset | Where-Object { $_.defaultSelected -and $Edition -in $_.editions } |
        ForEach-Object { $_.id }
}

function Add-BigZPlanEntry {
    param($Catalog, [string]$Edition, [string]$Id, $State)

    if ($State.Added.ContainsKey($Id)) { return }
    if ($State.Visiting.ContainsKey($Id)) { throw "Ciclo de dependências em $Id." }
    if (-not $Catalog.Index.ContainsKey($Id)) { throw "Item desconhecido: $Id." }
    $record = $Catalog.Index[$Id]
    if ($Edition -notin $record.Entry.editions) { throw "Item $Id indisponível na edição $Edition." }

    $State.Visiting[$Id] = $true
    foreach ($dependency in $record.Entry.dependsOn) {
        Add-BigZPlanEntry $Catalog $Edition $dependency $State
    }
    $State.Visiting.Remove($Id)
    $State.Added[$Id] = $true
    $State.Ordered.Add($record)
}

function New-BigZToolboxPlan {
    param($Catalog, [string]$Edition, [string[]]$Id)

    $state = @{
        Added = @{}
        Visiting = @{}
        Ordered = [System.Collections.Generic.List[object]]::new()
    }
    foreach ($itemId in $Id) { Add-BigZPlanEntry $Catalog $Edition $itemId $state }
    $items = foreach ($record in $state.Ordered) {
        $entry = $record.Entry
        foreach ($conflict in $entry.conflictsWith) {
            if ($state.Added.ContainsKey($conflict)) { throw "Conflito no plano: $($entry.id) e $conflict." }
        }
        $details = switch ($record.Kind) {
            'app' {
                if ($entry.delivery.provider -eq 'winget') {
                    "WinGet · $($entry.delivery.packageId) · escopo $($entry.delivery.scope). Conferir a procedência da versão a instalar. Manifesto: $($entry.delivery.manifestUrl)"
                } else {
                    "Página oficial · $($entry.delivery.officialUrl)"
                }
            }
            'tweak' { "$($entry.action.key) · $($entry.action.name) = $($entry.action.value) ($($entry.action.valueType)). Fonte: $($entry.source)" }
            'preset' {
                $entry.description
                if ($entry.asset) {
                    "Arquivo de configuração: $($entry.asset)."
                    if (-not $entry.assetAvailable) { 'Arquivo ainda não disponível.' }
                }
                if ($entry.configParams) {
                    "Preferências: $($entry.configParams | ConvertTo-Json -Depth 4 -Compress)."
                }
            }
        }
        $name = if ($record.Kind -eq 'tweak') { $entry.description } else { $entry.name }
        [pscustomobject]@{
            Id = $entry.id
            Kind = $record.Kind
            Name = $name
            Risk = $entry.risk
            Details = $details -join ' '
            Dependency = $entry.id -notin $Id
            Rollback = $record.Kind -eq 'tweak' -and $entry.rollback.type -eq 'restoreSnapshot'
        }
    }

    $module = $null
    $engine = 'Planejador local'
    $diagnostics = @()
    $tweakIds = @($items | Where-Object { $_.Kind -eq 'tweak' } | ForEach-Object { $_.Id })
    if ($tweakIds.Count) { $engine = 'Stub local' }
    if ($tweakIds.Count -and (Test-Path -LiteralPath $Catalog.EnginePath -PathType Leaf)) {
        try {
            $module = Import-Module -Name $Catalog.EnginePath -PassThru -ErrorAction Stop
        } catch {
            $diagnostics += "Módulo de ajustes indisponível. Prévia local sem validação do motor: $($_.Exception.Message)"
        }
        if ($module) {
            $command = $module.ExportedCommands['Get-BigZTweakPlan']
            if (-not $command -or -not $command.Parameters.ContainsKey('DeclarationOnly')) {
                $diagnostics += 'O módulo ainda não expõe DeclarationOnly. Prévia local sem validação do motor.'
            } else {
                $result = & $command -CatalogPath $Catalog.TweakPath -Id $tweakIds -Edition $Edition -Phase online -DeclarationOnly
                $engine = 'BigZ.Tweaks · validação declarativa'
                $diagnostics = @($result.Diagnostics | Where-Object { $null -ne $_ } | ForEach-Object {
                    if ($_ -is [string]) { $_ } else { $_ | ConvertTo-Json -Depth 5 -Compress }
                })
                if (-not $result.DeclarationOnly -or $result.CanApply) {
                    throw 'O motor retornou um resultado fora do modo declarativo.'
                }
                $validated = @{}
                foreach ($step in $result.Items) { $validated[$step.Id] = $step }
                foreach ($item in $items) {
                    if ($item.Kind -ne 'tweak') { continue }
                    if (-not $validated.ContainsKey($item.Id)) { throw "Ajuste ausente no retorno do motor: $($item.Id)." }
                    $step = $validated[$item.Id]
                    $action = $step.Action
                    $item.Details = "$($action.key) · $($action.name) = $($action.value) ($($action.valueType)). Fonte: $($Catalog.Index[$item.Id].Entry.source)"
                    if ($step.Status -eq 'Blocked') {
                        $item.Details += ' Bloqueado pelo motor.'
                        $item.Rollback = $false
                    }
                }
            }
        }
    }

    [pscustomobject]@{
        Edition = $Edition
        Mode = 'dry-run'
        Engine = $engine
        Items = @($items | Where-Object { $null -ne $_ })
        Diagnostics = $diagnostics
    }
}

function New-BigZToolboxUndoPlan {
    param($Plan)

    for ($i = $Plan.Items.Count - 1; $i -ge 0; $i--) {
        $item = $Plan.Items[$i]
        $details = switch ($item.Kind) {
            'tweak' {
                if ($item.Rollback) {
                    'Restaurar o estado anterior quando houver captura e o valor atual corresponder ao que a Toolbox escreveu.'
                } else {
                    'Reversão indisponível para este item do plano.'
                }
            }
            'app' { 'Revisar a instalação registrada. O protótipo não remove aplicativos.' }
            'preset' { 'Restaurar as preferências do shell capturadas em uma aplicação real.' }
        }
        [pscustomobject]@{ Name = $item.Name; Details = $details }
    }
}
