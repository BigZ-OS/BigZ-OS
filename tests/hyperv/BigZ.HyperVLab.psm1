#Requires -Version 5.1
<#
.SYNOPSIS
    Funções de apoio do laboratório Hyper-V do BigZ OS (usadas pelos scripts desta pasta).

.DESCRIPTION
    Guardas de segurança comuns:
    - exigir PowerShell elevado (sem autoelevação);
    - exigir o módulo Hyper-V (sem ativá-lo);
    - só mexer em VMs marcadas como do laboratório BigZ e dentro da pasta do laboratório;
    - uma VM ligada por vez e memória livre suficiente no host.
#>

Set-StrictMode -Version 2.0

$script:LabMarker = 'BigZ-Lab'
$script:DefaultLabRoot = 'C:\DEV\BigZ-Lab'

function Get-BigZLabDefault {
    <# Valores padrão do laboratório. #>
    [CmdletBinding()]
    param()
    return [pscustomobject]@{
        Marker  = $script:LabMarker
        LabRoot = $script:DefaultLabRoot
    }
}

function Test-BigZLabElevation {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-BigZLabElevation {
    <# Falha com mensagem clara se não estiver elevado. Nunca tenta se autoelevar. #>
    [CmdletBinding()]
    param()
    if (-not (Test-BigZLabElevation)) {
        throw ('Este script precisa de um PowerShell aberto como administrador (aceite o UAC). ' +
            'Ele não se autoeleva de propósito. Abra "Windows PowerShell" > "Executar como administrador" e rode de novo.')
    }
}

function Assert-BigZLabHyperV {
    <# Falha se o módulo Hyper-V não estiver disponível. Não ativa nada. #>
    [CmdletBinding()]
    param()
    if (-not (Get-Command -Name 'New-VM' -Module 'Hyper-V' -ErrorAction SilentlyContinue)) {
        throw ('O Hyper-V não está ativo neste PC (módulo Hyper-V ausente). Este script NÃO o ativa. ' +
            'Com aprovação do usuário, um administrador roda: ' +
            'Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All  (exige reiniciar).')
    }
}

function Test-BigZLabPathUnderRoot {
    <# $true se $Path estiver DENTRO de $Root (nunca igual à raiz). Função pura. #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Root
    )
    try {
        $full = [IO.Path]::GetFullPath($Path).TrimEnd('\')
        $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    }
    catch {
        return $false
    }
    if (-not $rootFull -or $full.Length -le $rootFull.Length) { return $false }
    return $full.StartsWith($rootFull + '\', [StringComparison]::OrdinalIgnoreCase)
}

function Get-BigZLabHostMemory {
    <# Memória física do host, em bytes. #>
    [CmdletBinding()]
    param()
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    return [pscustomobject]@{
        TotalBytes = [long]$os.TotalVisibleMemorySize * 1KB
        FreeBytes  = [long]$os.FreePhysicalMemory * 1KB
    }
}

function Test-BigZLabStartCapacity {
    <#
        Decide se há memória livre para ligar uma VM. O Hyper-V precisa da memória de
        INICIALIZAÇÃO livre no momento do boot; somamos uma margem para o host. Função pura.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][long]$FreeBytes,
        [Parameter(Mandatory)][long]$StartupBytes,
        [long]$MarginBytes = 512MB
    )
    $needed = $StartupBytes + $MarginBytes
    $ok = $FreeBytes -ge $needed
    $reason = if ($ok) { 'ok' } else {
        ('Memória livre insuficiente: {0:N1} GB livres, são necessários {1:N1} GB ({2:N1} GB da VM + {3:N1} GB de margem). ' +
            'Pause os agentes que não estão em uso e feche navegador e apps pesados antes de ligar a VM.') -f `
        ($FreeBytes / 1GB), ($needed / 1GB), ($StartupBytes / 1GB), ($MarginBytes / 1GB)
    }
    return [pscustomobject]@{ CanStart = $ok; NeededBytes = $needed; FreeBytes = $FreeBytes; Reason = $reason }
}

function Get-BigZLabVm {
    <#
        Retorna a VM só se ela for do laboratório BigZ: marcador nas Notes e configuração
        dentro de <LabRoot>\vms. Caso contrário, falha (protege outras VMs do usuário).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$LabRoot = $script:DefaultLabRoot
    )
    $vm = Get-VM -Name $Name -ErrorAction SilentlyContinue
    if (-not $vm) { throw "VM '$Name' não encontrada." }
    $vmRoot = Join-Path $LabRoot 'vms'
    if ([string]$vm.Notes -notmatch [regex]::Escape($script:LabMarker)) {
        throw "A VM '$Name' não tem o marcador '$($script:LabMarker)' nas Notes: não foi criada pelo laboratório BigZ. Nada foi alterado."
    }
    if (-not (Test-BigZLabPathUnderRoot -Path $vm.Path -Root $vmRoot)) {
        throw "A VM '$Name' está fora de '$vmRoot' ($($vm.Path)). Nada foi alterado."
    }
    return $vm
}

function Assert-BigZLabSingleVm {
    <# Política de RAM: uma VM ligada por vez (qualquer VM do host, não só as do BigZ). #>
    [CmdletBinding()]
    param([string]$ExceptName)
    $running = @(Get-VM | Where-Object { [string]$_.State -ne 'Off' -and $_.Name -ne $ExceptName })
    if ($running.Count -gt 0) {
        throw ("Política do laboratório: uma VM por vez. Desligue antes: {0}" -f (($running | ForEach-Object { "$($_.Name) [$($_.State)]" }) -join ', '))
    }
}

function Wait-BigZLabHeartbeat {
    <# Espera os serviços de integração responderem (o Windows convidado terminou de iniciar). #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [int]$TimeoutSec = 300
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $vm = Get-VM -Name $Name
        if ([string]$vm.Heartbeat -like 'Ok*') { return $true }
        Start-Sleep -Seconds 5
    }
    return $false
}

Export-ModuleMember -Function @(
    'Get-BigZLabDefault', 'Test-BigZLabElevation', 'Assert-BigZLabElevation', 'Assert-BigZLabHyperV',
    'Test-BigZLabPathUnderRoot', 'Get-BigZLabHostMemory', 'Test-BigZLabStartCapacity',
    'Get-BigZLabVm', 'Assert-BigZLabSingleVm', 'Wait-BigZLabHeartbeat'
)
