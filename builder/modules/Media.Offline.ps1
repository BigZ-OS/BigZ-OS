function Invoke-BigZHiveCommand {
    param($Tools, [string[]]$ArgumentList, $Job)

    $log = Join-Path $Job.Path 'registry.log'
    $null = Invoke-BigZNativeCommand $Tools.Reg $ArgumentList $log
}

function Close-BigZOfflineHive {
    param($Job, $Tools)

    if (-not $Job.Record.HiveLoadRequested) { return }
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($Job.HiveName, $false)
    if ($null -ne $key) {
        $key.Dispose()
        if (-not (Get-BigZOwnedWimMount $Job)) { throw 'Hive carregada sem montagem WIM do job correspondente.' }
        Invoke-BigZHiveCommand $Tools @('unload', "HKLM\$($Job.HiveName)") $Job
    }
    $Job.Record.HiveLoadRequested = $false
    Save-BigZJobState $Job $Job.Record.Stage
}

function Write-BigZOfflineRegistry {
    param($Job, $Tools, $Action)

    Assert-BigZOfflineAction $Action
    if ($Action.type -cne 'registry.setOfflineValue') { throw 'Esperada uma ação de registro offline.' }
    if (-not (Get-BigZOwnedWimMount $Job)) { throw 'Montagem WIM do job ausente.' }
    $relativePath = 'Windows\System32\config\SOFTWARE'
    if ($Action.hive -ceq 'defaultUser') { $relativePath = 'Users\Default\NTUSER.DAT' }
    $hiveFile = Get-BigZLocalPath (Join-Path $Job.MountPath $relativePath)
    if (-not (Test-Path -LiteralPath $hiveFile -PathType Leaf)) { throw "Hive ausente em '$hiveFile'." }

    $existing = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($Job.HiveName, $false)
    if ($null -ne $existing) {
        $existing.Dispose()
        throw 'O nome de hive deste job já está carregado.'
    }
    $Job.Record.HiveLoadRequested = $true
    Save-BigZJobState $Job 'editing-hive'
    try {
        Invoke-BigZHiveCommand $Tools @('load', "HKLM\$($Job.HiveName)", $hiveFile) $Job
        $hive = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($Job.HiveName, $true)
        if ($null -eq $hive) { throw 'O Windows não abriu a hive da imagem.' }
        try {
            $key = $hive.CreateSubKey($Action.key)
            if ($null -eq $key) { throw 'O Windows não abriu a chave da imagem.' }
            try {
                $kind = [Microsoft.Win32.RegistryValueKind]$Action.valueType
                $value = $Action.value
                if ($kind -eq [Microsoft.Win32.RegistryValueKind]::DWord) { $value = [int]$value }
                $key.SetValue($Action.name, $value, $kind)
                if ($key.GetValueKind($Action.name) -ne $kind -or $key.GetValue($Action.name) -cne $value) {
                    throw 'A releitura do valor de registro offline falhou.'
                }
            }
            finally { $key.Dispose() }
        }
        finally { $hive.Dispose() }
    }
    finally { Close-BigZOfflineHive $Job $Tools }
}

function Get-BigZProvisionedPackage {
    param($Job)
    $dismOptions = Get-BigZDismOption $Job
    Dism\Get-AppxProvisionedPackage -Path $Job.MountPath @dismOptions
}

function Get-BigZVerifiedPackageName {
    param([AllowEmptyCollection()][object[]]$Inventory, [string]$DisplayName)

    $publisher = Get-BigZAppxPublisher $DisplayName
    $candidate = @($Inventory | Where-Object DisplayName -CEQ $DisplayName)
    if ($candidate.Count -eq 0) { return }
    $pattern = '\A' + [regex]::Escape($DisplayName) + '_\d+(\.\d+){3}_(x64|neutral)_([a-zA-Z0-9.~\-]*)_' + $publisher + '\z'
    if ($candidate.Count -ne 1 -or $candidate[0].PackageName -cnotmatch $pattern -or
        ($candidate[0].PublisherId -and $candidate[0].PublisherId -cne $publisher)) {
        throw "Identidade Appx ambígua ou publicador incompatível para '$DisplayName'."
    }
    return $candidate[0].PackageName
}

function Invoke-BigZAppxDeprovision {
    param($Job, $Action)

    Assert-BigZOfflineAction $Action
    if ($Action.type -cne 'appx.deprovision') { throw 'Esperada uma ação Appx offline.' }
    if (-not (Get-BigZOwnedWimMount $Job)) { throw 'Montagem WIM do job ausente.' }
    $packageName = Get-BigZVerifiedPackageName @(Get-BigZProvisionedPackage $Job) $Action.packageName
    if (-not $packageName) { return [pscustomobject]@{ Result = 'already-absent'; PackageName = $null } }
    $dismOptions = Get-BigZDismOption $Job
    Dism\Remove-AppxProvisionedPackage -Path $Job.MountPath -PackageName $packageName @dismOptions | Out-Null
    if (@(Get-BigZProvisionedPackage $Job | Where-Object DisplayName -CEQ $Action.packageName).Count) {
        throw "Appx ainda provisionado após remoção: '$packageName'."
    }
    return [pscustomobject]@{ Result = 'deprovisioned'; PackageName = $packageName }
}

function Write-BigZAnswerFile {
    param($Job, [string]$TemplatePath, [string]$Language)

    $settings = [Xml.XmlReaderSettings]::new()
    $settings.DtdProcessing = [Xml.DtdProcessing]::Prohibit
    $settings.XmlResolver = $null
    $reader = [Xml.XmlReader]::Create($TemplatePath, $settings)
    try {
        $document = [Xml.XmlDocument]::new()
        $document.XmlResolver = $null
        $document.Load($reader)
    }
    finally { $reader.Dispose() }

    $namespace = 'urn:schemas-microsoft-com:unattend'
    $manager = [Xml.XmlNamespaceManager]::new($document.NameTable)
    $manager.AddNamespace('u', $namespace)
    $shell = $document.SelectSingleNode('/u:unattend/u:settings[@pass="windowsPE"]', $manager)
    $image = $document.SelectSingleNode('//u:InstallFrom/u:MetaData[u:Key="/IMAGE/INDEX"]/u:Value', $manager)
    if ($null -eq $shell -or $null -eq $image -or $image.InnerText -cne '1') {
        throw 'Template do arquivo de resposta incompatível com o WIM exportado.'
    }
    $languageFile = Join-Path $Job.MediaPath 'sources\lang.ini'
    if ($Language -and (Test-Path -LiteralPath $languageFile -PathType Leaf)) {
        $locale = [Globalization.CultureInfo]::GetCultureInfo($Language).Name
        $languages = Get-Content -LiteralPath $languageFile -Raw -ErrorAction Stop
        if ($languages -match ('(?im)^\s*' + [regex]::Escape($locale) + '\s*=')) {
            $component = $document.CreateElement('component', $namespace)
            $component.SetAttribute('name', 'Microsoft-Windows-International-Core-WinPE')
            $component.SetAttribute('processorArchitecture', 'amd64')
            $component.SetAttribute('publicKeyToken', '31bf3856ad364e35')
            $component.SetAttribute('language', 'neutral')
            $component.SetAttribute('versionScope', 'nonSxS')
            $setupLanguage = $document.CreateElement('SetupUILanguage', $namespace)
            $uiLanguage = $document.CreateElement('UILanguage', $namespace)
            $uiLanguage.InnerText = $locale
            [void]$setupLanguage.AppendChild($uiLanguage.CloneNode($true))
            [void]$component.AppendChild($setupLanguage)
            [void]$component.AppendChild($uiLanguage)
            [void]$shell.AppendChild($component)
        }
    }
    $path = Join-Path $Job.MediaPath 'autounattend.xml'
    if ([IO.File]::Exists($path)) { throw 'O arquivo de resposta já existe no staging.' }
    $document.Save($path)
}
