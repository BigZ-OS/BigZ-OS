#Requires -Version 5.1
<#
.SYNOPSIS
    Remove uma VM do laboratório BigZ e, com -DeleteFiles, apaga o disco e os checkpoints.

.DESCRIPTION
    Só remove VMs criadas pelo New-BigZTestVm.ps1: marcador "BigZ-Lab" nas Notes e pasta
    dentro de <LabRoot>\vms. Qualquer outra VM do usuário é recusada.
    Exige PowerShell como administrador. Não se autoeleva. Pede confirmação (ConfirmImpact High).

.EXAMPLE
    .\Remove-BigZTestVm.ps1 -Name BigZ-REF -DeleteFiles
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9-]{1,40}$')]
    [string]$Name,

    [string]$LabRoot = 'C:\DEV\BigZ-Lab',

    # Apaga também a pasta da VM (VHDX, checkpoints, configuração).
    [switch]$DeleteFiles
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'BigZ.HyperVLab.psm1') -Force
Assert-BigZLabElevation
Assert-BigZLabHyperV

$vm = Get-BigZLabVm -Name $Name -LabRoot $LabRoot
$vmRoot = Join-Path $LabRoot 'vms'
$vmDir = Join-Path $vmRoot $Name

$action = if ($DeleteFiles) { "Remover a VM e APAGAR $vmDir" } else { 'Remover a VM (os arquivos ficam no disco)' }
if (-not $PSCmdlet.ShouldProcess($Name, $action)) { return }

if ([string]$vm.State -ne 'Off') { Stop-VM -Name $Name -TurnOff -Force }
Remove-VM -Name $Name -Force

if ($DeleteFiles) {
    if (-not (Test-BigZLabPathUnderRoot -Path $vmDir -Root $vmRoot)) {
        throw "Recusado: '$vmDir' não está dentro de '$vmRoot'."
    }
    if (Test-Path -LiteralPath $vmDir) { Remove-Item -LiteralPath $vmDir -Recurse -Force }
    Write-Information "VM '$Name' removida e pasta apagada: $vmDir" -InformationAction Continue
}
else {
    Write-Information "VM '$Name' removida. Arquivos mantidos em $vmDir" -InformationAction Continue
}
