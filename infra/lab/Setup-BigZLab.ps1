<#
.SYNOPSIS
    Prepara um PC Windows 11 Pro para desenvolver e testar o BigZ OS (rodar como administrador, um unico UAC).
.DESCRIPTION
    1) Ferramentas via winget (fontes oficiais): Git, GitHub CLI, rclone, Windows ADK (somente Deployment Tools).
    2) Modulos PowerShell do usuario: Pester 5.7.1 e PSScriptAnalyzer.
    3) Ativa o Hyper-V (exige Windows Pro/Enterprise e reinicio).
    4) Cria as pastas do laboratorio em <LabRoot>.
    Nao reinicia sozinho. Log em <LabRoot>\logs\setup-<data>.log e status em <LabRoot>\logs\setup-status.json.
#>
[CmdletBinding()]
param(
    [string]$LabRoot = 'C:\DEV\BigZ-Lab',
    [switch]$SkipHyperV
)
$ErrorActionPreference = 'Stop'
foreach ($d in 'iso', 'iso-eval', 'work', 'out', 'vms', 'logs', 'results', 'tools') {
    New-Item -ItemType Directory -Force -Path (Join-Path $LabRoot $d) | Out-Null
}
$logs = Join-Path $LabRoot 'logs'
Start-Transcript -Path (Join-Path $logs ("setup-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))) | Out-Null
$status = [ordered]@{ started = (Get-Date).ToString('o'); ok = $false; restartNeeded = $false; installed = @(); error = $null }
try {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) { throw 'Execute este script como administrador.' }

    Write-Output '== Ferramentas (winget)'
    $packages = [ordered]@{
        'Git.Git'               = $null
        'GitHub.cli'            = $null
        'Rclone.Rclone'         = $null
        'Microsoft.WindowsADK'  = '/features OptionId.DeploymentTools /quiet /norestart /ceip off'
    }
    foreach ($id in $packages.Keys) {
        $null = winget list --id $id -e --accept-source-agreements 2>$null
        if ($LASTEXITCODE -eq 0) { Write-Output "$id ja instalado."; continue }
        $wingetArgs = @('install', '--id', $id, '-e', '--silent', '--accept-source-agreements', '--accept-package-agreements')
        if ($packages[$id]) { $wingetArgs += @('--override', $packages[$id]) }
        & winget @wingetArgs
        if ($LASTEXITCODE -ne 0) { throw "Falha ao instalar $id (codigo $LASTEXITCODE)." }
        $status.installed += $id
    }

    Write-Output '== Modulos PowerShell'
    if (-not (Get-Module -ListAvailable Pester | Where-Object Version -eq '5.7.1')) {
        Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser -SkipPublisherCheck -Force
        $status.installed += 'Pester 5.7.1'
    }
    if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
        Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
        $status.installed += 'PSScriptAnalyzer'
    }

    if (-not $SkipHyperV) {
        Write-Output '== Hyper-V'
        $hv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
        if ($hv.State -ne 'Enabled') {
            $r = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All -NoRestart
            $status.restartNeeded = [bool]$r.RestartNeeded
            $status.installed += 'Hyper-V'
        } else { Write-Output 'Hyper-V ja estava ativado.' }
    }
    $status.ok = $true
    Write-Output ('CONCLUIDO. Reinicio necessario: {0}' -f $status.restartNeeded)
}
catch { $status.error = $_.Exception.Message; Write-Output "ERRO: $($status.error)" }
finally {
    $status.finished = (Get-Date).ToString('o')
    $status | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $logs 'setup-status.json') -Encoding UTF8
    Stop-Transcript | Out-Null
}
