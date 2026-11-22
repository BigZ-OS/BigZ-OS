<#
.SYNOPSIS
    Roda o builder do BigZ OS no laboratorio local, elevado, e grava o status em JSON.
.DESCRIPTION
    Pensado para ser disparado com um unico aviso de UAC por um agente nao elevado:
      Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','<repo>\infra\lab\Invoke-BigZLabBuild.ps1','-TestOnly'
    O resultado fica em <LabRoot>\logs\build-status.json (legivel sem elevacao).
    Requer: administrador, Windows ADK (Deployment Tools) e exatamente 1 ISO oficial em <LabRoot>\iso.
.PARAMETER TestOnly
    Usa a ISO Windows 11 Enterprise Evaluation (somente laboratorio, ver ADR-010).
#>
[CmdletBinding()]
param(
    [ValidateSet('balanced', 'dev', 'full-performance')]
    [string]$BuildProfile = 'balanced',
    [switch]$TestOnly,
    [string]$WindowsEdition,
    [string]$LabRoot = 'C:\DEV\BigZ-Lab'
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$builder = Join-Path $repoRoot 'builder\Build-BigZIso.ps1'
$logs = Join-Path $LabRoot 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$statusFile = Join-Path $logs 'build-status.json'
Start-Transcript -Path (Join-Path $logs "build-$stamp.log") | Out-Null
$status = [ordered]@{ started = (Get-Date).ToString('o'); ok = $false; step = 'init'; profile = $BuildProfile; testOnly = [bool]$TestOnly; error = $null; output = $null; inventory = $null }
try {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) { throw 'Execute como administrador.' }
    if (Get-Command Get-VM -ErrorAction SilentlyContinue) {
        $running = @(Get-VM | Where-Object State -eq 'Running')
        if ($running.Count -gt 0) { throw 'Ha VM ligada; desligue antes do build.' }
    }

    $media = @(Get-ChildItem -LiteralPath (Join-Path $LabRoot 'iso') -Filter '*.iso' -File)
    if ($media.Count -ne 1) { throw "Esperada 1 ISO em $LabRoot\iso, encontradas $($media.Count)." }
    if (-not $WindowsEdition) { $WindowsEdition = if ($TestOnly) { 'EnterpriseEval' } else { 'Professional' } }

    $status.step = 'inspect'
    $plan = & $builder -Plan -InspectMedia -Profile $BuildProfile -IsoPath $media[0].FullName
    $status.inventory = @($plan.ImageInventory | Select-Object Index, Name, Edition, Build, Architecture, DefaultLanguage)

    $status.step = 'build'
    $suffix = if ($TestOnly) { 'TESTONLY' } else { 'x64' }
    $out = Join-Path $LabRoot ("out\BigZ-{0}-{1}.iso" -f $BuildProfile, $suffix)
    $buildArgs = @{
        Build          = $true
        Profile        = $BuildProfile
        IsoPath        = $media[0].FullName
        WindowsEdition = $WindowsEdition
        WorkRoot       = (Join-Path $LabRoot 'work')
        OutputPath     = $out
        Verbose        = $true
    }
    if ($TestOnly) { $buildArgs.TestOnly = $true }
    # Nao propagar 'Stop' ao builder: no PowerShell 5.1 o stderr de ferramentas nativas viraria erro fatal.
    $ErrorActionPreference = 'Continue'
    & $builder @buildArgs
    if (-not (Test-Path -LiteralPath $out)) { throw 'Build terminou sem gerar a ISO.' }
    $hashLine = [string](Get-Content -LiteralPath "$out.sha256" -ErrorAction SilentlyContinue | Select-Object -First 1)
    $status.output = [ordered]@{ iso = $out; gb = [math]::Round((Get-Item -LiteralPath $out).Length / 1GB, 2); sha256 = ($hashLine -split '\s+')[0] }
    $status.step = 'done'
    $status.ok = $true
}
catch { $status.error = $_.Exception.Message; Write-Output "ERRO: $($status.error)" }
finally {
    $status.finished = (Get-Date).ToString('o')
    $status | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $statusFile -Encoding UTF8
    Stop-Transcript | Out-Null
}
