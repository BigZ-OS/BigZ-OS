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
$script:BigZOfflinePackages = @{
    'Microsoft.BingNews' = '8wekyb3d8bbwe'
    'Clipchamp.Clipchamp' = 'yxz26nhyzhsrt'
    'Microsoft.MicrosoftSolitaireCollection' = '8wekyb3d8bbwe'
}

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

function Assert-BigZObjectShape {
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

    Assert-BigZObjectShape $Action @('type', 'key', 'name', 'valueType', 'value') -Label $Label
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

function Get-BigZAppxPublisher {
    param([string]$PackageName)

    if ($PackageName -cnotin $script:BigZOfflinePackages.Keys) {
        throw "Pacote fora da lista Appx permitida: '$PackageName'."
    }
    return $script:BigZOfflinePackages[$PackageName]
}

function Assert-BigZOfflineAction {
    param($Action)

    Assert-BigZObjectShape $Action @('type') @('packageName', 'hive', 'key', 'name', 'valueType', 'value') 'ação offline'
    switch -CaseSensitive ($Action.type) {
        'appx.deprovision' {
            Assert-BigZObjectShape $Action @('type', 'packageName') -Label 'ação Appx offline'
            if ($Action.packageName -isnot [string]) { throw 'Identidade Appx inválida.' }
            $null = Get-BigZAppxPublisher $Action.packageName
        }
        'registry.setOfflineValue' {
            Assert-BigZObjectShape $Action @('type', 'hive', 'key', 'name', 'valueType', 'value') -Label 'registro offline'
            foreach ($argument in @($Action.hive, $Action.key, $Action.name, $Action.valueType)) {
                if ($argument -isnot [string]) { throw 'Campo de registro offline inválido.' }
            }
            $profileMarker = $Action.hive -ceq 'software' -and $Action.key -ceq 'BigZOS' -and
                $Action.name -ceq 'Profile' -and $Action.valueType -ceq 'String' -and
                $Action.value -is [string] -and $Action.value -cin $script:BigZEditions
            $defaultPreference = $Action.hive -ceq 'defaultUser' -and
                $Action.key -ceq 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -and
                $Action.name -ceq 'HideFileExt' -and $Action.valueType -ceq 'DWord' -and
                (Test-BigZInteger $Action.value) -and $Action.value -eq 0
            if (-not ($profileMarker -or $defaultPreference)) { throw 'Valor de registro offline fora da lista permitida.' }
        }
        default { throw 'Tipo de ação offline desconhecido.' }
    }
}

function Assert-BigZTweak {
    param($Tweak, [string]$Label)

    $fields = @('schemaVersion', 'id', 'description', 'risk', 'editions', 'phase', 'scope', 'securityImpact', 'source',
        'requires', 'dependsOn', 'conflictsWith', 'action', 'verify', 'rollback', 'restart')
    Assert-BigZObjectShape $Tweak $fields -Label $Label
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
    Assert-BigZObjectShape $Tweak.requires @('builds', 'architectures', 'admin') -Label "$Label.requires"
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

    Assert-BigZObjectShape $Tweak.action @('type') @('key', 'name', 'valueType', 'value', 'packageName', 'hive') "$Label.action"
    Assert-BigZObjectShape $Tweak.verify @('type') -Label "$Label.verify"
    Assert-BigZObjectShape $Tweak.rollback @('type') -Label "$Label.rollback"
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
            Assert-BigZOfflineAction $Tweak.action
            if ($Tweak.phase -cne 'offline' -or $Tweak.scope -cne 'image' -or -not $Tweak.requires.admin -or
                $Tweak.verify.type -cne 'appx.absent' -or $Tweak.rollback.type -cne 'rebuildImage') {
                throw "Contrato de imagem inválido em $Label."
            }
        }
        'registry.setOfflineValue' {
            Assert-BigZOfflineAction $Tweak.action
            if ($Tweak.action.hive -cne 'defaultUser' -or $Tweak.phase -cne 'offline' -or
                $Tweak.scope -cne 'defaultUser' -or -not $Tweak.requires.admin -or
                $Tweak.verify.type -cne 'registry.matchesAction' -or $Tweak.rollback.type -cne 'rebuildImage') {
                throw "Contrato de registro offline inválido em $Label."
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
