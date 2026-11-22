#Requires -Version 5.1
<#
.SYNOPSIS
    Cria o ponto de verificação (checkpoint) "limpo" da VM de teste, com ela desligada.

.DESCRIPTION
    Use depois de instalar o Windows, concluir a OOBE e rodar o Windows Update até não haver
    pendências. Desliga a VM de forma limpa (pelo Windows convidado), ejeta a ISO, põe o disco
    como primeiro boot e cria o checkpoint.

    Exige PowerShell como administrador. Não se autoeleva.

.EXAMPLE
    .\Checkpoint-BigZTestVm.ps1 -Name BigZ-REF                 # cria "limpo"
    .\Checkpoint-BigZTestVm.ps1 -Name BigZ-REF -CheckpointName balanced-aplicada
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidatePattern('^[A-Za-z0-9-]{1,40}$')]
    [string]$Name = 'BigZ-REF',

    [ValidatePattern('^[A-Za-z0-9._-]{1,60}$')]
    [string]$CheckpointName = 'limpo',

    [string]$LabRoot = 'C:\DEV\BigZ-Lab',

    # Mantém a ISO no drive de DVD (padrão: ejeta).
    [switch]$KeepIso,

    # Substitui um checkpoint com o mesmo nome.
    [switch]$Replace
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'BigZ.HyperVLab.psm1') -Force
Assert-BigZLabElevation
Assert-BigZLabHyperV

$vm = Get-BigZLabVm -Name $Name -LabRoot $LabRoot
$existing = Get-VMSnapshot -VMName $Name -Name $CheckpointName -ErrorAction SilentlyContinue
if ($existing -and -not $Replace) {
    throw "Já existe o checkpoint '$CheckpointName' na VM '$Name'. Use -Replace para substituí-lo."
}

if (-not $PSCmdlet.ShouldProcess("$Name / $CheckpointName", 'Desligar a VM e criar checkpoint')) { return }

if ([string]$vm.State -ne 'Off') {
    Write-Information "Desligando '$Name' pelo Windows convidado..." -InformationAction Continue
    Stop-VM -Name $Name   # desligamento limpo; falha se os serviços de integração não responderem
}

if (-not $KeepIso) {
    Get-VMDvdDrive -VMName $Name | Set-VMDvdDrive -Path $null
    $disk = Get-VMHardDiskDrive -VMName $Name | Select-Object -First 1
    if ($disk) { Set-VMFirmware -VMName $Name -FirstBootDevice $disk }
}

if ($existing) { Remove-VMSnapshot -VMName $Name -Name $CheckpointName }
Checkpoint-VM -Name $Name -SnapshotName $CheckpointName

$snap = Get-VMSnapshot -VMName $Name -Name $CheckpointName
if (-not $snap) { throw "O checkpoint '$CheckpointName' não foi criado." }
Write-Information ("Checkpoint '{0}' criado em {1}." -f $CheckpointName, $snap.CreationTime) -InformationAction Continue
