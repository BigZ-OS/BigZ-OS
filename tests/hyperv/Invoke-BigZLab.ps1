#Requires -Version 5.1
<#
.SYNOPSIS
    Ponto de entrada ÚNICO das operações elevadas do laboratório Hyper-V (uma janela de UAC por ação).

.DESCRIPTION
    Agrupa os scripts desta pasta em ações:
      Create     = New-BigZTestVm + Start-BigZTestVm -Connect
      Start      = Start-BigZTestVm -Connect
      Checkpoint = Checkpoint-BigZTestVm (padrão "limpo")
      Reset      = Restore-BigZTestVm (pede confirmação) + Start-BigZTestVm -Connect
      Baseline   = Checkpoint-BigZTestVm + Start-BigZTestVm + Invoke-BigZVmP0 (um UAC só, após instalar e atualizar)
      P0         = Invoke-BigZVmP0 (copia, roda e traz os testes P0)
      Remove     = Remove-BigZTestVm (pede confirmação)
      Status     = estado das VMs do laboratório, checkpoints e memória do host (só leitura)

    Exige PowerShell como administrador e não se autoeleva. Quem inicia a janela elevada é uma
    pessoa (aceitando o UAC), ou um agente com Start-Process -Verb RunAs, que mostra o UAC ao usuário.
    Como agentes não leem janelas elevadas (UIPI), toda execução grava em <LabRoot>\logs:
      - <data>-<ação>.log     transcrição completa
      - last-status.json      resultado da última ação (Action, Success, Error, ExitCode...)

.EXAMPLE
    # Iniciado por um agente (o usuário aceita o UAC):
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -File "C:\DEV\PROJETOS_MDEV\BigZ OS\tests\hyperv\Invoke-BigZLab.ps1" -Action Status'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Create', 'Start', 'Checkpoint', 'Reset', 'Baseline', 'P0', 'Remove', 'Status')]
    [string]$Action,

    [ValidatePattern('^[A-Za-z0-9-]{1,40}$')]
    [string]$Name = 'BigZ-REF',

    [string]$IsoPath,

    [ValidateSet('dev', 'balanced', 'full-performance')]
    [string]$Edition = 'balanced',

    [ValidatePattern('^[A-Za-z0-9._-]{1,40}$')]
    [string]$Label = 'run',

    [ValidatePattern('^[A-Za-z0-9._-]{1,60}$')]
    [string]$CheckpointName = 'limpo',

    [string]$LabRoot = 'C:\DEV\BigZ-Lab',

    [switch]$EnableNestedVirtualization,
    [switch]$InstallPester,
    [switch]$SkipOnlineSearch,
    [switch]$SkipActivation,
    [switch]$SkipWinget,
    [switch]$IncludeMutating,
    [switch]$DeleteFiles
)

$ErrorActionPreference = 'Stop'
$logDir = Join-Path $LabRoot 'logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$logFile = Join-Path $logDir "$stamp-$Action.log"
$statusFile = Join-Path $logDir 'last-status.json'

Start-Transcript -Path $logFile -Append | Out-Null
$status = [ordered]@{
    Action      = $Action
    Name        = $Name
    StartedUtc  = (Get-Date).ToUniversalTime().ToString('o')
    FinishedUtc = $null
    Success     = $false
    ExitCode    = $null
    Error       = $null
    Log         = $logFile
}

try {
    Import-Module (Join-Path $PSScriptRoot 'BigZ.HyperVLab.psm1') -Force
    Assert-BigZLabElevation
    Assert-BigZLabHyperV

    $common = @{ Name = $Name; LabRoot = $LabRoot }
    switch ($Action) {
        'Create' {
            if (-not $IsoPath) { throw 'A ação Create exige -IsoPath.' }
            $newArgs = @{ Name = $Name; LabRoot = $LabRoot; IsoPath = $IsoPath }
            if ($EnableNestedVirtualization) { $newArgs['EnableNestedVirtualization'] = $true }
            & (Join-Path $PSScriptRoot 'New-BigZTestVm.ps1') @newArgs
            & (Join-Path $PSScriptRoot 'Start-BigZTestVm.ps1') @common -Connect
        }
        'Start' {
            & (Join-Path $PSScriptRoot 'Start-BigZTestVm.ps1') @common -Connect
        }
        'Checkpoint' {
            & (Join-Path $PSScriptRoot 'Checkpoint-BigZTestVm.ps1') @common -CheckpointName $CheckpointName
        }
        'Reset' {
            & (Join-Path $PSScriptRoot 'Restore-BigZTestVm.ps1') @common -CheckpointName $CheckpointName
            & (Join-Path $PSScriptRoot 'Start-BigZTestVm.ps1') @common -Connect
        }
        { $_ -in 'P0', 'Baseline' } {
            if ($Action -eq 'Baseline') {
                & (Join-Path $PSScriptRoot 'Checkpoint-BigZTestVm.ps1') @common -CheckpointName $CheckpointName
                & (Join-Path $PSScriptRoot 'Start-BigZTestVm.ps1') @common
            }
            $p0Args = @{ Name = $Name; LabRoot = $LabRoot; Edition = $Edition; Label = $Label }
            if ($InstallPester) { $p0Args['InstallPester'] = $true }
            if ($SkipOnlineSearch) { $p0Args['SkipOnlineSearch'] = $true }
            if ($SkipActivation) { $p0Args['SkipActivation'] = $true }
            if ($SkipWinget) { $p0Args['SkipWinget'] = $true }
            if ($IncludeMutating) { $p0Args['IncludeMutating'] = $true }
            & (Join-Path $PSScriptRoot 'Invoke-BigZVmP0.ps1') @p0Args
            $status.ExitCode = $LASTEXITCODE
        }
        'Remove' {
            $rmArgs = @{ Name = $Name; LabRoot = $LabRoot }
            if ($DeleteFiles) { $rmArgs['DeleteFiles'] = $true }
            & (Join-Path $PSScriptRoot 'Remove-BigZTestVm.ps1') @rmArgs
        }
        'Status' {
            $marker = (Get-BigZLabDefault).Marker
            $mem = Get-BigZLabHostMemory
            $vms = @(Get-VM | Where-Object { [string]$_.Notes -match [regex]::Escape($marker) } | ForEach-Object {
                    [pscustomobject]@{
                        Name        = $_.Name
                        State       = [string]$_.State
                        Heartbeat   = [string]$_.Heartbeat
                        MemoryGB    = [math]::Round($_.MemoryAssigned / 1GB, 1)
                        Checkpoints = (@(Get-VMSnapshot -VMName $_.Name | ForEach-Object { $_.Name }) -join ', ')
                    }
                })
            Write-Information -MessageData ($vms | Format-Table -AutoSize | Out-String) -InformationAction Continue
            Write-Information ("Host: {0:N1} GB livres de {1:N1} GB." -f ($mem.FreeBytes / 1GB), ($mem.TotalBytes / 1GB)) -InformationAction Continue
            $status['Vms'] = $vms
            $status['HostFreeGB'] = [math]::Round($mem.FreeBytes / 1GB, 1)
        }
    }
    $status.Success = ($null -eq $status.ExitCode) -or ($status.ExitCode -eq 0)
}
catch {
    $status.Error = $_.Exception.Message
    Write-Warning "Falhou: $($status.Error)"
}
finally {
    $status.FinishedUtc = (Get-Date).ToUniversalTime().ToString('o')
    [pscustomobject]$status | ConvertTo-Json -Depth 4 | Out-File -FilePath $statusFile -Encoding utf8
    Write-Information "Log: $logFile | Status: $statusFile" -InformationAction Continue
    Stop-Transcript | Out-Null
}

if (-not $status.Success) { exit 1 }
