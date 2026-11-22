#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Plan,
    [switch]$Build,
    [switch]$InspectMedia,
    [guid]$RecoverJob,
    [guid]$CleanupJob,
    [Alias('Profile')][ValidateSet('dev', 'balanced', 'full-performance')][string]$EditionProfile = 'balanced',
    [string]$IsoPath,
    [ValidateRange(1, 2147483647)][int]$ImageIndex,
    [ValidateSet('Core', 'Professional', 'EnterpriseEval')][string]$WindowsEdition,
    [string]$OutputPath,
    [ValidatePattern('\A[0-9a-fA-F]{64}\z')][string]$ExpectedSha256,
    [switch]$TestOnly,
    [string]$WorkRoot = 'C:\DEV\BigZ-Lab\work',
    [string]$OscdimgPath,
    [string]$ProfilesPath,
    [string]$CatalogPath,
    [string]$FirstUsePath,
    [string]$AppCatalogPath
)

Set-StrictMode -Version Latest
$recovery = $PSBoundParameters.ContainsKey('RecoverJob')
$cleanup = $PSBoundParameters.ContainsKey('CleanupJob')
$modes = @($Plan, $Build, $recovery, $cleanup | Where-Object { $_ })
if ($modes.Count -ne 1 -or ($InspectMedia -and -not $Plan)) {
    throw 'Escolha exatamente um modo: -Plan, -Build, -RecoverJob ou -CleanupJob. -InspectMedia acompanha -Plan.'
}
if ($recovery -or $cleanup) {
    $jobOptions = @('WorkRoot', 'WhatIf', 'Confirm', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction',
        'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable')
    if ($PSBoundParameters.Keys | Where-Object { $_ -notin $jobOptions -and $_ -notin @('RecoverJob', 'CleanupJob') }) {
        throw '-RecoverJob e -CleanupJob aceitam o ID do job e a área de trabalho, sem opções de mídia.'
    }
    Import-Module (Join-Path $PSScriptRoot 'modules/BigZ.Media.psm1') -ErrorAction Stop
    if ($cleanup) {
        $cleanupArgs = @{ WorkRoot = $WorkRoot; Id = $CleanupJob }
        foreach ($option in @('WhatIf', 'Confirm')) {
            if ($PSBoundParameters.ContainsKey($option)) { $cleanupArgs[$option] = $PSBoundParameters[$option] }
        }
        Clear-BigZMediaJob @cleanupArgs
    }
    elseif ($PSCmdlet.ShouldProcess($RecoverJob.ToString('N'), 'Recuperar um job local')) {
        Restore-BigZMediaJob -WorkRoot $WorkRoot -Id $RecoverJob -Confirm:$false
    }
    return
}
if (($ImageIndex -or $WindowsEdition -or $ExpectedSha256 -or $Build -or $InspectMedia) -and -not $IsoPath) {
    throw 'Informe -IsoPath para inspecionar a mídia, selecionar o índice ou construir.'
}
if ($Build -and (-not $OutputPath -or (-not $ImageIndex -and -not $WindowsEdition))) {
    throw '-Build exige -OutputPath e -ImageIndex ou -WindowsEdition.'
}
if ($WindowsEdition -and (($WindowsEdition -ieq 'EnterpriseEval') -ne [bool]$TestOnly)) {
    throw 'Use -TestOnly exatamente para a edição EnterpriseEval.'
}

if ($Build -or $InspectMedia) {
    if (-not $PSCmdlet.ShouldProcess($IsoPath, 'Acessar a ISO local com ferramentas do Windows')) { return }
    Import-Module (Join-Path $PSScriptRoot 'modules/BigZ.Media.psm1') -ErrorAction Stop
    Assert-BigZElevation
}

$root = Split-Path -Parent $PSScriptRoot
if (-not $ProfilesPath) { $ProfilesPath = Join-Path $root 'shared/profiles' }
if (-not $CatalogPath) { $CatalogPath = Join-Path $root 'shared/tweaks' }
if (-not $FirstUsePath) { $FirstUsePath = Join-Path $root 'toolbox/catalog/profiles.json' }
if (-not $AppCatalogPath) { $AppCatalogPath = Join-Path $root 'toolbox/catalog/apps.json' }
Import-Module (Join-Path $root 'shared/modules/BigZ.Tweaks/BigZ.Tweaks.psd1') -ErrorAction Stop
Import-Module (Join-Path $PSScriptRoot 'modules/BigZ.ProfilePlan.psm1') -ErrorAction Stop

$profileArgs = @{
    Id = $EditionProfile.ToLowerInvariant()
    ProfilesPath = $ProfilesPath
    CatalogPath = $CatalogPath
    FirstUsePath = $FirstUsePath
    AppCatalogPath = $AppCatalogPath
}
$profilePlan = Get-BigZProfilePlan @profileArgs

$source = $null
if ($IsoPath) {
    $iso = Get-Item -LiteralPath $IsoPath -ErrorAction Stop
    if ($iso -isnot [IO.FileInfo] -or $iso.Extension -ine '.iso' -or $iso.Length -eq 0) {
        throw 'Informe um arquivo .iso não vazio.'
    }
    $length = $iso.Length
    $lastWrite = $iso.LastWriteTimeUtc
    $hash = Get-FileHash -LiteralPath $iso.FullName -Algorithm SHA256 -ErrorAction Stop
    $iso.Refresh()
    if (-not $iso.Exists -or $iso.Length -ne $length -or $iso.LastWriteTimeUtc -ne $lastWrite) {
        throw 'O arquivo ISO mudou durante a leitura.'
    }
    if ($ExpectedSha256 -and $hash.Hash -ine $ExpectedSha256) { throw 'SHA-256 de origem não corresponde à referência informada.' }
    $source = [pscustomobject]@{
        Path = $iso.FullName
        Bytes = $length
        Sha256 = $hash.Hash
        ReferenceSha256Matched = [bool]$ExpectedSha256
        RequestedIndex = $null
        RequestedEdition = $WindowsEdition
        ImageMetadataVerified = $false
    }
    if ($PSBoundParameters.ContainsKey('ImageIndex')) { $source.RequestedIndex = $ImageIndex }
}

$output = $null
if ($OutputPath) {
    $output = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
    if ([IO.Path]::GetExtension($output) -ine '.iso') { throw '-OutputPath deve terminar em .iso.' }
    if ($source -and $source.Path -ieq $output) { throw 'A saída planejada deve ser diferente da ISO de origem.' }
}

if ($Build -or $InspectMedia) {
    $arguments = @{
        Source = $source
        ProfilePlan = $profilePlan
        WorkRoot = $WorkRoot
        TemplatePath = Join-Path $PSScriptRoot 'templates/unattend.xml'
        OutputPath = $output
        OscdimgPath = $OscdimgPath
        Index = $ImageIndex
        WindowsEdition = $WindowsEdition
        InspectOnly = $InspectMedia
        TestOnly = $TestOnly
    }
    Invoke-BigZMediaBuild @arguments -Confirm:$false
    return
}

[pscustomobject]@{
    Mode = 'plan'
    Profile = $profilePlan
    Source = $source
    RequestedOutput = $output
    TestOnly = [bool]$TestOnly
    MediaInspected = $false
    CanBuild = $false
    Diagnostics = @('A prévia estática não monta mídia. Use -Plan -InspectMedia em uma sessão elevada para listar índices.')
}
