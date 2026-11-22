function Get-BigZWindowsToolchain {
    param([string]$OscdimgPath, [switch]$RequireOscdimg)

    $system = [Environment]::SystemDirectory
    $moduleRoot = Join-Path $system 'WindowsPowerShell\v1.0\Modules'
    Import-Module (Join-Path $moduleRoot 'Dism\Dism.psd1') -ErrorAction Stop
    Import-Module (Join-Path $moduleRoot 'Storage\Storage.psd1') -ErrorAction Stop
    $oscdimg = $null
    if ($RequireOscdimg) {
        if (-not $OscdimgPath) {
            $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
            $OscdimgPath = Join-Path $programFilesX86 'Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe'
        }
        $toolPath = Get-BigZLocalPath $OscdimgPath
        if (-not (Test-Path -LiteralPath $toolPath -PathType Leaf)) {
            throw 'Instale Deployment Tools do Windows ADK oficial ou indique -OscdimgPath.'
        }
        $tool = Get-Item -LiteralPath $toolPath -ErrorAction Stop
        $signature = Get-AuthenticodeSignature -LiteralPath $toolPath -ErrorAction Stop
        if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch '(^|,\s*)O=Microsoft Corporation(,|$)' -or
            ($tool.Name -ine 'oscdimg.exe' -or $tool.VersionInfo.ProductName -ine 'OSCDIMG')) {
            throw 'oscdimg deve ter identidade e assinatura Authenticode válidas da Microsoft.'
        }
        $oscdimg = [pscustomobject]@{
            Path = $toolPath
            Version = $tool.VersionInfo.FileVersion
            Sha256 = (Get-FileHash -LiteralPath $toolPath -Algorithm SHA256 -ErrorAction Stop).Hash
        }
    }
    $dism = Get-Item -LiteralPath (Join-Path $system 'dism.exe') -ErrorAction Stop
    $dismSignature = Get-AuthenticodeSignature -LiteralPath $dism.FullName -ErrorAction Stop
    if ($dismSignature.Status -ne 'Valid' -or $dismSignature.SignerCertificate.Subject -notmatch '(^|,\s*)O=Microsoft Corporation(,|$)') {
        throw 'A assinatura do DISM do Windows não pôde ser verificada.'
    }
    return [pscustomobject]@{
        Reg = Join-Path $system 'reg.exe'
        Robocopy = Join-Path $system 'robocopy.exe'
        DismVersion = $dism.VersionInfo.FileVersion
        Oscdimg = $oscdimg
    }
}

function Get-BigZDiskImage {
    param([string]$SourcePath)
    Storage\Get-DiskImage -ImagePath $SourcePath -StorageType ISO -ErrorAction Stop
}

function Get-BigZHostBootTime {
    $hostInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    return $hostInfo.LastBootUpTime.ToUniversalTime().ToString('o')
}

function Open-BigZIso {
    param($Job)

    if ((Get-BigZDiskImage $Job.Record.SourcePath).Attached) {
        throw 'A ISO já está conectada. Ejete essa montagem antes do build para o BigZ gerenciar sua própria leitura.'
    }
    $Job.Record.IsoBootTimeUtc = Get-BigZHostBootTime
    $Job.Record.AttachRequested = $true
    Save-BigZJobState $Job 'attaching'
    $disk = Storage\Mount-DiskImage -ImagePath $Job.Record.SourcePath -StorageType ISO -Access ReadOnly -PassThru -ErrorAction Stop
    if (-not $disk.DevicePath) { throw 'O Windows não retornou o dispositivo da ISO montada.' }
    $Job.Record.IsoDevicePath = [string]$disk.DevicePath
    Save-BigZJobState $Job 'attached'

    $volumes = @($disk | Storage\Get-Volume -ErrorAction Stop | Where-Object DriveLetter)
    if ($volumes.Count -ne 1) { throw 'Esperada uma unidade de DVD virtual atribuída à ISO.' }
    return "$($volumes[0].DriveLetter):\"
}

function Close-BigZIso {
    param($Job)

    if (-not $Job.Record.AttachRequested) { return }
    $disk = Get-BigZDiskImage $Job.Record.SourcePath
    if ($disk.Attached) {
        if (-not $Job.Record.IsoDevicePath -or $disk.DevicePath -ine $Job.Record.IsoDevicePath -or
            $Job.Record.IsoBootTimeUtc -cne (Get-BigZHostBootTime)) {
            throw 'A ISO está conectada, mas a montagem não pôde ser atribuída a este job. Verifique e ejete manualmente.'
        }
        Storage\Dismount-DiskImage -DevicePath $disk.DevicePath -ErrorAction Stop | Out-Null
    }
    $Job.Record.AttachRequested = $false
    $Job.Record.IsoDevicePath = ''
    $Job.Record.IsoBootTimeUtc = ''
    Save-BigZJobState $Job $Job.Record.Stage
}

function Get-BigZInstallerLayout {
    param([string]$MediaRoot)

    foreach ($name in @('setup.exe', 'sources\boot.wim', 'efi\boot\bootx64.efi', 'efi\microsoft\boot\efisys.bin')) {
        if (-not (Test-Path -LiteralPath (Join-Path $MediaRoot $name) -PathType Leaf)) {
            throw "Arquivo necessário ao Windows Setup x64/UEFI ausente: '$name'."
        }
    }
    $image = @(
        foreach ($name in @('sources\install.wim', 'sources\install.esd')) {
            $path = Join-Path $MediaRoot $name
            if (Test-Path -LiteralPath $path -PathType Leaf) { $path }
        }
    )
    if ($image.Count -ne 1 -or @(Get-ChildItem -LiteralPath (Join-Path $MediaRoot 'sources') -Filter 'install*.swm' -File).Count) {
        throw 'Use uma mídia com um único install.wim ou install.esd. Imagens divididas não são aceitas.'
    }
    return $image[0]
}

function Get-BigZDismOption {
    param($Job)
    return @{ LogPath = $Job.DismLog; ScratchDirectory = $Job.ScratchDirectory; ErrorAction = 'Stop' }
}

function Get-BigZImageInventory {
    param([string]$ImagePath, $Job)

    $dismOptions = Get-BigZDismOption $Job
    foreach ($item in (Dism\Get-WindowsImage -ImagePath $ImagePath @dismOptions)) {
        $detail = Dism\Get-WindowsImage -ImagePath $ImagePath -Index $item.ImageIndex @dismOptions
        $languages = @($detail.Languages | ForEach-Object { [string]$_ })
        $defaultLanguage = $null
        $languageIndex = $detail.DefaultLanguageIndex
        if ($null -ne $languageIndex -and $languageIndex -ge 0 -and $languageIndex -lt $languages.Count) {
            $defaultLanguage = $languages[$languageIndex]
        }
        if (-not $defaultLanguage -and $languages.Count -eq 1) { $defaultLanguage = $languages[0] }
        [pscustomobject]@{
            Index = [int]$detail.ImageIndex
            Name = $detail.ImageName
            Edition = $detail.EditionId
            Build = [int]$detail.Build
            Revision = [int]$detail.SPBuild
            Architecture = [int]$detail.Architecture
            InstallationType = $detail.InstallationType
            Languages = $languages
            DefaultLanguage = $defaultLanguage
        }
    }
}

function Copy-BigZInstaller {
    param([string]$SourceRoot, $Job, $Tools)

    $copyLog = Join-Path $Job.Path 'robocopy.log'
    # The dot avoids a trailing backslash directly before native argument quoting.
    $source = Join-Path $SourceRoot '.'
    $copyArgs = @($source, $Job.MediaPath, '/E', '/R:1', '/W:1', '/XJ', '/COPY:DT', '/DCOPY:DT', '/NP',
        "/LOG:$copyLog", '/XF', 'install.wim', 'install.esd', 'autounattend.xml')
    & $Tools.Robocopy @copyArgs | Out-Null
    if ($LASTEXITCODE -gt 7) { throw "Falha na cópia do instalador. Consulte '$copyLog'." }
}

function Export-BigZInstallImage {
    param([string]$SourceImage, [int]$Index, $Job)

    $dismOptions = Get-BigZDismOption $Job
    $exportArgs = @{
        SourceImagePath = $SourceImage
        SourceIndex = $Index
        DestinationImagePath = $Job.WimPath
        CompressionType = 'Max'
        CheckIntegrity = $true
    }
    Dism\Export-WindowsImage @exportArgs @dismOptions | Out-Null
}

function Open-BigZWim {
    param($Job)

    $Job.Record.WimMountRequested = $true
    Save-BigZJobState $Job 'mounting-wim'
    $dismOptions = Get-BigZDismOption $Job
    Dism\Mount-WindowsImage -ImagePath $Job.WimPath -Index 1 -Path $Job.MountPath -CheckIntegrity @dismOptions | Out-Null
}

function Get-BigZMountedImage {
    param($Job)
    $dismOptions = Get-BigZDismOption $Job
    Dism\Get-WindowsImage -Mounted @dismOptions
}

function Get-BigZOwnedWimMount {
    param($Job)

    $mountPath = Get-BigZLocalPath $Job.MountPath
    $wimPath = Get-BigZLocalPath $Job.WimPath
    $owned = @(Get-BigZMountedImage $Job | Where-Object { $_.Path.TrimEnd('\') -ieq $mountPath })
    if ($owned.Count -eq 0) { return }
    if ($owned.Count -ne 1 -or $owned[0].ImagePath -ine $wimPath -or $owned[0].ImageIndex -ne 1) {
        throw 'A montagem encontrada não corresponde ao WIM do job.'
    }
    return $owned[0]
}

function Close-BigZWim {
    param($Job, [switch]$Save)

    if (-not $Job.Record.WimMountRequested) { return }
    $mount = Get-BigZOwnedWimMount $Job
    if (-not $mount -and $Save) { throw 'Montagem do job não encontrada para commit.' }
    if ($mount) {
        $dismOptions = Get-BigZDismOption $Job
        if ($Save) {
            if ($mount.MountStatus -ne 'Ok') { throw 'Montagem incompatível com o commit.' }
            Dism\Dismount-WindowsImage -Path $Job.MountPath -Save -CheckIntegrity @dismOptions | Out-Null
        }
        else {
            if ($mount.MountStatus -eq 'NeedsRemount') {
                Dism\Mount-WindowsImage -Path $Job.MountPath -Remount @dismOptions | Out-Null
            }
            Dism\Dismount-WindowsImage -Path $Job.MountPath -Discard @dismOptions | Out-Null
        }
        if (Get-BigZOwnedWimMount $Job) { throw 'O DISM ainda apresenta a montagem do job.' }
    }
    $Job.Record.WimMountRequested = $false
    Save-BigZJobState $Job $Job.Record.Stage
}

function Invoke-BigZOscdimg {
    param($Job, $Tools, [string]$Path, [string]$VolumeLabel)

    $log = Join-Path $Job.Path 'oscdimg.log'
    $bootFile = Join-Path $Job.MediaPath 'efi\microsoft\boot\efisys.bin'
    if ((Get-FileHash -LiteralPath $Tools.Oscdimg.Path -Algorithm SHA256 -ErrorAction Stop).Hash -cne $Tools.Oscdimg.Sha256) {
        throw 'oscdimg mudou desde a verificação inicial.'
    }
    # One UEFI El Torito entry, with a boot image from the user's ISO.
    $isoArgs = @('-m', '-o', '-u2', '-udfver102', '-e', '-pEF', "-b$bootFile", "-l$VolumeLabel", $Job.MediaPath, $Path)
    & $Tools.Oscdimg.Path @isoArgs *> $log
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Path -PathType Leaf) -or (Get-Item -LiteralPath $Path).Length -eq 0) {
        throw "Falha do oscdimg. Consulte '$log'."
    }
}
