#Requires -Version 5.1
<#
.SYNOPSIS
    Roda os testes P0 dentro da VM de teste e salva os resultados (NUnit XML + snapshot JSON).

.DESCRIPTION
    Use SOMENTE dentro de uma VM de laboratório, como administrador, logado com o usuário
    de teste (o winget é registrado por usuário). Os testes são somente leitura, exceto
    com -IncludeMutating (instala um pacote via winget).

    Requer Pester 5.5 ou superior. O Windows vem com o Pester 3.4, que NÃO serve.
    Use -InstallPester para instalar do PowerShell Gallery (escopo CurrentUser, só na VM).

.EXAMPLE
    # Na VM de controle (Windows oficial, sem BigZ) — a linha de base deve passar inteira
    .\Invoke-BigZVmChecks.ps1 -Edition balanced -Label controle

.EXAMPLE
    # Edição DEV, depois de aplicar o perfil e rodar o Windows Update
    .\Invoke-BigZVmChecks.ps1 -Edition dev -Label dev-pos-perfil -IncludeMutating
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('dev', 'balanced', 'full-performance')]
    [string]$Edition,

    [ValidateSet('DefenderPassiveWithThirdPartyAV', 'SmartScreenOff')]
    [string[]]$AllowOptIn = @(),

    [ValidatePattern('^[A-Za-z0-9._-]{1,40}$')]
    [string]$Label = 'run',

    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'results'),

    [switch]$SkipOnlineSearch,
    [switch]$SkipActivation,
    [switch]$IncludeMutating,
    [switch]$AllowWsus,
    [switch]$InstallPester,

    [int]$MaxSignatureAgeDays = 7,
    [int]$MaxUpdateAgeDays = 35,
    [string]$WingetTestPackageId = 'Microsoft.PowerShell'
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'BigZ.VmChecks.psm1') -Force

if (-not (Test-BigZIsAdmin)) {
    throw 'Rode este script em um PowerShell aberto como administrador, dentro da VM de teste.'
}

# ADR-005: opt-ins 🟡 só valem na full-performance (e, na v0, o catálogo não oferece nenhum).
if ($AllowOptIn.Count -gt 0) {
    if ($Edition -ne 'full-performance') {
        throw "Opt-ins ($($AllowOptIn -join ', ')) só são aceitos na edição full-performance (ADR-005)."
    }
    Write-Warning "Opt-ins aceitos nesta execução: $($AllowOptIn -join ', '). Na v0 nenhum item do catálogo deveria usá-los."
}

$pester = Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -ge [version]'5.5.0' } |
    Sort-Object Version -Descending | Select-Object -First 1
if (-not $pester) {
    if ($InstallPester) {
        Write-Information 'Instalando Pester 5 (CurrentUser) a partir do PowerShell Gallery...' -InformationAction Continue
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
        }
        # -SkipPublisherCheck: o Pester 3.4 embutido no Windows tem outro certificado de editor
        Install-Module -Name Pester -MinimumVersion 5.5.0 -Scope CurrentUser -Force -SkipPublisherCheck
        $pester = Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -ge [version]'5.5.0' } |
            Sort-Object Version -Descending | Select-Object -First 1
    }
    if (-not $pester) {
        throw 'Pester 5.5+ não encontrado. Rode de novo com -InstallPester (na VM) ou instale manualmente.'
    }
}
Remove-Module Pester -ErrorAction SilentlyContinue
Import-Module $pester.Path -Force

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$runDir = Join-Path $OutputDirectory "$stamp-$Edition-$Label"
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

Write-Information "Coletando snapshot do estado em $runDir ..." -InformationAction Continue
Get-BigZVmState | ConvertTo-Json -Depth 6 | Out-File -FilePath (Join-Path $runDir 'state.json') -Encoding utf8

$data = @{
    Edition             = $Edition
    AllowOptIn          = $AllowOptIn
    MaxSignatureAgeDays = $MaxSignatureAgeDays
    MaxUpdateAgeDays    = $MaxUpdateAgeDays
    AllowWsus           = [bool]$AllowWsus
    WingetTestPackageId = $WingetTestPackageId
}
$container = New-PesterContainer -Path (Join-Path $PSScriptRoot 'P0.VmState.Tests.ps1') -Data $data

$exclude = @()
if ($SkipOnlineSearch) { $exclude += 'Online' }
if ($SkipActivation) { $exclude += 'Activation' }
if (-not $IncludeMutating) { $exclude += 'Mutating' }

$config = New-PesterConfiguration
$config.Run.Container = $container
$config.Run.PassThru = $true
$config.Filter.ExcludeTag = $exclude
$config.Output.Verbosity = 'Detailed'
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath = Join-Path $runDir 'p0-results.xml'

$result = Invoke-Pester -Configuration $config

$summary = [pscustomobject]@{
    Edition      = $Edition
    Label        = $Label
    AllowOptIn   = $AllowOptIn
    ExcludedTags = $exclude
    Result       = [string]$result.Result
    Passed       = $result.PassedCount
    Failed       = $result.FailedCount
    Skipped      = $result.SkippedCount
    NotRun       = $result.NotRunCount
    FinishedUtc  = (Get-Date).ToUniversalTime().ToString('o')
}
$summary | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $runDir 'summary.json') -Encoding utf8

Write-Information '' -InformationAction Continue
Write-Information -InformationAction Continue -MessageData ("P0 [{0}/{1}]: {2} — {3} ok, {4} falhas, {5} pulados. Resultados em {6}" -f `
        $Edition, $Label, $summary.Result, $summary.Passed, $summary.Failed, $summary.Skipped, $runDir)

exit $result.FailedCount
