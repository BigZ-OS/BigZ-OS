Set-StrictMode -Version Latest

$script:ProfileIds = @('base', 'dev', 'balanced', 'full-performance')
$script:ProfileLists = @('offlineTweaks', 'optionalTweaks')

function Read-BigZProfileJson {
    param([string]$Path)

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($raw) -or -not $raw.TrimStart().StartsWith('{')) {
        throw "Esperado um objeto JSON em '$Path'."
    }
    return ConvertFrom-Json -InputObject $raw -ErrorAction Stop
}

function Assert-BigZProfileShape {
    param($Object, [string[]]$Fields, [string]$Label)

    if ($Object -isnot [pscustomobject]) { throw "Esperado um objeto em '$Label'." }
    $names = @($Object.PSObject.Properties.Name)
    if ($names.Count -ne $Fields.Count -or @($Fields | Where-Object { $_ -cnotin $names }).Count) {
        throw "Campos inválidos em '$Label'."
    }
}

function Assert-BigZProfileVersion {
    param($Version, [string]$Label)

    if (($Version -isnot [int] -and $Version -isnot [long]) -or $Version -ne 1) {
        throw "schemaVersion incompatível em '$Label'."
    }
}

function Assert-BigZProfileIdList {
    param($Items, [string]$Label)

    if ($Items -isnot [array]) { throw "Esperada uma lista em '$Label'." }
    $seen = @{}
    foreach ($item in $Items) {
        if ($item -isnot [string] -or $item -cnotmatch '\A[a-z0-9]+(?:[.-][a-z0-9]+)*\z' -or $seen.ContainsKey($item)) {
            throw "ID inválido ou repetido em '$Label'."
        }
        $seen[$item] = $true
    }
}

function Read-BigZProfileChain {
    param([string]$Id, [string]$Path, [hashtable]$Visited)

    if ($Visited.ContainsKey($Id)) { throw "Ciclo na herança do perfil '$Id'." }
    $Visited[$Id] = $true
    $data = Read-BigZProfileJson (Join-Path $Path "$Id.json")
    Assert-BigZProfileShape $data (@('schemaVersion', 'id', 'base') + $script:ProfileLists) $Id
    Assert-BigZProfileVersion $data.schemaVersion $Id
    if ($data.id -isnot [string] -or $data.id -cne $Id) { throw "ID divergente no perfil '$Id'." }
    foreach ($field in $script:ProfileLists) {
        Assert-BigZProfileIdList $data.$field "$Id.$field"
    }
    if ($Id -ceq 'base') {
        if ($null -ne $data.base) { throw 'O perfil base exige base nula.' }
    }
    else {
        if ($data.base -isnot [string] -or $data.base -cnotin $script:ProfileIds) {
            throw "Perfil base desconhecido em '$Id'."
        }
        Read-BigZProfileChain $data.base $Path $Visited
    }
    $data
}

function Read-BigZFirstUseProfile {
    param([string]$Id, [string]$Path, [string]$AppCatalogPath)

    $envelope = Read-BigZProfileJson $Path
    Assert-BigZProfileShape $envelope @('schemaVersion', 'profiles') 'perfis de primeiro uso'
    Assert-BigZProfileVersion $envelope.schemaVersion 'perfis de primeiro uso'
    if ($envelope.profiles -isnot [array]) { throw 'profiles deve ser uma lista.' }
    $profiles = @{}
    foreach ($entry in $envelope.profiles) {
        Assert-BigZProfileShape $entry @('id', 'firstUseDefaults', 'firstUseAppDefaults') 'perfil de primeiro uso'
        if ($entry.id -isnot [string] -or $entry.id -cnotin $script:ProfileIds[1..3] -or $profiles.ContainsKey($entry.id)) {
            throw 'Edição BigZ inválida ou repetida nos perfis de primeiro uso.'
        }
        Assert-BigZProfileIdList $entry.firstUseDefaults "$($entry.id).firstUseDefaults"
        Assert-BigZProfileIdList $entry.firstUseAppDefaults "$($entry.id).firstUseAppDefaults"
        $profiles[$entry.id] = $entry
    }
    if (-not $profiles.ContainsKey($Id)) { throw "Perfil de primeiro uso não encontrado para '$Id'." }

    $selected = $profiles[$Id]
    if ($selected.firstUseAppDefaults.Count) {
        $apps = Read-BigZProfileJson $AppCatalogPath
        Assert-BigZProfileShape $apps @('schemaVersion', 'apps') 'catálogo de aplicativos'
        Assert-BigZProfileVersion $apps.schemaVersion 'catálogo de aplicativos'
        if ($apps.apps -isnot [array]) { throw 'apps deve ser uma lista.' }
        foreach ($appId in $selected.firstUseAppDefaults) {
            $appMatches = @($apps.apps | Where-Object { $_.id -ceq $appId })
            if ($appMatches.Count -ne 1 -or $appMatches[0].editions -isnot [array] -or $Id -cnotin $appMatches[0].editions) {
                throw "Aplicativo de primeiro uso '$appId' desconhecido, duplicado ou incompatível com '$Id'."
            }
            $app = $appMatches[0]
            Assert-BigZProfileVersion $app.schemaVersion $appId
            if ($app.securityImpact -cne 'none' -or $app.risk -cnotin @('low', 'medium') -or
                $app.phase -cnotin @('online', 'firstUse') -or $app.requires.builds -isnot [array] -or
                26200 -notin $app.requires.builds -or $app.requires.architectures -isnot [array] -or
                'x64' -cnotin $app.requires.architectures) {
                throw "Aplicativo de primeiro uso '$appId' fora da política e da matriz v0."
            }
        }
    }
    return $selected
}

function Assert-BigZProfileTweakPlan {
    param($Plan)

    if (-not $Plan.IsValid) {
        $messages = $Plan.Diagnostics | ForEach-Object { "$($_.Id) $($_.Message)" }
        throw "Perfil inválido. $($messages -join ' ')"
    }
}

function Get-BigZProfilePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('dev', 'balanced', 'full-performance')][string]$Id,
        [Parameter(Mandatory)][string]$ProfilesPath,
        [Parameter(Mandatory)][string]$CatalogPath,
        [Parameter(Mandatory)][string]$FirstUsePath,
        [Parameter(Mandatory)][string]$AppCatalogPath
    )

    $chain = @(Read-BigZProfileChain $Id $ProfilesPath @{})
    $firstUse = Read-BigZFirstUseProfile $Id $FirstUsePath $AppCatalogPath
    $offlineIds = @($chain | ForEach-Object { $_.offlineTweaks } | Select-Object -Unique)
    $optionalIds = @($chain | ForEach-Object { $_.optionalTweaks } | Select-Object -Unique)
    $offline = Get-BigZTweakPlan -CatalogPath $CatalogPath -Id $offlineIds -Edition $Id -Phase offline -DeclarationOnly
    $online = Get-BigZTweakPlan -CatalogPath $CatalogPath -Id $firstUse.firstUseDefaults -Edition $Id -DeclarationOnly
    Assert-BigZProfileTweakPlan $offline
    Assert-BigZProfileTweakPlan $online

    $optional = @(
        foreach ($tweakId in $optionalIds) {
            if ($tweakId -cin $firstUse.firstUseDefaults) { throw "Tweak '$tweakId' é padrão e opcional no mesmo perfil." }
            $tweakPlan = Get-BigZTweakPlan -CatalogPath $CatalogPath -Id $tweakId -Edition $Id -DeclarationOnly
            Assert-BigZProfileTweakPlan $tweakPlan
            $tweakPlan.Items | Where-Object Id -CEQ $tweakId
        }
    )
    return [pscustomobject]@{
        Id = $Id
        Inheritance = @($chain.id)
        Target = [pscustomobject]@{
            WindowsRelease = '25H2'
            Build = 26200
            Architecture = 'x64'
            WindowsEditions = @('Core', 'Professional')
            Firmware = 'UEFI'
        }
        OfflineTweaks = $offline.Items
        FirstUseDefaults = $online.Items
        FirstUseAppDefaults = $firstUse.firstUseAppDefaults
        OptionalTweaks = $optional
    }
}

Export-ModuleMember -Function Get-BigZProfilePlan
