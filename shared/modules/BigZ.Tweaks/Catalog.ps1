$script:BigZEditions = @('dev', 'balanced', 'full-performance')

# These exact preferences can be proposed by the catalog. The journal may restore their previous DWORD.
$script:BigZRegistryPolicy = @{
    'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' = @{
        HideFileExt = 0
        Hidden = 1
        LaunchTo = 1
        TaskbarAl = 0
        ShowTaskViewButton = 0
        TaskbarGlomLevel = 0
        MMTaskbarGlomLevel = 0
        MMTaskbarMode = 2
    }
    'HKCU\Software\Microsoft\Windows\CurrentVersion\Search' = @{ SearchboxTaskbarMode = 0 }
    'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' = @{ EnableTransparency = 0 }
}
$script:BigZOfflinePackages = @('Microsoft.BingNews', 'Clipchamp.Clipchamp', 'Microsoft.MicrosoftSolitaireCollection')

function Read-BigZJson {
    param([string]$Path)

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw) -or -not $raw.TrimStart().StartsWith('{')) {
            throw 'Esperado um objeto JSON na raiz.'
        }
        return ConvertFrom-Json -InputObject $raw -ErrorAction Stop
    }
    catch {
        throw "JSON inválido em $Path. $($_.Exception.Message)"
    }
}

function Assert-BigZFields {
    param($Value, [string[]]$Required, [string[]]$Optional = @(), [string]$Label)

    if ($Value -isnot [pscustomobject]) { throw "$Label deve ser um objeto JSON." }
    $names = @($Value.PSObject.Properties.Name)
    foreach ($name in $Required) {
        if ($name -cnotin $names) { throw "$Label exige o campo '$name'." }
    }
    foreach ($name in $names) {
        if ($name -cnotin $Required -and $name -cnotin $Optional) {
            throw "Campo '$name' desconhecido em $Label."
        }
    }
}

function Assert-BigZId {
    param($Value, [string]$Label)

    if ($Value -isnot [string] -or $Value -cnotmatch '\A[a-z0-9]+(?:[.-][a-z0-9]+)*\z') {
        throw "$Label deve ser um ID em minúsculas com separadores ponto ou hífen."
    }
}

function Assert-BigZList {
    param($Value, [string]$Label, [scriptblock]$ValidateItem, [switch]$RequireItem)

    if ($Value -isnot [array] -or ($RequireItem -and $Value.Count -eq 0)) {
        throw "$Label deve ser uma lista JSON com os itens exigidos."
    }
    $seen = @{}
    foreach ($item in $Value) {
        & $ValidateItem $item $Label
        if ($seen.ContainsKey($item)) { throw "Item duplicado '$item' em $Label." }
        $seen[$item] = $true
    }
}

function Test-BigZInteger {
    param($Value)

    return $Value -is [int] -or $Value -is [long]
}

function Assert-BigZRegistryAction {
    param($Action, [string]$Label)

    Assert-BigZFields $Action @('type', 'key', 'name', 'valueType', 'value') -Label $Label
    if ($Action.type -cne 'registry.setValue' -or $Action.valueType -cne 'DWord' -or
        $Action.key -isnot [string] -or $Action.name -isnot [string] -or
        -not (Test-BigZInteger $Action.value)) {
        throw "Ação de registro inválida em $Label."
    }
    if (-not $script:BigZRegistryPolicy.ContainsKey($Action.key)) {
        throw "Chave fora da lista permitida em $Label."
    }
    $values = $script:BigZRegistryPolicy[$Action.key]
    if (-not $values.ContainsKey($Action.name) -or $Action.value -ne $values[$Action.name]) {
        throw "Valor fora da lista permitida em $Label."
    }
}

function Assert-BigZTweak {
    param($Tweak, [string]$Label)

    $fields = @('schemaVersion', 'id', 'description', 'risk', 'editions', 'phase', 'scope', 'securityImpact', 'source',
        'requires', 'dependsOn', 'conflictsWith', 'action', 'verify', 'rollback', 'restart')
    Assert-BigZFields $Tweak $fields -Label $Label
    if (-not (Test-BigZInteger $Tweak.schemaVersion) -or $Tweak.schemaVersion -ne 1) {
        throw "schemaVersion incompatível em $Label."
    }
    Assert-BigZId $Tweak.id "$Label.id"
    if ($Tweak.description -isnot [string] -or [string]::IsNullOrWhiteSpace($Tweak.description) -or
        $Tweak.risk -isnot [string] -or $Tweak.risk -cnotin @('low', 'medium', 'high') -or
        $Tweak.restart -isnot [string] -or $Tweak.restart -cnotin @('none', 'logoff', 'reboot')) {
        throw "Descrição, risco ou reinício inválido em $Label."
    }
    $sourceUri = $null
    if ($Tweak.securityImpact -isnot [string] -or $Tweak.securityImpact -cnotin @('none', 'reducesProtection') -or
        $Tweak.source -isnot [string] -or -not [uri]::TryCreate($Tweak.source, [UriKind]::Absolute, [ref]$sourceUri) -or
        $sourceUri.Scheme -cne 'https' -or -not $sourceUri.Host -or $sourceUri.UserInfo) {
        throw "Impacto na segurança ou fonte HTTPS inválida em $Label."
    }
    Assert-BigZList $Tweak.editions "$Label.editions" {
        param($item, $field)
        if ($item -isnot [string] -or $item -cnotin $script:BigZEditions) { throw "Edição inválida em $field." }
    } -RequireItem
    $validateId = { param($item, $field) Assert-BigZId $item $field }
    Assert-BigZList $Tweak.dependsOn "$Label.dependsOn" $validateId
    Assert-BigZList $Tweak.conflictsWith "$Label.conflictsWith" $validateId
    Assert-BigZFields $Tweak.requires @('builds', 'architectures', 'admin') -Label "$Label.requires"
    Assert-BigZList $Tweak.requires.builds "$Label.requires.builds" {
        param($item, $field)
        if (-not (Test-BigZInteger $item) -or $item -le 0 -or $item -gt [int]::MaxValue) {
            throw "Build inválida em $field."
        }
    } -RequireItem
    Assert-BigZList $Tweak.requires.architectures "$Label.requires.architectures" {
        param($item, $field)
        if ($item -isnot [string] -or $item -cne 'x64') { throw "Arquitetura fora da matriz v0 em $field." }
    } -RequireItem
    if ($Tweak.requires.admin -isnot [bool]) { throw "admin deve ser booleano em $Label." }

    Assert-BigZFields $Tweak.action @('type') @('key', 'name', 'valueType', 'value', 'packageName') "$Label.action"
    Assert-BigZFields $Tweak.verify @('type') -Label "$Label.verify"
    Assert-BigZFields $Tweak.rollback @('type') -Label "$Label.rollback"
    foreach ($type in @($Tweak.action.type, $Tweak.verify.type, $Tweak.rollback.type, $Tweak.phase, $Tweak.scope)) {
        if ($type -isnot [string]) { throw "Tipo, fase ou escopo inválido em $Label." }
    }

    switch -CaseSensitive ($Tweak.action.type) {
        'registry.setValue' {
            Assert-BigZRegistryAction $Tweak.action "$Label.action"
            if ($Tweak.phase -cne 'online' -or $Tweak.scope -cne 'currentUser' -or $Tweak.requires.admin -or
                $Tweak.verify.type -cne 'registry.matchesAction' -or $Tweak.rollback.type -cne 'restoreSnapshot') {
                throw "Fase, escopo, verificação ou reversão incompatível em $Label."
            }
        }
        'appx.deprovision' {
            Assert-BigZFields $Tweak.action @('type', 'packageName') -Label "$Label.action"
            if ($Tweak.action.packageName -isnot [string] -or $Tweak.action.packageName -cnotin $script:BigZOfflinePackages -or
                $Tweak.phase -cne 'offline' -or $Tweak.scope -cne 'image' -or -not $Tweak.requires.admin -or
                $Tweak.verify.type -cne 'appx.absent' -or $Tweak.rollback.type -cne 'rebuildImage') {
                throw "Pacote ou contrato de imagem fora da política v0 em $Label."
            }
        }
        default { throw "Tipo de ação desconhecido em $Label." }
    }
}

function Add-BigZTweakOrder {
    param([string]$Id, [hashtable]$Catalog, [hashtable]$Marks, [Collections.Generic.List[string]]$Order)

    if ($Marks[$Id] -eq 'visiting') { throw "Ciclo nas dependências de '$Id'." }
    if ($Marks[$Id] -eq 'done') { return }
    $Marks[$Id] = 'visiting'
    foreach ($dependency in $Catalog[$Id].dependsOn) {
        Add-BigZTweakOrder $dependency $Catalog $Marks $Order
    }
    $Marks[$Id] = 'done'
    $Order.Add($Id)
}

function Read-BigZTweakCatalog {
    param([string]$Path)

    $root = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($root.PSIsContainer) {
        $files = @(Get-ChildItem -LiteralPath $root.FullName -File -Filter '*.json' -ErrorAction Stop | Sort-Object Name)
    }
    else {
        $files = @($root)
    }

    $catalog = @{}
    foreach ($file in $files) {
        $tweak = Read-BigZJson $file.FullName
        Assert-BigZTweak $tweak $file.Name
        if ($catalog.ContainsKey($tweak.id)) { throw "ID de tweak duplicado '$($tweak.id)'." }
        $catalog[$tweak.id] = $tweak
    }
    foreach ($tweak in $catalog.Values) {
        foreach ($reference in ($tweak.dependsOn + $tweak.conflictsWith)) {
            if (-not $catalog.ContainsKey($reference) -or $reference -ceq $tweak.id) {
                throw "Referência '$reference' inválida em '$($tweak.id)'."
            }
        }
        foreach ($dependency in $tweak.dependsOn) {
            if ($catalog[$dependency].phase -cne $tweak.phase) {
                throw "Dependência '$dependency' de '$($tweak.id)' cruza fases."
            }
        }
    }
    $marks = @{}
    $order = [Collections.Generic.List[string]]::new()
    foreach ($id in $catalog.Keys) {
        Add-BigZTweakOrder $id $catalog $marks $order
    }
    return $catalog
}
