#Requires -Version 5.1
<#
.SYNOPSIS
    Copia os testes P0 (tests\vm) para dentro da VM via PowerShell Direct, roda e traz os resultados.

.DESCRIPTION
    Roda no HOST, em PowerShell como administrador. Não se autoeleva. A VM precisa estar
    ligada com o Windows já instalado. A credencial é a da conta de LABORATÓRIO da VM; ela é
    pedida no prompt do Windows e não fica gravada.

    O winget é registrado por usuário e pode não funcionar numa sessão PowerShell Direct
    (não interativa). Se o bloco Winget falhar só aqui, rode de novo com -SkipWinget e
    rode o bloco Winget num console interativo da VM (tests\vm\README.md).

.EXAMPLE
    .\Invoke-BigZVmP0.ps1 -Name BigZ-REF -Edition balanced -Label controle -InstallPester
#>
[CmdletBinding()]
param(
    [ValidatePattern('^[A-Za-z0-9-]{1,40}$')]
    [string]$Name = 'BigZ-REF',

    [Parameter(Mandatory)]
    [ValidateSet('dev', 'balanced', 'full-performance')]
    [string]$Edition,

    [ValidatePattern('^[A-Za-z0-9._-]{1,40}$')]
    [string]$Label = 'run',

    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty,

    [string]$LabRoot = 'C:\DEV\BigZ-Lab',

    [string]$GuestRoot = 'C:\BigZ',

    [switch]$InstallPester,
    [switch]$SkipOnlineSearch,
    [switch]$SkipActivation,
    [switch]$SkipWinget,
    [switch]$IncludeMutating,

    [ValidateRange(30, 1800)]
    [int]$HeartbeatTimeoutSec = 300
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'BigZ.HyperVLab.psm1') -Force
Assert-BigZLabElevation
Assert-BigZLabHyperV

$vm = Get-BigZLabVm -Name $Name -LabRoot $LabRoot
if ([string]$vm.State -ne 'Running') {
    throw "A VM '$Name' está '$($vm.State)'. Ligue-a com Start-BigZTestVm.ps1 e espere o login do Windows."
}
if (-not (Wait-BigZLabHeartbeat -Name $Name -TimeoutSec $HeartbeatTimeoutSec)) {
    throw "A VM '$Name' não respondeu aos serviços de integração em $HeartbeatTimeoutSec s (Windows ainda iniciando?)."
}

if ($Credential -eq [System.Management.Automation.PSCredential]::Empty) {
    $Credential = Get-Credential -Message "Conta de LABORATÓRIO da VM '$Name' (administrador do convidado)"
}

$testsSource = Join-Path (Split-Path -Parent $PSScriptRoot) 'vm'
$guestTests = Join-Path $GuestRoot 'tests\vm'
$hostResults = Join-Path $LabRoot 'results'
New-Item -ItemType Directory -Path $hostResults -Force | Out-Null

$session = New-PSSession -VMName $Name -Credential $Credential
try {
    # 1) Copiar só os arquivos dos testes (sem resultados antigos)
    Invoke-Command -Session $session -ScriptBlock {
        New-Item -ItemType Directory -Path $using:guestTests -Force | Out-Null
    }
    Get-ChildItem -LiteralPath $testsSource -File | Where-Object { $_.Extension -in '.ps1', '.psm1', '.md' } | ForEach-Object {
        Copy-Item -ToSession $session -LiteralPath $_.FullName -Destination $guestTests -Force
    }

    # 2) Rodar o P0 dentro da VM (ExecutionPolicy só no processo da sessão)
    $runArgs = @{ Edition = $Edition; Label = $Label }
    if ($InstallPester) { $runArgs['InstallPester'] = $true }
    if ($SkipOnlineSearch) { $runArgs['SkipOnlineSearch'] = $true }
    if ($SkipActivation) { $runArgs['SkipActivation'] = $true }
    if ($SkipWinget) { $runArgs['SkipWinget'] = $true }
    if ($IncludeMutating) { $runArgs['IncludeMutating'] = $true }
    $remote = Invoke-Command -Session $session -ScriptBlock {
        $dir = $using:guestTests
        $runnerArgs = $using:runArgs
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
        Set-Location -LiteralPath $dir
        & (Join-Path $dir 'Invoke-BigZVmChecks.ps1') @runnerArgs | Out-Host
        $code = $LASTEXITCODE
        $latest = Get-ChildItem -LiteralPath (Join-Path $dir 'results') -Directory -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        [pscustomobject]@{ ExitCode = $code; RunDir = if ($latest) { $latest.FullName } else { $null } }
    }

    # 3) Trazer os resultados para o host
    if ($remote.RunDir) {
        Copy-Item -FromSession $session -LiteralPath $remote.RunDir -Destination $hostResults -Recurse -Force
        $localRun = Join-Path $hostResults (Split-Path -Leaf $remote.RunDir)
        Write-Information "Resultados copiados para $localRun" -InformationAction Continue
    }
    else {
        Write-Warning 'Nenhuma pasta de resultados encontrada na VM.'
    }
}
finally {
    Remove-PSSession -Session $session -ErrorAction SilentlyContinue
}

Write-Information ("P0 na VM '{0}' ({1}/{2}): {3} falha(s)." -f $Name, $Edition, $Label, $remote.ExitCode) -InformationAction Continue
exit ([int]$remote.ExitCode)
