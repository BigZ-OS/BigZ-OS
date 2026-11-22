# BigZ OS - backup do projeto para o Google Drive via rclone
# Espelho em gdrive:BigZ-OS-Backup/atual; arquivos alterados/apagados vão para versoes/<data>.
# Requer o remote "gdrive" (escopo drive.file) já configurado no rclone.
param(
    [string]$Source = (Split-Path -Parent $PSScriptRoot),
    [string]$Remote = 'gdrive:BigZ-OS-Backup',
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

$rclone = (Get-Command rclone -ErrorAction SilentlyContinue).Source
if (-not $rclone) {
    $rclone = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Rclone.Rclone*" -Recurse -Filter rclone.exe |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $rclone) { throw 'rclone não encontrado.' }

$stamp  = Get-Date -Format 'yyyy-MM-dd_HHmm'
$logDir = Join-Path $env:LOCALAPPDATA 'BigZ-OS\backup-logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir "backup-$stamp.log"

$rcArgs = @(
    'sync', $Source, "$Remote/atual",
    '--backup-dir', "$Remote/versoes/$stamp",
    '--exclude', 'builder/_refs/**',
    '--exclude', '*.iso', '--exclude', '*.wim', '--exclude', '*.esd',
    '--exclude', '*.vhd', '--exclude', '*.vhdx',
    '--exclude', '.env', '--exclude', '*.pfx', '--exclude', '*.key',
    '--exclude', '~$*',
    '--log-file', $logFile, '--log-level', 'INFO', '--stats-one-line'
)
if ($DryRun) { $rcArgs += '--dry-run' }

& $rclone @rcArgs
if ($LASTEXITCODE -ne 0) { throw "rclone terminou com código $LASTEXITCODE. Log: $logFile" }
Write-Output "Backup concluído ($stamp). Log: $logFile"

