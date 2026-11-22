function Get-BigZSelectedImage {
    param(
        [AllowEmptyCollection()][object[]]$Inventory, [int]$Index,
        [string]$WindowsEdition, [switch]$TestOnly
    )

    if (-not $Index -and -not $WindowsEdition) { return }
    $selected = @($Inventory | Where-Object {
        (-not $Index -or $_.Index -eq $Index) -and
        (-not $WindowsEdition -or $_.Edition -ieq $WindowsEdition)
    })
    if ($selected.Count -ne 1) {
        throw 'O seletor não corresponde a um único índice. Use o inventário para confirmar -ImageIndex ou -WindowsEdition.'
    }
    $image = $selected[0]
    if ($image.Architecture -ne 9 -or $image.InstallationType -ine 'Client' -or $image.Build -notin @(26200, 26300)) {
        throw "Imagem fora da matriz Windows 11 x64: build $($image.Build), arquitetura $($image.Architecture)."
    }
    if ($TestOnly -and $image.Edition -ine 'EnterpriseEval') {
        throw '-TestOnly aceita exclusivamente Windows 11 Enterprise Evaluation (EnterpriseEval).'
    }
    if (-not $TestOnly -and $image.Edition -inotmatch '\A(Core|Professional)\z') {
        throw 'Build normal aceita Home (Core) ou Pro (Professional). EnterpriseEval exige -TestOnly.'
    }
    return $image
}

function Assert-BigZPlannedImage {
    param($Plan, $Image)

    Assert-BigZOfflineAction $Plan.ProfileMarker
    if ($Plan.ProfileMarker.type -cne 'registry.setOfflineValue' -or $Plan.ProfileMarker.hive -cne 'software' -or
        $Plan.ProfileMarker.value -cne $Plan.Id) { throw 'Marcador de perfil incompatível.' }
    foreach ($item in $Plan.OfflineTweaks) {
        Assert-BigZOfflineAction $item.Action
        if ($item.Phase -cne 'offline' -or $item.Status -cne 'Declared' -or $item.SecurityImpact -cne 'none' -or
            $item.Risk -cnotin @('low', 'medium') -or $Image.Build -notin $item.Requires.builds -or
            'x64' -cnotin $item.Requires.architectures) {
            throw "Ajuste '$($item.Id)' fora da política ou da build $($Image.Build)."
        }
        if ($item.Action.type -ceq 'registry.setOfflineValue' -and $item.Action.hive -cne 'defaultUser') {
            throw 'O perfil pode alterar somente a preferência aprovada da hive Default User.'
        }
    }
}

function Close-BigZJobResource {
    param($Job, $Tools)

    try {
        Close-BigZOfflineHive $Job $Tools
        Close-BigZWim $Job
    }
    finally { Close-BigZIso $Job }
}

function Get-BigZArtifactLayout {
    param([string]$OutputPath, [switch]$TestOnly)

    $path = Get-BigZLabLocation $OutputPath
    if ([IO.Path]::GetExtension($path) -ine '.iso') { throw '-OutputPath deve terminar em .iso.' }
    $marked = [IO.Path]::GetFileNameWithoutExtension($path).EndsWith('-TESTONLY', [StringComparison]::OrdinalIgnoreCase)
    if ($marked -ne [bool]$TestOnly) { throw 'Use o sufixo -TESTONLY.iso exatamente para o modo -TestOnly.' }
    return [pscustomobject]@{ Iso = $path; Manifest = "$path.manifest.json"; Checksum = "$path.sha256" }
}

function Assert-BigZArtifactVacant {
    param($Artifact)

    foreach ($file in @($Artifact.Iso, $Artifact.Manifest, $Artifact.Checksum)) {
        if (Test-Path -LiteralPath $file) { throw "Arquivo de saída já existe: '$file'." }
    }
}

function Publish-BigZMediaArtifact {
    param($Job, $Tools, $Artifact, $Manifest, [string]$Label)

    $outputDirectory = [IO.Path]::GetDirectoryName($Artifact.Iso)
    [void][IO.Directory]::CreateDirectory($outputDirectory)
    $pending = Get-BigZLocalPath (Join-Path $outputDirectory ('.bigz-' + $Job.Id))
    if (Test-Path -LiteralPath $pending) { throw 'A pasta temporária deste job já existe.' }
    [void][IO.Directory]::CreateDirectory($pending)
    $iso = Join-Path $pending 'pending.iso'
    $json = Join-Path $pending 'manifest.json'
    $checksum = Join-Path $pending 'checksum.txt'
    $moved = [Collections.Generic.List[string]]::new()
    try {
        Invoke-BigZOscdimg $Job $Tools $iso $Label
        $imageFile = Get-Item -LiteralPath $iso -ErrorAction Stop
        if ($imageFile.Length -eq 0) { throw 'ISO vazia após executar oscdimg.' }
        $hash = (Get-FileHash -LiteralPath $iso -Algorithm SHA256 -ErrorAction Stop).Hash
        $Manifest.Output.Sha256 = $hash
        $Manifest.Output.Bytes = $imageFile.Length
        [IO.File]::WriteAllText($json, ($Manifest | ConvertTo-Json -Depth 12) + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
        $line = "$hash *$([IO.Path]::GetFileName($Artifact.Iso))" + [Environment]::NewLine
        [IO.File]::WriteAllText($checksum, $line, [Text.UTF8Encoding]::new($false))

        # Publish ISO last so an interrupted publication cannot expose a final ISO without both sidecars.
        [IO.File]::Move($json, $Artifact.Manifest)
        $moved.Add($Artifact.Manifest)
        [IO.File]::Move($checksum, $Artifact.Checksum)
        $moved.Add($Artifact.Checksum)
        [IO.File]::Move($iso, $Artifact.Iso)
    }
    catch {
        foreach ($file in $moved) { [IO.File]::Delete($file) }
        throw
    }
    finally {
        try {
            foreach ($file in @($iso, $json, $checksum)) { [IO.File]::Delete($file) }
            [IO.Directory]::Delete($pending)
        }
        catch { Write-Warning "Pasta temporária preservada para revisão: '$pending'." }
    }
}

function Invoke-BigZBuildPipeline {
    param($Job, $Tools, $Source, $Plan, $Artifact, [string]$TemplatePath, [int]$Index,
        [string]$WindowsEdition, [switch]$InspectOnly, [switch]$TestOnly)

    $mediaRoot = Open-BigZIso $Job
    Save-BigZJobState $Job 'inventory'
    $sourceImage = Get-BigZInstallerLayout $mediaRoot
    $inventory = @(Get-BigZImageInventory $sourceImage $Job)
    if (-not $inventory.Count) { throw 'O DISM não encontrou índices no instalador.' }
    if ($TestOnly -and -not $Index -and -not $WindowsEdition) { $WindowsEdition = 'EnterpriseEval' }
    $selected = Get-BigZSelectedImage $inventory $Index $WindowsEdition -TestOnly:$TestOnly
    if ($selected) { Assert-BigZPlannedImage $Plan $selected }
    $Source.ImageMetadataVerified = [bool]$selected
    $container = [IO.Path]::GetExtension($sourceImage).TrimStart('.').ToUpperInvariant()
    if ($InspectOnly) {
        Close-BigZIso $Job
        return [pscustomobject]@{
            Mode = 'inventory'
            Profile = $Plan
            Source = $Source
            MediaInspected = $true
            Container = $container
            ImageInventory = $inventory
            SelectedImage = $selected
            CanBuild = [bool]$selected
            JobPath = $Job.Path
        }
    }

    if (-not $selected) { throw 'Escolha -ImageIndex ou -WindowsEdition antes de construir a ISO.' }
    Save-BigZJobState $Job 'copying'
    Copy-BigZInstaller $mediaRoot $Job $Tools
    Save-BigZJobState $Job 'exporting'
    Export-BigZInstallImage $sourceImage $selected.Index $Job
    $null = Get-BigZInstallerLayout $Job.MediaPath
    Close-BigZIso $Job
    if ((Get-FileHash -LiteralPath $Source.Path -Algorithm SHA256 -ErrorAction Stop).Hash -cne $Source.Sha256) {
        throw 'O conteúdo da ISO de origem mudou entre a leitura e a cópia.'
    }

    Open-BigZWim $Job
    $changes = @(
        foreach ($item in $Plan.OfflineTweaks) {
            switch -CaseSensitive ($item.Action.type) {
                'appx.deprovision' {
                    Save-BigZJobState $Job 'servicing-appx'
                    $change = Invoke-BigZAppxDeprovision $Job $item.Action
                    [pscustomobject]@{ Id = $item.Id; Result = $change.Result; PackageName = $change.PackageName }
                }
                'registry.setOfflineValue' {
                    Write-BigZOfflineRegistry $Job $Tools $item.Action
                    [pscustomobject]@{ Id = $item.Id; Result = 'verified'; Value = $item.Action }
                }
            }
        }
        Write-BigZOfflineRegistry $Job $Tools $Plan.ProfileMarker
        [pscustomobject]@{ Id = 'bigz.profile-marker'; Result = 'verified'; Value = $Plan.ProfileMarker }
    )
    Save-BigZJobState $Job 'committing'
    Close-BigZWim $Job -Save

    Save-BigZJobState $Job 'verifying-wim'
    $exported = @(Get-BigZImageInventory $Job.WimPath $Job)
    if ($exported.Count -ne 1 -or $exported[0].Index -ne 1 -or $exported[0].Edition -ine $selected.Edition -or
        $exported[0].Build -ne $selected.Build -or $exported[0].Architecture -ne $selected.Architecture) {
        throw 'O WIM final não preservou a identidade do índice selecionado.'
    }
    Save-BigZJobState $Job 'writing-answer-file'
    Write-BigZAnswerFile $Job $TemplatePath $selected.DefaultLanguage
    $definition = $Plan | ConvertTo-Json -Depth 10 -Compress
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try { $profileDigest = [BitConverter]::ToString($sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($definition))).Replace('-', '') }
    finally { $sha256.Dispose() }

    $manifest = [pscustomobject]@{
        SchemaVersion = 1
        JobId = $Job.Id
        BuiltAtUtc = [datetime]::UtcNow.ToString('o')
        testOnly = [bool]$TestOnly
        Profile = $Plan.Id
        ProfileDefinition = $Plan
        ProfileDefinitionSha256 = $profileDigest
        Source = $Source
        SourceContainer = $container
        SourceImage = $selected
        OutputImage = $exported[0]
        Output = [pscustomobject]@{ FileName = [IO.Path]::GetFileName($Artifact.Iso); Bytes = 0; Sha256 = '' }
        Tools = [pscustomobject]@{ DismVersion = $Tools.DismVersion; Oscdimg = $Tools.Oscdimg }
        Boot = 'UEFI x64'
        OfflineChanges = $changes
    }
    Save-BigZJobState $Job 'packaging'
    $label = "BIGZ_$($Plan.Id.Replace('-', '_').ToUpperInvariant())"
    if ($TestOnly) { $label += '_TESTONLY' }
    Publish-BigZMediaArtifact $Job $Tools $Artifact $manifest $label
    return [pscustomobject]@{
        Mode = 'build'
        Profile = $Plan.Id
        TestOnly = [bool]$TestOnly
        Iso = $Artifact.Iso
        Manifest = $Artifact.Manifest
        Checksum = $Artifact.Checksum
        Sha256 = $manifest.Output.Sha256
        JobPath = $Job.Path
    }
}

function Invoke-BigZMediaBuild {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]$Source,
        [Parameter(Mandatory)]$ProfilePlan,
        [Parameter(Mandatory)][string]$WorkRoot,
        [Parameter(Mandatory)][string]$TemplatePath,
        [string]$OutputPath, [string]$OscdimgPath, [int]$Index, [string]$WindowsEdition,
        [switch]$InspectOnly, [switch]$TestOnly
    )

    $root = Get-BigZLabLocation $WorkRoot
    $sourcePath = Get-BigZLabLocation $Source.Path
    if ($TestOnly -and (-not (Test-BigZWithinPath $sourcePath 'C:\DEV\BigZ-Lab\iso') -or
        -not (Test-BigZWithinPath $root 'C:\DEV\BigZ-Lab\work'))) {
        throw 'Use C:\DEV\BigZ-Lab\iso e C:\DEV\BigZ-Lab\work no modo -TestOnly.'
    }
    $artifact = $null
    if (-not $InspectOnly) {
        if (-not $OutputPath -or (-not $Index -and -not $WindowsEdition)) {
            throw 'O build exige -OutputPath e um seletor: -ImageIndex ou -WindowsEdition.'
        }
        $artifact = Get-BigZArtifactLayout $OutputPath -TestOnly:$TestOnly
        if ($artifact.Iso -ieq $sourcePath) { throw 'A ISO de origem e a saída devem ser distintas.' }
        if ($TestOnly -and -not (Test-BigZWithinPath $artifact.Iso 'C:\DEV\BigZ-Lab\out')) {
            throw 'Use C:\DEV\BigZ-Lab\out como pasta de saída no modo -TestOnly.'
        }
        Assert-BigZArtifactVacant $artifact
    }
    if (-not $PSCmdlet.ShouldProcess($sourcePath, 'Acessar a mídia do instalador')) { return }
    Assert-BigZElevation
    $capacityPath = $null
    if ($artifact) { $capacityPath = $artifact.Iso }
    Assert-BigZCapacity $root $capacityPath $Source.Bytes -InspectOnly:$InspectOnly
    $tools = Get-BigZWindowsToolchain $OscdimgPath -RequireOscdimg:(-not $InspectOnly)
    $mutex = Enter-BigZMediaLock
    try {
        $job = Initialize-BigZJob $root $sourcePath -TestOnly:$TestOnly
        if ($TestOnly) { Write-Warning 'Enterprise Evaluation. Este job se destina somente ao laboratório.' }
        try {
            $pipeline = @{
                Job = $job; Tools = $tools; Source = $Source; Plan = $ProfilePlan; Artifact = $artifact
                TemplatePath = $TemplatePath; Index = $Index; WindowsEdition = $WindowsEdition
                InspectOnly = $InspectOnly; TestOnly = $TestOnly
            }
            $result = Invoke-BigZBuildPipeline @pipeline
        }
        catch {
            $failureMessage = Get-BigZJobFailureMessage $job $_
            try {
                Close-BigZJobResource $job $tools
                Save-BigZJobState $job 'failed'
            }
            catch { Write-Warning "Recuperação pendente para job $($job.Id): $(Get-BigZErrorText $_)" -WarningAction Continue }
            throw $failureMessage
        }

        try {
            Save-BigZJobState $job 'complete'
            Clear-BigZJobPayload $job
        }
        catch { Write-Warning "Área de trabalho preservada em '$($job.Path)': $($_.Exception.Message)" }
        return $result
    }
    finally { Exit-BigZMediaLock $mutex }
}

function Restore-BigZMediaJob {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$WorkRoot, [Parameter(Mandatory)][guid]$Id)

    $root = Get-BigZLabLocation $WorkRoot
    if (-not $PSCmdlet.ShouldProcess($Id.ToString('N'), 'Recuperar e descartar montagens deste job')) { return }
    Assert-BigZElevation
    $tools = Get-BigZWindowsToolchain
    $mutex = Enter-BigZMediaLock
    try {
        $job = Read-BigZJob $root $Id
        Close-BigZJobResource $job $tools
        Save-BigZJobState $job 'recovered'
        return [pscustomobject]@{ Mode = 'recovery'; JobId = $job.Id; JobPath = $job.Path }
    }
    finally { Exit-BigZMediaLock $mutex }
}
