#Requires -Version 5.1
<#
.SYNOPSIS
    Volta a VM de teste a um checkpoint (padrão: "limpo"). Descarta o estado atual da VM.

.DESCRIPTION
    Exige PowerShell como administrador. Não se autoeleva. A VM é desligada à força antes
    da restauração (o estado atual será descartado de qualquer forma).

.EXAMPLE
    .\Restore-BigZTestVm.ps1 -Name BigZ-REF
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [ValidatePattern('^[A-Za-z0-9-]{1,40}$')]
    [string]$Name = 'BigZ-REF',

    [ValidatePattern('^[A-Za-z0-9._-]{1,60}$')]
    [string]$CheckpointName = 'limpo',

    [string]$LabRoot = 'C:\DEV\BigZ-Lab'
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'BigZ.HyperVLab.psm1') -Force
Assert-BigZLabElevation
Assert-BigZLabHyperV

$vm = Get-BigZLabVm -Name $Name -LabRoot $LabRoot
$snap = Get-VMSnapshot -VMName $Name -Name $CheckpointName -ErrorAction SilentlyContinue
if (-not $snap) {
    $list = (@(Get-VMSnapshot -VMName $Name | ForEach-Object { $_.Name }) -join ', ')
    throw "Checkpoint '$CheckpointName' não existe na VM '$Name'. Disponíveis: $list"
}

if (-not $PSCmdlet.ShouldProcess("$Name -> $CheckpointName", 'Descartar o estado atual e restaurar o checkpoint')) { return }

if ([string]$vm.State -ne 'Off') { Stop-VM -Name $Name -TurnOff -Force }
Restore-VMSnapshot -VMName $Name -Name $CheckpointName -Confirm:$false
Write-Information "VM '$Name' restaurada para '$CheckpointName' (desligada). Ligue com Start-BigZTestVm.ps1." -InformationAction Continue
