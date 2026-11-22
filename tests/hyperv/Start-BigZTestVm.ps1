#Requires -Version 5.1
<#
.SYNOPSIS
    Liga uma VM do laboratório BigZ, respeitando "uma VM por vez" e a memória livre do host.

.DESCRIPTION
    Exige PowerShell como administrador. Não se autoeleva. Recusa ligar se outra VM estiver
    ligada ou se faltar memória livre para a memória de inicialização + margem.

.EXAMPLE
    .\Start-BigZTestVm.ps1 -Name BigZ-REF -Connect
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidatePattern('^[A-Za-z0-9-]{1,40}$')]
    [string]$Name = 'BigZ-REF',

    [string]$LabRoot = 'C:\DEV\BigZ-Lab',

    # Margem de memória que fica para o host além da memória de inicialização da VM.
    [ValidateRange(256MB, 4GB)]
    [long]$HostMarginBytes = 512MB,

    # Abre a janela de console da VM (vmconnect).
    [switch]$Connect
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'BigZ.HyperVLab.psm1') -Force
Assert-BigZLabElevation
Assert-BigZLabHyperV

$vm = Get-BigZLabVm -Name $Name -LabRoot $LabRoot
if ([string]$vm.State -eq 'Running') {
    Write-Information "A VM '$Name' já está ligada." -InformationAction Continue
}
else {
    Assert-BigZLabSingleVm -ExceptName $Name
    $mem = Get-BigZLabHostMemory
    $cap = Test-BigZLabStartCapacity -FreeBytes $mem.FreeBytes -StartupBytes $vm.MemoryStartup -MarginBytes $HostMarginBytes
    if (-not $cap.CanStart) { throw $cap.Reason }

    if ($PSCmdlet.ShouldProcess($Name, 'Ligar VM')) {
        Start-VM -Name $Name
        Write-Information ("VM '{0}' ligada. Memória livre no host antes do boot: {1:N1} GB." -f $Name, ($mem.FreeBytes / 1GB)) -InformationAction Continue
    }
}

if ($Connect) {
    Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\vmconnect.exe') -ArgumentList 'localhost', $Name
}
