#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$Plan,
    [Alias('Profile')][ValidateSet('dev', 'balanced', 'full-performance')][string]$EditionProfile = 'balanced',
    [string]$IsoPath,
    [ValidateRange(1, 2147483647)][int]$ImageIndex,
    [string]$OutputPath,
    [string]$ProfilesPath,
    [string]$CatalogPath,
    [string]$FirstUsePath,
    [string]$AppCatalogPath
)

Set-StrictMode -Version Latest
if (-not $Plan) { throw 'Este marco implementa somente -Plan. Nenhuma ISO é gerada.' }
if ($PSBoundParameters.ContainsKey('ImageIndex') -and -not $IsoPath) { throw '-ImageIndex exige -IsoPath.' }

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
$notes = @('Inventário WIM/ESD, índice, origem oficial e inicialização UEFI ainda exigem verificação.')
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
    $source = [pscustomobject]@{
        Path = $iso.FullName
        Bytes = $length
        Sha256 = $hash.Hash
        RequestedIndex = $null
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

[pscustomobject]@{
    Mode = 'plan'
    Profile = $profilePlan
    Source = $source
    RequestedOutput = $output
    MediaInspected = $false
    CanBuild = $false
    Diagnostics = $notes
}
