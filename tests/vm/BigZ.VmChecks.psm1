#Requires -Version 5.1
<#
.SYNOPSIS
    Coletores SOMENTE LEITURA do estado de uma VM de teste do BigZ OS.

.DESCRIPTION
    Usado pelos testes Pester P0 (P0.VmState.Tests.ps1) e pelo snapshot JSON do
    Invoke-BigZVmChecks.ps1. Nenhuma função aqui altera o sistema.
    Exceção documentada: Invoke-BigZWingetTestInstall (tag Mutating), que instala
    um pacote e só roda quando pedido explicitamente.

    Política de referência: docs/decisoes/ADR-005-politica-de-risco-de-tweaks.md
#>

Set-StrictMode -Version 2.0

# Nomes de domínio do Windows Update que nunca devem estar bloqueados no arquivo hosts.
$script:UpdateDomains = @(
    'windowsupdate.com',
    'update.microsoft.com',
    'delivery.mp.microsoft.com'
)

function Test-BigZIsAdmin {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-BigZRegistryValue {
    <# Retorna o valor ou $null se a chave/valor não existir. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name
    )
    try {
        $item = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop
        return $item.$Name
    }
    catch {
        return $null
    }
}

function Get-BigZServiceStart {
    <#
        Lê o tipo de início do serviço direto do registro (mais confiável que Get-Service
        para detectar tweaks): 0 boot, 1 system, 2 automático, 3 manual, 4 DESATIVADO.
        Retorna $null se o serviço não existir.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name)
    $key = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name"
    if (-not (Test-Path -LiteralPath $key)) { return $null }
    $start = Get-BigZRegistryValue -Path $key -Name 'Start'
    if ($null -eq $start) { return $null }
    return [int]$start
}

function Invoke-BigZNative {
    <# Executa um programa externo com tempo limite e captura saída e código de saída. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$ArgumentList,
        [int]$TimeoutSec = 120
    )
    $outFile = [IO.Path]::GetTempFileName()
    $errFile = [IO.Path]::GetTempFileName()
    try {
        $proc = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -NoNewWindow -PassThru `
            -RedirectStandardOutput $outFile -RedirectStandardError $errFile -ErrorAction Stop
        $null = $proc.Handle   # garante que ExitCode fique disponível após o término
        if (-not $proc.WaitForExit($TimeoutSec * 1000)) {
            try { $proc.Kill() } catch { Write-Verbose "Falha ao encerrar $FilePath após timeout: $_" }
            return [pscustomobject]@{ ExitCode = $null; TimedOut = $true; NotFound = $false; Output = ''; Error = 'timeout' }
        }
        $proc.WaitForExit()
        return [pscustomobject]@{
            ExitCode = $proc.ExitCode
            TimedOut = $false
            NotFound = $false
            Output   = [string](Get-Content -LiteralPath $outFile -Raw -Encoding UTF8)
            Error    = [string](Get-Content -LiteralPath $errFile -Raw -Encoding UTF8)
        }
    }
    catch {
        return [pscustomobject]@{ ExitCode = $null; TimedOut = $false; NotFound = $true; Output = ''; Error = $_.Exception.Message }
    }
    finally {
        Remove-Item -LiteralPath $outFile, $errFile -Force -ErrorAction SilentlyContinue
    }
}

function Get-BigZHostsBlockedUpdateDomain {
    <# Lista entradas ativas do arquivo hosts que apontam domínios do Windows Update. #>
    [CmdletBinding()]
    param()
    $hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
    if (-not (Test-Path -LiteralPath $hostsPath)) { return @() }
    $hits = foreach ($line in (Get-Content -LiteralPath $hostsPath -ErrorAction SilentlyContinue)) {
        $clean = ($line -replace '#.*$', '').Trim()
        if (-not $clean) { continue }
        foreach ($domain in $script:UpdateDomains) {
            if ($clean -match [regex]::Escape($domain)) { $clean; break }
        }
    }
    return @($hits)
}

function Get-BigZUpdateState {
    [CmdletBinding()]
    param()
    $wuPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    $services = [ordered]@{}
    foreach ($name in 'wuauserv', 'UsoSvc', 'BITS', 'TrustedInstaller', 'WaaSMedicSvc', 'CryptSvc') {
        $services[$name] = Get-BigZServiceStart -Name $name
    }

    # As tarefas do UpdateOrchestrator só são visíveis para administradores.
    $orchestratorTasks = $null
    if (Test-BigZIsAdmin) {
        $orchestratorTasks = @(Get-ScheduledTask -TaskPath '\Microsoft\Windows\UpdateOrchestrator\' -ErrorAction SilentlyContinue)
    }

    $lastInstall = $null
    $lastSearch = $null
    try {
        $au = New-Object -ComObject Microsoft.Update.AutoUpdate
        $lastInstall = $au.Results.LastInstallationSuccessDate
        $lastSearch = $au.Results.LastSearchSuccessDate
    }
    catch {
        Write-Verbose "Microsoft.Update.AutoUpdate indisponível: $_"
    }

    return [pscustomobject]@{
        ServiceStart                        = [pscustomobject]$services
        NoAutoUpdate                        = Get-BigZRegistryValue -Path "$wuPolicy\AU" -Name 'NoAutoUpdate'
        DisableWindowsUpdateAccess          = Get-BigZRegistryValue -Path $wuPolicy -Name 'DisableWindowsUpdateAccess'
        SetDisableUXWUAccess                = Get-BigZRegistryValue -Path $wuPolicy -Name 'SetDisableUXWUAccess'
        DoNotConnectToWUInternetLocations   = Get-BigZRegistryValue -Path $wuPolicy -Name 'DoNotConnectToWindowsUpdateInternetLocations'
        WUServer                            = Get-BigZRegistryValue -Path $wuPolicy -Name 'WUServer'
        HostsBlockedEntries                 = @(Get-BigZHostsBlockedUpdateDomain)
        OrchestratorTaskCount               = if ($null -ne $orchestratorTasks) { $orchestratorTasks.Count } else { $null }
        OrchestratorTasksNotDisabled        = if ($null -ne $orchestratorTasks) { @($orchestratorTasks | Where-Object { [string]$_.State -ne 'Disabled' }).Count } else { $null }
        LastInstallationSuccessDate         = $lastInstall
        LastSearchSuccessDate               = $lastSearch
    }
}

function Invoke-BigZUpdateOnlineSearch {
    <#
        Faz uma busca real de updates pelo agente do Windows Update (pode levar minutos).
        Não instala nada. ResultCode 2 = sucesso, 3 = sucesso com erros.
    #>
    [CmdletBinding()]
    param()
    try {
        $session = New-Object -ComObject Microsoft.Update.Session
        $searcher = $session.CreateUpdateSearcher()
        $result = $searcher.Search("IsInstalled=0 and IsHidden=0")
        return [pscustomobject]@{ ResultCode = [int]$result.ResultCode; PendingCount = [int]$result.Updates.Count; Error = $null }
    }
    catch {
        return [pscustomobject]@{ ResultCode = $null; PendingCount = $null; Error = $_.Exception.Message }
    }
}

function Get-BigZThirdPartyAntivirusProduct {
    <# Antivírus registrados no Security Center que não são o Microsoft Defender. #>
    [CmdletBinding()]
    param()
    try {
        $products = Get-CimInstance -Namespace 'root/SecurityCenter2' -ClassName 'AntiVirusProduct' -ErrorAction Stop
        return @($products | Where-Object { $_.displayName -notmatch 'Defender' } | ForEach-Object { $_.displayName })
    }
    catch {
        return @()
    }
}

function Get-BigZDefenderState {
    [CmdletBinding()]
    param()
    $mp = $null
    $mpError = $null
    try { $mp = Get-MpComputerStatus -ErrorAction Stop } catch { $mpError = $_.Exception.Message }

    $defPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
    $services = [ordered]@{}
    foreach ($name in 'WinDefend', 'wscsvc', 'SecurityHealthService') {
        $services[$name] = Get-BigZServiceStart -Name $name
    }

    $secHealthUi = $null
    if (Test-BigZIsAdmin) {
        $secHealthUi = [bool](Get-AppxPackage -AllUsers -Name 'Microsoft.SecHealthUI' -ErrorAction SilentlyContinue)
    }

    $firewall = @(Get-NetFirewallProfile -ErrorAction SilentlyContinue | ForEach-Object {
            [pscustomobject]@{ Name = $_.Name; Enabled = [string]$_.Enabled }
        })

    $prop = {
        param($name)
        if ($null -eq $mp) { return $null }
        if ($mp.PSObject.Properties.Name -contains $name) { return $mp.$name }
        return $null
    }

    return [pscustomobject]@{
        MpStatusError               = $mpError
        AMServiceEnabled            = & $prop 'AMServiceEnabled'
        AntivirusEnabled            = & $prop 'AntivirusEnabled'
        RealTimeProtectionEnabled   = & $prop 'RealTimeProtectionEnabled'
        IsTamperProtected           = & $prop 'IsTamperProtected'
        AMRunningMode               = & $prop 'AMRunningMode'
        AntivirusSignatureAge       = & $prop 'AntivirusSignatureAge'
        PolicyDisableAntiSpyware    = Get-BigZRegistryValue -Path $defPolicy -Name 'DisableAntiSpyware'
        PolicyDisableAntiVirus      = Get-BigZRegistryValue -Path $defPolicy -Name 'DisableAntiVirus'
        PolicyDisableRealtime       = Get-BigZRegistryValue -Path "$defPolicy\Real-Time Protection" -Name 'DisableRealtimeMonitoring'
        PolicyDisableBehavior       = Get-BigZRegistryValue -Path "$defPolicy\Real-Time Protection" -Name 'DisableBehaviorMonitoring'
        ServiceStart                = [pscustomobject]$services
        SecHealthUiInstalled        = $secHealthUi
        SmartScreenPolicy           = Get-BigZRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableSmartScreen'
        SmartScreenExplorer         = Get-BigZRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'SmartScreenEnabled'
        ThirdPartyAntivirus         = @(Get-BigZThirdPartyAntivirusProduct)
        FirewallProfiles            = $firewall
    }
}

function Get-BigZUacState {
    [CmdletBinding()]
    param()
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    return [pscustomobject]@{
        EnableLUA                  = Get-BigZRegistryValue -Path $key -Name 'EnableLUA'
        ConsentPromptBehaviorAdmin = Get-BigZRegistryValue -Path $key -Name 'ConsentPromptBehaviorAdmin'
        PromptOnSecureDesktop      = Get-BigZRegistryValue -Path $key -Name 'PromptOnSecureDesktop'
    }
}

function Get-BigZAppxPresence {
    <# Requer administrador (usa -AllUsers). Retorna nome -> $true/$false. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$Name)
    $result = [ordered]@{}
    foreach ($n in $Name) {
        $result[$n] = [bool](Get-AppxPackage -AllUsers -Name $n -ErrorAction SilentlyContinue)
    }
    return [pscustomobject]$result
}

function Get-BigZWebView2Version {
    <#
        Versão do WebView2 Runtime (Evergreen) registrada pelo EdgeUpdate.
        GUID do cliente do Runtime conforme a documentação do WebView2 (distribuição).
    #>
    [CmdletBinding()]
    param()
    $guid = '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
    foreach ($path in @(
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\$guid",
            "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\$guid",
            "HKCU:\Software\Microsoft\EdgeUpdate\Clients\$guid")) {
        $pv = Get-BigZRegistryValue -Path $path -Name 'pv'
        if ($pv -and $pv -ne '0.0.0.0') { return [string]$pv }
    }
    return $null
}

function Get-BigZStoreState {
    [CmdletBinding()]
    param()
    $storePolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore'
    $appx = $null
    if (Test-BigZIsAdmin) {
        $appx = Get-BigZAppxPresence -Name @(
            'Microsoft.WindowsStore',
            'Microsoft.DesktopAppInstaller',
            'Microsoft.StorePurchaseApp',
            'Microsoft.VCLibs.140.00*',
            'Microsoft.UI.Xaml.*',
            'Microsoft.XboxGamingOverlay',
            'Microsoft.XboxIdentityProvider'
        )
    }
    return [pscustomobject]@{
        Appx                    = $appx
        PolicyRemoveWindowsStore = Get-BigZRegistryValue -Path $storePolicy -Name 'RemoveWindowsStore'
        PolicyDisableStoreApps  = Get-BigZRegistryValue -Path $storePolicy -Name 'DisableStoreApps'
        InstallServiceStart     = Get-BigZServiceStart -Name 'InstallService'
        ClipSvcStart            = Get-BigZServiceStart -Name 'ClipSVC'
        AppXSvcStart            = Get-BigZServiceStart -Name 'AppXSvc'
        WebView2Version         = Get-BigZWebView2Version
    }
}

function Get-BigZWingetState {
    [CmdletBinding()]
    param()
    $cmd = Get-Command -Name 'winget.exe' -ErrorAction SilentlyContinue
    if (-not $cmd) {
        return [pscustomobject]@{ Path = $null; VersionExitCode = $null; Version = $null; SourcesExitCode = $null; SourcesOutput = '' }
    }
    $ver = Invoke-BigZNative -FilePath $cmd.Source -ArgumentList '--version' -TimeoutSec 60
    $src = Invoke-BigZNative -FilePath $cmd.Source -ArgumentList 'source', 'list' -TimeoutSec 120
    return [pscustomobject]@{
        Path            = $cmd.Source
        VersionExitCode = $ver.ExitCode
        Version         = ([string]$ver.Output).Trim()
        SourcesExitCode = $src.ExitCode
        SourcesOutput   = [string]$src.Output
    }
}

function Invoke-BigZWingetTestInstall {
    <#
        MUTANTE: instala um pacote de teste via winget e confirma com "winget list".
        Só usar em VM descartável (tag Mutating).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$PackageId)
    $cmd = Get-Command -Name 'winget.exe' -ErrorAction SilentlyContinue
    if (-not $cmd) { return [pscustomobject]@{ InstallExitCode = $null; ListExitCode = $null; Error = 'winget não encontrado' } }
    $install = $null
    if ($PSCmdlet.ShouldProcess($PackageId, 'winget install')) {
        $install = Invoke-BigZNative -FilePath $cmd.Source -TimeoutSec 900 -ArgumentList @(
            'install', '--id', $PackageId, '--exact', '--source', 'winget', '--silent',
            '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
    }
    $list = Invoke-BigZNative -FilePath $cmd.Source -TimeoutSec 120 -ArgumentList @(
        'list', '--id', $PackageId, '--exact', '--accept-source-agreements', '--disable-interactivity')
    return [pscustomobject]@{
        InstallExitCode = if ($install) { $install.ExitCode } else { $null }
        ListExitCode    = $list.ExitCode
        Error           = if ($install) { $install.Error } else { 'WhatIf' }
    }
}

function Get-BigZWslState {
    [CmdletBinding()]
    param()
    $features = [ordered]@{ 'Microsoft-Windows-Subsystem-Linux' = $null; 'VirtualMachinePlatform' = $null }
    if (Test-BigZIsAdmin) {
        foreach ($f in @($features.Keys)) {
            $feat = Get-WindowsOptionalFeature -Online -FeatureName $f -ErrorAction SilentlyContinue
            if ($feat) { $features[$f] = [string]$feat.State }
        }
    }
    $wslExe = Join-Path $env:SystemRoot 'System32\wsl.exe'
    $status = $null
    $version = $null
    if (Test-Path -LiteralPath $wslExe) {
        $previous = $env:WSL_UTF8
        $env:WSL_UTF8 = '1'
        try {
            $status = Invoke-BigZNative -FilePath $wslExe -ArgumentList '--status' -TimeoutSec 120
            $version = Invoke-BigZNative -FilePath $wslExe -ArgumentList '--version' -TimeoutSec 60
        }
        finally {
            $env:WSL_UTF8 = $previous
        }
    }
    return [pscustomobject]@{
        Features          = [pscustomobject]$features
        StatusExitCode    = if ($status) { $status.ExitCode } else { $null }
        VersionExitCode   = if ($version) { $version.ExitCode } else { $null }
        VersionOutput     = if ($version) { [string]$version.Output } else { '' }
    }
}

function Get-BigZBaseState {
    <# Integridade e plataforma: Secure Boot, TPM, WinRE, saúde da imagem, ativação, BitLocker. #>
    [CmdletBinding()]
    param()
    $isAdmin = Test-BigZIsAdmin

    $secureBoot = $null
    $tpmPresent = $null
    $tpmReady = $null
    $winReEnabled = $null
    $imageHealth = $null
    $bitlocker = $null

    if ($isAdmin) {
        try { $secureBoot = [bool](Confirm-SecureBootUEFI -ErrorAction Stop) } catch { $secureBoot = $false }
        try {
            $tpm = Get-Tpm -ErrorAction Stop
            $tpmPresent = [bool]$tpm.TpmPresent
            $tpmReady = [bool]$tpm.TpmReady
        }
        catch { $tpmPresent = $false; $tpmReady = $false }

        # Independente de idioma: com o WinRE habilitado, "reagentc /info" mostra o caminho \\?\GLOBALROOT\...\Recovery\WindowsRE
        $re = Invoke-BigZNative -FilePath (Join-Path $env:SystemRoot 'System32\reagentc.exe') -ArgumentList '/info' -TimeoutSec 60
        $winReEnabled = ([string]$re.Output -match '\\\\\?\\GLOBALROOT\\device\\harddisk\d+\\partition\d+\\Recovery\\WindowsRE')

        try { $imageHealth = [string](Repair-WindowsImage -Online -CheckHealth -ErrorAction Stop).ImageHealthState } catch { $imageHealth = "erro: $($_.Exception.Message)" }

        try {
            $vol = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
            $bitlocker = [pscustomobject]@{
                ProtectionStatus     = [string]$vol.ProtectionStatus
                VolumeStatus         = [string]$vol.VolumeStatus
                HasRecoveryPassword  = [bool](@($vol.KeyProtector | Where-Object { [string]$_.KeyProtectorType -eq 'RecoveryPassword' }).Count)
            }
        }
        catch { $bitlocker = [pscustomobject]@{ ProtectionStatus = 'indisponível'; VolumeStatus = $_.Exception.Message; HasRecoveryPassword = $false } }
    }

    $license = $null
    try {
        # ApplicationID do Windows no serviço de licenciamento
        $license = Get-CimInstance -ClassName SoftwareLicensingProduct -ErrorAction Stop `
            -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL" |
            Select-Object -First 1 Name, LicenseStatus
    }
    catch { Write-Verbose "SoftwareLicensingProduct indisponível: $_" }

    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    return [pscustomobject]@{
        Caption            = [string]$os.Caption
        Build              = [string]$os.BuildNumber
        UBR                = Get-BigZRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'UBR'
        DisplayVersion     = Get-BigZRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'DisplayVersion'
        SecureBoot         = $secureBoot
        TpmPresent         = $tpmPresent
        TpmReady           = $tpmReady
        WinReEnabled       = $winReEnabled
        ImageHealthState   = $imageHealth
        LicenseName        = if ($license) { [string]$license.Name } else { $null }
        LicenseStatus      = if ($license) { [int]$license.LicenseStatus } else { $null }   # 1 = licenciado
        BitLocker          = $bitlocker
    }
}

function Get-BigZVmState {
    <# Snapshot completo (somente leitura) para gravar em JSON e comparar antes/depois. #>
    [CmdletBinding()]
    param()
    return [pscustomobject]@{
        CollectedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        ComputerName   = $env:COMPUTERNAME
        IsAdmin        = Test-BigZIsAdmin
        Base           = Get-BigZBaseState
        Update         = Get-BigZUpdateState
        Defender       = Get-BigZDefenderState
        Uac            = Get-BigZUacState
        Store          = Get-BigZStoreState
        Winget         = Get-BigZWingetState
        Wsl            = Get-BigZWslState
    }
}

Export-ModuleMember -Function @(
    'Test-BigZIsAdmin', 'Get-BigZRegistryValue', 'Get-BigZServiceStart', 'Invoke-BigZNative',
    'Get-BigZHostsBlockedUpdateDomain', 'Get-BigZUpdateState', 'Invoke-BigZUpdateOnlineSearch',
    'Get-BigZThirdPartyAntivirusProduct', 'Get-BigZDefenderState', 'Get-BigZUacState', 'Get-BigZAppxPresence',
    'Get-BigZWebView2Version', 'Get-BigZStoreState', 'Get-BigZWingetState', 'Invoke-BigZWingetTestInstall',
    'Get-BigZWslState', 'Get-BigZBaseState', 'Get-BigZVmState'
)
