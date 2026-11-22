function ConvertTo-BigZNativeArgument {
    param([AllowEmptyString()][string]$Value)

    if ($Value.Length -ne 0 -and $Value -notmatch '[\s"]') { return $Value }
    # Escape quotes and double backslashes immediately before a quote or the closing delimiter.
    $escaped = $Value -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1'
    return '"' + $escaped + '"'
}

function Get-BigZErrorText {
    param([System.Management.Automation.ErrorRecord]$Record)

    foreach ($message in @($Record.Exception.Message, $Record.ToString(), $Record.FullyQualifiedErrorId)) {
        if (-not [string]::IsNullOrWhiteSpace($message)) { return $message.Trim() }
    }
    return $Record.Exception.GetType().FullName
}

function Get-BigZNativeFailure {
    param([string]$Message, [string]$LogPath, [Nullable[int]]$ExitCode)

    $failure = [InvalidOperationException]::new($Message)
    $failure.Data['BigZLogPath'] = $LogPath
    if ($null -ne $ExitCode) { $failure.Data['BigZExitCode'] = [int]$ExitCode }
    return $failure
}

function Invoke-BigZNativeCommand {
    param([string]$FilePath, [string[]]$ArgumentList, [string]$LogPath, [int]$MaximumSuccessCode = 0)

    $ErrorActionPreference = 'Stop'
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $FilePath
    $start.Arguments = ($ArgumentList | ForEach-Object { ConvertTo-BigZNativeArgument $_ }) -join ' '
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    # A hidden Win32 console starts on the system OEM page, even if the caller uses UTF-8.
    $oemEncoding = [Text.Encoding]::GetEncoding((Get-WinSystemLocale -ErrorAction Stop).TextInfo.OEMCodePage)
    $start.StandardOutputEncoding = $oemEncoding
    $start.StandardErrorEncoding = $oemEncoding
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    $launched = $false
    $exitCode = $null
    $tool = [IO.Path]::GetFileName($FilePath)
    try {
        $launched = $process.Start()
        if (-not $launched) { throw 'O Windows não iniciou o processo.' }
        # Drain both streams concurrently without turning stderr into PowerShell errors.
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        $exitCode = $process.ExitCode
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        $log = @("[$tool] código de saída: $exitCode", '[stdout]', $stdout.TrimEnd(),
            '[stderr]', $stderr.TrimEnd(), '') -join [Environment]::NewLine
        [IO.File]::AppendAllText($LogPath, $log, [Text.UTF8Encoding]::new($false))
    }
    catch {
        $detail = Get-BigZErrorText $_
        throw (Get-BigZNativeFailure "Falha ao executar ou registrar $tool. $detail" $LogPath $exitCode)
    }
    finally {
        try {
            if ($launched -and -not $process.HasExited) {
                $process.Kill()
                $process.WaitForExit()
            }
        }
        finally { $process.Dispose() }
    }

    if ($exitCode -lt 0 -or $exitCode -gt $MaximumSuccessCode) {
        throw (Get-BigZNativeFailure "$tool retornou falha (código de saída $exitCode)." $LogPath $exitCode)
    }
    return $exitCode
}

function Get-BigZJobFailureMessage {
    param($Job, [System.Management.Automation.ErrorRecord]$Failure)

    $stage = $Job.Record.Stage
    $data = $Failure.Exception.Data
    $code = 'indisponível'
    if ($data.Contains('BigZExitCode')) { $code = [string]$data['BigZExitCode'] }
    $logPath = $data['BigZLogPath']
    if (-not $logPath) {
        $logName = switch ($stage) {
            'copying' { 'robocopy.log' }
            'editing-hive' { 'registry.log' }
            'packaging' { 'oscdimg.log' }
            default { 'dism.log' }
        }
        $logPath = Join-Path $Job.Path $logName
    }

    $message = "Job $($Job.Id) em '$($Job.Path)': etapa '$stage', código de saída $code. $(Get-BigZErrorText $Failure)"
    try {
        $tail = @(Get-Content -LiteralPath $logPath -Encoding UTF8 -Tail 16 -ErrorAction Stop |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Last 8)
        if ($tail.Count) {
            return $message + [Environment]::NewLine + "Últimas linhas de '$logPath':" +
                [Environment]::NewLine + ($tail -join [Environment]::NewLine)
        }
    }
    catch {
        return "$message Log '$logPath' indisponível."
    }
    return "$message Log '$logPath' sem linhas disponíveis."
}
