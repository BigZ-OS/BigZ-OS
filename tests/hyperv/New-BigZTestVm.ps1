#Requires -Version 5.1
<#
.SYNOPSIS
    Cria a VM de teste do BigZ OS: Geração 2, Secure Boot (modelo Microsoft Windows), vTPM,
    memória dinâmica (4 GB na inicialização, mínimo 2 GB), 2 vCPU, disco dinâmico de 64 GB.

.DESCRIPTION
    Exige PowerShell como administrador e o Hyper-V já ativo. Não se autoeleva e não ativa
    o Hyper-V. Não liga a VM: use Start-BigZTestVm.ps1 (que confere a memória livre).

    Depois de instalar o Windows e rodar o Windows Update na VM, crie o ponto de verificação
    "limpo" com Checkpoint-BigZTestVm.ps1.

.EXAMPLE
    .\New-BigZTestVm.ps1 -Name BigZ-REF -IsoPath C:\DEV\BigZ-Lab\iso\Win11_Enterprise_Eval.iso
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidatePattern('^[A-Za-z0-9-]{1,40}$')]
    [string]$Name = 'BigZ-REF',

    [Parameter(Mandatory)]
    [string]$IsoPath,

    [string]$LabRoot = 'C:\DEV\BigZ-Lab',

    [ValidateRange(1, 8)]
    [int]$ProcessorCount = 2,

    # O Windows 11 exige 4 GB: a memória de inicialização não pode ser menor (ADR-005: sem burlar requisitos).
    [ValidateRange(4GB, 64GB)]
    [long]$MemoryStartupBytes = 4GB,

    [ValidateRange(1GB, 64GB)]
    [long]$MemoryMinimumBytes = 2GB,

    [ValidateRange(4GB, 64GB)]
    [long]$MemoryMaximumBytes = 4GB,

    # O Windows 11 exige 64 GB de armazenamento.
    [ValidateRange(64GB, 512GB)]
    [long]$DiskSizeBytes = 64GB,

    [string]$SwitchName = 'Default Switch',

    # Para a edição DEV (WSL 2 dentro da VM). Usa memória fixa = MemoryStartupBytes.
    [switch]$EnableNestedVirtualization
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'BigZ.HyperVLab.psm1') -Force
Assert-BigZLabElevation
Assert-BigZLabHyperV

if (-not ($MemoryMinimumBytes -le $MemoryStartupBytes -and $MemoryStartupBytes -le $MemoryMaximumBytes)) {
    throw 'Memória inválida: é preciso mínimo <= inicialização <= máximo.'
}
if (-not (Test-Path -LiteralPath $IsoPath -PathType Leaf) -or [IO.Path]::GetExtension($IsoPath) -ne '.iso') {
    throw "ISO não encontrada ou extensão diferente de .iso: $IsoPath"
}
$IsoPath = (Resolve-Path -LiteralPath $IsoPath).Path

if (Get-VM -Name $Name -ErrorAction SilentlyContinue) {
    throw "Já existe uma VM chamada '$Name'. Use outro -Name ou remova com Remove-BigZTestVm.ps1."
}
if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
    $available = (@(Get-VMSwitch | ForEach-Object { $_.Name }) -join ', ')
    throw "Switch virtual '$SwitchName' não encontrado. Disponíveis: $available"
}

$marker = (Get-BigZLabDefault).Marker
$vmRoot = Join-Path $LabRoot 'vms'
$vmDir = Join-Path $vmRoot $Name
$vhdPath = Join-Path $vmDir "Virtual Hard Disks\$Name.vhdx"
if (Test-Path -LiteralPath $vmDir) {
    throw "A pasta '$vmDir' já existe. Remova-a ou use outro -Name (nada foi sobrescrito)."
}

$hash = (Get-FileHash -LiteralPath $IsoPath -Algorithm SHA256).Hash
Write-Information "SHA-256 da ISO: $hash" -InformationAction Continue

if (-not $PSCmdlet.ShouldProcess($Name, 'Criar VM de teste Hyper-V (Gen2, vTPM, Secure Boot)')) { return }

New-Item -ItemType Directory -Path $vmDir -Force | Out-Null
$created = $false
try {
    New-VM -Name $Name -Generation 2 -MemoryStartupBytes $MemoryStartupBytes `
        -NewVHDPath $vhdPath -NewVHDSizeBytes $DiskSizeBytes `
        -SwitchName $SwitchName -Path $vmRoot | Out-Null
    $created = $true

    if ($EnableNestedVirtualization) {
        # Virtualização aninhada: memória fixa, mais previsível para o WSL 2 dentro da VM.
        Set-VMMemory -VMName $Name -DynamicMemoryEnabled $false -StartupBytes $MemoryStartupBytes
        Set-VMProcessor -VMName $Name -ExposeVirtualizationExtensions $true
    }
    else {
        Set-VMMemory -VMName $Name -DynamicMemoryEnabled $true -MinimumBytes $MemoryMinimumBytes `
            -StartupBytes $MemoryStartupBytes -MaximumBytes $MemoryMaximumBytes
    }
    Set-VMProcessor -VMName $Name -Count $ProcessorCount

    $notes = "$marker | criada $(Get-Date -Format s) | ISO SHA-256 $hash"
    Set-VM -Name $Name -AutomaticCheckpointsEnabled $false -CheckpointType Standard `
        -AutomaticStartAction Nothing -AutomaticStopAction ShutDown -Notes $notes

    Set-VMFirmware -VMName $Name -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows
    Set-VMKeyProtector -VMName $Name -NewLocalKeyProtector
    Enable-VMTPM -VMName $Name

    $dvd = Add-VMDvdDrive -VMName $Name -Path $IsoPath -Passthru
    Set-VMFirmware -VMName $Name -FirstBootDevice $dvd
}
catch {
    $err = $_
    Write-Warning "Falha ao configurar a VM; desfazendo o que foi criado. Erro: $($err.Exception.Message)"
    if ($created) { Remove-VM -Name $Name -Force -ErrorAction SilentlyContinue }
    if (Test-BigZLabPathUnderRoot -Path $vmDir -Root $vmRoot) {
        Remove-Item -LiteralPath $vmDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    throw $err
}

$vm = Get-VM -Name $Name
$fw = Get-VMFirmware -VMName $Name
$sec = Get-VMSecurity -VMName $Name
[pscustomobject]@{
    Name           = $vm.Name
    Generation     = $vm.Generation
    SecureBoot     = [string]$fw.SecureBoot
    SecureBootTmpl = [string]$fw.SecureBootTemplate
    TpmEnabled     = [bool]$sec.TpmEnabled
    DynamicMemory  = [bool]$vm.DynamicMemoryEnabled
    StartupGB      = [math]::Round($vm.MemoryStartup / 1GB, 1)
    vCPU           = $vm.ProcessorCount
    Vhd            = $vhdPath
    IsoSha256      = $hash
}

Write-Information ("Próximo passo: .\Start-BigZTestVm.ps1 -Name $Name -Connect  (instale o Windows, rode o Windows Update) " +
    "e depois .\Checkpoint-BigZTestVm.ps1 -Name $Name") -InformationAction Continue
