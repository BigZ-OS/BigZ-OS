function Assert-BigZElevation {
    if (-not [Environment]::Is64BitProcess -or $PSVersionTable.PSEdition -ne 'Desktop') {
        throw 'Use o Windows PowerShell 5.1 x64 para inspecionar, construir ou recuperar mídia.'
    }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    try {
        $account = [Security.Principal.WindowsPrincipal]::new($identity)
        if (-not $account.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw 'Abra o Windows PowerShell x64 como administrador, aceite o UAC e execute novamente este comando.'
        }
    }
    finally { $identity.Dispose() }
}

function Get-BigZLocalPath {
    param([string]$Path)

    $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    if ($resolved -notmatch '^[A-Za-z]:\\' -or $resolved.Substring(2).Contains(':')) {
        throw "Caminho local de sistema de arquivos exigido: '$Path'."
    }
    $fullPath = [IO.Path]::GetFullPath($resolved)
    $candidate = $fullPath
    while ($candidate) {
        if (Test-Path -LiteralPath $candidate) {
            $item = Get-Item -LiteralPath $candidate -Force -ErrorAction Stop
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Caminho com link ou ponto de montagem: '$candidate'."
            }
        }
        $candidate = [IO.Path]::GetDirectoryName($candidate)
    }
    return $fullPath
}

function Test-BigZWithinPath {
    param([string]$Path, [string]$Parent)

    $prefix = $Parent.TrimEnd('\') + '\'
    return $Path.TrimEnd('\') -ieq $Parent.TrimEnd('\') -or
        $Path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
}

function Get-BigZLabLocation {
    param([string]$Path)

    $fullPath = Get-BigZLocalPath $Path
    $project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
    if (Test-BigZWithinPath $fullPath $project) {
        throw "Mídia e arquivos do laboratório devem ficar fora do repositório: '$fullPath'."
    }
    return $fullPath
}

function Assert-BigZCapacity {
    param([string]$WorkRoot, [string]$OutputPath, [long]$SourceBytes, [switch]$InspectOnly)

    $workDrive = [IO.DriveInfo]::new([IO.Path]::GetPathRoot($WorkRoot))
    if ($workDrive.DriveType -ne [IO.DriveType]::Fixed -or $workDrive.DriveFormat -ne 'NTFS') {
        throw 'A área de trabalho do DISM exige um volume NTFS local fixo.'
    }
    if ($InspectOnly) { return }
    $outputDrive = [IO.DriveInfo]::new([IO.Path]::GetPathRoot($OutputPath))
    if ($outputDrive.DriveType -ne [IO.DriveType]::Fixed -or $outputDrive.DriveFormat -ne 'NTFS') {
        throw 'A saída exige um volume NTFS local fixo.'
    }
    $workSpace = 3 * $SourceBytes + 25GB
    $outputSpace = 2 * $SourceBytes + 2GB
    if ($workDrive.Name -ieq $outputDrive.Name) {
        $workSpace += $outputSpace
        $outputSpace = 0
    }
    if ($workDrive.AvailableFreeSpace -lt $workSpace -or $outputDrive.AvailableFreeSpace -lt $outputSpace) {
        throw 'Espaço livre insuficiente para a cópia, a manutenção do WIM e a ISO de saída.'
    }
}

function Get-BigZJob {
    param([string]$WorkRoot, [guid]$Id)

    if ($Id -eq [guid]::Empty) { throw 'ID de job inválido.' }
    $token = $Id.ToString('N')
    $path = Get-BigZLocalPath (Join-Path $WorkRoot "job-$token")
    return [pscustomobject]@{
        Id = $token
        Path = $path
        StatePath = Join-Path $path 'job.json'
        MediaPath = Join-Path $path 'media'
        MountPath = Join-Path $path 'mount'
        ScratchDirectory = Join-Path $path 'scratch'
        DismLog = Join-Path $path 'dism.log'
        WimPath = Join-Path $path 'media\sources\install.wim'
        HiveName = "BigZ_$token"
        Record = $null
    }
}

function Save-BigZJobState {
    param($Job, [string]$Stage)

    Write-Verbose "Job $($Job.Id): $Stage"
    $Job.Record.Stage = $Stage
    $Job.Record.UpdatedAtUtc = [datetime]::UtcNow.ToString('o')
    $stateFile = Get-BigZLocalPath $Job.StatePath
    $pending = Join-Path $Job.Path ("state-$([guid]::NewGuid().ToString('N')).tmp")
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($Job.Record | ConvertTo-Json -Depth 5))
    try {
        $stream = [IO.File]::Open($pending, 'CreateNew', 'Write', 'None')
        try {
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush($true)
        }
        finally { $stream.Dispose() }
        if ([IO.File]::Exists($stateFile)) { [IO.File]::Replace($pending, $stateFile, [NullString]::Value) }
        else { [IO.File]::Move($pending, $stateFile) }
    }
    finally {
        if ([IO.File]::Exists($pending)) { [IO.File]::Delete($pending) }
    }
}

function Initialize-BigZJob {
    param([string]$WorkRoot, [string]$SourcePath, [switch]$TestOnly)

    $job = Get-BigZJob $WorkRoot ([guid]::NewGuid())
    foreach ($directory in @($job.Path, $job.MediaPath, $job.MountPath, $job.ScratchDirectory)) {
        [void][IO.Directory]::CreateDirectory($directory)
    }
    $job.Record = [pscustomobject]@{
        SchemaVersion = 1
        Id = $job.Id
        SourcePath = $SourcePath
        TestOnly = [bool]$TestOnly
        Stage = ''
        UpdatedAtUtc = ''
        AttachRequested = $false
        IsoDevicePath = ''
        IsoBootTimeUtc = ''
        WimMountRequested = $false
        HiveLoadRequested = $false
    }
    Save-BigZJobState $job 'created'
    return $job
}

function Read-BigZJob {
    param([string]$WorkRoot, [guid]$Id)

    $job = Get-BigZJob $WorkRoot $Id
    $stateFile = Get-BigZLocalPath $job.StatePath
    $record = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($record.SchemaVersion -ne 1 -or $record.Id -cne $job.Id -or $record.SourcePath -isnot [string] -or
        $record.IsoDevicePath -isnot [string] -or $record.IsoBootTimeUtc -isnot [string] -or
        $record.AttachRequested -isnot [bool] -or
        $record.WimMountRequested -isnot [bool] -or $record.HiveLoadRequested -isnot [bool]) {
        throw "Diário incompatível para '$($job.Id)'."
    }
    $record.SourcePath = Get-BigZLabLocation $record.SourcePath
    $job.Record = $record
    return $job
}

function Enter-BigZMediaLock {
    $mutex = [Threading.Mutex]::new($false, 'Global\BigZ.OS.F2.Media')
    $acquired = $false
    try {
        try { $acquired = $mutex.WaitOne(0) }
        catch [Threading.AbandonedMutexException] { $acquired = $true }
        if (-not $acquired) { throw 'Já existe uma operação do builder em andamento neste computador.' }
        return $mutex
    }
    finally {
        if (-not $acquired) { $mutex.Dispose() }
    }
}

function Exit-BigZMediaLock {
    param([Threading.Mutex]$Mutex)
    try { $Mutex.ReleaseMutex() }
    finally { $Mutex.Dispose() }
}

function Get-BigZJobPayloadPath {
    param($Job)

    $jobPath = Get-BigZLocalPath $Job.Path
    $directories = @(Get-ChildItem -LiteralPath $jobPath -Force -ErrorAction Stop |
        Where-Object { $_.Name -in @('media', 'mount', 'scratch') })
    foreach ($directory in $directories) {
        $candidate = Get-BigZLocalPath $directory.FullName
        if ([IO.Path]::GetDirectoryName($candidate) -ine $jobPath -or -not $directory.PSIsContainer -or
            (Test-BigZWithinPath $Job.Record.SourcePath $candidate)) {
            throw "Pasta de limpeza incompatível com o job: '$candidate'."
        }

        # Inspect one level at a time so enumeration never follows a junction in the payload.
        $pending = [Collections.Generic.Stack[IO.FileSystemInfo]]::new()
        $pending.Push($directory)
        while ($pending.Count) {
            $item = $pending.Pop()
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Link ou ponto de montagem preservado em '$($item.FullName)'."
            }
            if ($item -is [IO.DirectoryInfo]) {
                foreach ($child in (Get-ChildItem -LiteralPath $item.FullName -Force -ErrorAction Stop)) {
                    $pending.Push($child)
                }
            }
        }
    }
    $directories | ForEach-Object { $_.FullName }
}

function Clear-BigZJobPayload {
    param([string[]]$Path)

    foreach ($directory in $Path) {
        Remove-Item -LiteralPath $directory -Recurse -Force -Confirm:$false -ErrorAction Stop
    }
}
