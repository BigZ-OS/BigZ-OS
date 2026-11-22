#Requires -Version 5.1
<#
.SYNOPSIS
    Testes P0 (bloqueantes) do estado de uma VM de teste do BigZ OS. Pester 5.

.DESCRIPTION
    Rodar DENTRO da VM, como administrador, de preferência via Invoke-BigZVmChecks.ps1.
    Todos os testes são somente leitura, exceto os marcados com a tag "Mutating".

    Base: docs/02-seguranca-legal-qa.md (seção 4.3) e ADR-005 (base comum preservada).
    Primeiro rode na VM de CONTROLE (Windows oficial, sem BigZ): o que falhar lá é
    problema do teste ou do ambiente, não do BigZ.

    Tags: P0, Base, Activation, Update, Online, Defender, UAC, Store, Gaming, Winget, Mutating, WSL
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Pester 5: variáveis do BeforeAll são lidas nos blocos It')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Parâmetros do container Pester usados nos blocos It')]
param(
    [ValidateSet('dev', 'balanced', 'full-performance')]
    [string]$Edition = 'balanced',

    # Opt-ins 🟡 aceitos nesta execução (ADR-005). Na v0 nenhum é oferecido pelo catálogo.
    [ValidateSet('DefenderPassiveWithThirdPartyAV', 'SmartScreenOff')]
    [string[]]$AllowOptIn = @(),

    [int]$MaxSignatureAgeDays = 7,
    [int]$MaxUpdateAgeDays = 35,
    [bool]$AllowWsus = $false,
    [string]$WingetTestPackageId = 'Microsoft.PowerShell'
)

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'BigZ.VmChecks.psm1') -Force
    $IsAdmin = Test-BigZIsAdmin

    function Assert-BigZAdmin {
        if (-not $IsAdmin) { Set-ItResult -Skipped -Because 'requer PowerShell como administrador' }
        return $IsAdmin
    }
}

Describe 'Base comum: integridade e plataforma' -Tag 'P0', 'Base' {
    BeforeAll { $base = Get-BigZBaseState }

    It 'Secure Boot está ativo' {
        if (Assert-BigZAdmin) { $base.SecureBoot | Should -BeTrue }
    }
    It 'TPM presente e pronto' {
        if (Assert-BigZAdmin) {
            $base.TpmPresent | Should -BeTrue
            $base.TpmReady | Should -BeTrue
        }
    }
    It 'WinRE está habilitado (reagentc /info)' {
        if (Assert-BigZAdmin) { $base.WinReEnabled | Should -BeTrue }
    }
    It 'Imagem do sistema saudável (Repair-WindowsImage -CheckHealth)' {
        if (Assert-BigZAdmin) { $base.ImageHealthState | Should -Be 'Healthy' }
    }
    It 'Se o BitLocker protege o disco do sistema, existe senha de recuperação' {
        if (Assert-BigZAdmin) {
            if ($base.BitLocker.ProtectionStatus -eq 'On') {
                $base.BitLocker.HasRecoveryPassword | Should -BeTrue
            }
            else {
                Set-ItResult -Skipped -Because "BitLocker não está protegendo o disco ($($base.BitLocker.ProtectionStatus))"
            }
        }
    }
    It 'Windows está ativado (LicenseStatus = 1)' -Tag 'Activation' {
        $base.LicenseStatus | Should -Be 1 -Because 'o BigZ não pode alterar a ativação (ADR-007)'
    }
}

Describe 'Windows Update preservado' -Tag 'P0', 'Update' {
    BeforeAll { $wu = Get-BigZUpdateState }

    It 'Serviço <_> existe e não está desativado' -ForEach @('wuauserv', 'UsoSvc', 'BITS', 'TrustedInstaller', 'WaaSMedicSvc', 'CryptSvc') {
        $start = $wu.ServiceStart.$_
        $start | Should -Not -BeNullOrEmpty -Because "o serviço $_ não pode ser removido"
        $start | Should -Not -Be 4 -Because "o serviço $_ não pode ser desativado (Start=4)"
    }
    It 'Sem política NoAutoUpdate=1' {
        $wu.NoAutoUpdate | Should -Not -Be 1
    }
    It 'Sem política DisableWindowsUpdateAccess=1' {
        $wu.DisableWindowsUpdateAccess | Should -Not -Be 1
    }
    It 'Sem política SetDisableUXWUAccess=1' {
        $wu.SetDisableUXWUAccess | Should -Not -Be 1
    }
    It 'Sem política DoNotConnectToWindowsUpdateInternetLocations=1' {
        $wu.DoNotConnectToWUInternetLocations | Should -Not -Be 1
    }
    It 'Sem servidor WSUS configurado (a VM de laboratório usa o Windows Update público)' {
        if ($AllowWsus) { Set-ItResult -Skipped -Because 'AllowWsus = $true' }
        else { $wu.WUServer | Should -BeNullOrEmpty }
    }
    It 'Arquivo hosts não bloqueia domínios do Windows Update' {
        $wu.HostsBlockedEntries | Should -BeNullOrEmpty
    }
    It 'Tarefas do UpdateOrchestrator existem e ao menos uma não está desativada' {
        if (Assert-BigZAdmin) {
            $wu.OrchestratorTaskCount | Should -BeGreaterThan 0
            $wu.OrchestratorTasksNotDisabled | Should -BeGreaterThan 0
        }
    }
    It "Última instalação de update bem-sucedida há no máximo $MaxUpdateAgeDays dias" {
        $wu.LastInstallationSuccessDate | Should -Not -BeNullOrEmpty
        $age = ((Get-Date).ToUniversalTime() - [datetime]$wu.LastInstallationSuccessDate).TotalDays
        $age | Should -BeLessOrEqual $MaxUpdateAgeDays -Because 'rode a fase "Windows Update" do roteiro antes do P0'
    }
    It 'Busca online de updates conclui com sucesso (pode levar minutos)' -Tag 'Online' {
        $search = Invoke-BigZUpdateOnlineSearch
        $search.Error | Should -BeNullOrEmpty
        $search.ResultCode | Should -BeIn @(2, 3) -Because 'ResultCode 2 = sucesso, 3 = sucesso com erros'
    }
}

Describe 'Microsoft Defender, SmartScreen e firewall preservados' -Tag 'P0', 'Defender' {
    BeforeAll {
        $def = Get-BigZDefenderState
        $passiveAllowed = ($AllowOptIn -contains 'DefenderPassiveWithThirdPartyAV') -and ($def.ThirdPartyAntivirus.Count -gt 0)
    }

    It 'Get-MpComputerStatus responde (Defender instalado)' {
        $def.MpStatusError | Should -BeNullOrEmpty
    }
    It 'Serviço <_> existe e não está desativado' -ForEach @('WinDefend', 'wscsvc', 'SecurityHealthService') {
        $start = $def.ServiceStart.$_
        $start | Should -Not -BeNullOrEmpty
        $start | Should -Not -Be 4
    }
    It 'Defender ativo, com proteção em tempo real (ou passivo com outro AV, se opt-in)' {
        if ($passiveAllowed) {
            $def.AMRunningMode | Should -BeIn @('Normal', 'Passive Mode')
        }
        else {
            $def.AMServiceEnabled | Should -BeTrue
            $def.AntivirusEnabled | Should -BeTrue
            $def.RealTimeProtectionEnabled | Should -BeTrue
            $def.AMRunningMode | Should -Be 'Normal'
        }
    }
    It 'Tamper Protection ligado' {
        $def.IsTamperProtected | Should -BeTrue -Because 'o BigZ nunca desliga Tamper Protection (ADR-005)'
    }
    It "Assinaturas com no máximo $MaxSignatureAgeDays dias" {
        if ($passiveAllowed) { Set-ItResult -Skipped -Because 'Defender passivo com outro AV (opt-in)' }
        else { $def.AntivirusSignatureAge | Should -BeLessOrEqual $MaxSignatureAgeDays }
    }
    It 'Sem políticas que desativam o Defender' {
        $def.PolicyDisableAntiSpyware | Should -Not -Be 1
        $def.PolicyDisableAntiVirus | Should -Not -Be 1
        $def.PolicyDisableRealtime | Should -Not -Be 1
        $def.PolicyDisableBehavior | Should -Not -Be 1
    }
    It 'App Segurança do Windows (Microsoft.SecHealthUI) instalado' {
        if (Assert-BigZAdmin) { $def.SecHealthUiInstalled | Should -BeTrue }
    }
    It 'SmartScreen não está desligado (política nem Explorer)' {
        if ($AllowOptIn -contains 'SmartScreenOff') { Set-ItResult -Skipped -Because 'opt-in SmartScreenOff' }
        else {
            $def.SmartScreenPolicy | Should -Not -Be 0
            $def.SmartScreenExplorer | Should -Not -Be 'Off'
        }
    }
    It 'Firewall ligado em todos os perfis' {
        $def.FirewallProfiles.Count | Should -BeGreaterThan 0
        foreach ($p in $def.FirewallProfiles) {
            $p.Enabled | Should -Be 'True' -Because "perfil $($p.Name)"
        }
    }
}

Describe 'UAC preservado' -Tag 'P0', 'UAC' {
    BeforeAll { $uac = Get-BigZUacState }

    It 'EnableLUA = 1' {
        $uac.EnableLUA | Should -Be 1
    }
    It 'Administradores recebem pedido de elevação (ConsentPromptBehaviorAdmin ≠ 0)' {
        $uac.ConsentPromptBehaviorAdmin | Should -Not -Be 0
    }
    It 'Pedido de elevação na área de trabalho segura (PromptOnSecureDesktop = 1)' {
        $uac.PromptOnSecureDesktop | Should -Be 1
    }
}

Describe 'Microsoft Store, App Installer e runtimes preservados' -Tag 'P0', 'Store' {
    BeforeAll { $store = Get-BigZStoreState }

    It 'Pacote <_> presente' -ForEach @(
        'Microsoft.WindowsStore', 'Microsoft.DesktopAppInstaller', 'Microsoft.StorePurchaseApp',
        'Microsoft.VCLibs.140.00*', 'Microsoft.UI.Xaml.*') {
        if (Assert-BigZAdmin) { $store.Appx.$_ | Should -BeTrue }
    }
    It 'Pacote Xbox <_> presente (Game Bar / identidade)' -Tag 'Gaming' -ForEach @('Microsoft.XboxGamingOverlay', 'Microsoft.XboxIdentityProvider') {
        if (Assert-BigZAdmin) { $store.Appx.$_ | Should -BeTrue }
    }
    It 'Sem políticas que removem a Store ou bloqueiam apps da Store' {
        $store.PolicyRemoveWindowsStore | Should -Not -Be 1
        $store.PolicyDisableStoreApps | Should -Not -Be 1
    }
    It 'Serviços InstallService, ClipSVC e AppXSvc existem e não estão desativados' {
        foreach ($s in @($store.InstallServiceStart, $store.ClipSvcStart, $store.AppXSvcStart)) {
            $s | Should -Not -BeNullOrEmpty
            $s | Should -Not -Be 4
        }
    }
    It 'WebView2 Runtime instalado' {
        $store.WebView2Version | Should -Not -BeNullOrEmpty -Because 'WebView2 é componente protegido (ADR-005)'
    }
}

Describe 'winget funcional' -Tag 'P0', 'Winget' {
    BeforeAll { $wg = Get-BigZWingetState }

    It 'winget.exe disponível para o usuário atual' {
        $wg.Path | Should -Not -BeNullOrEmpty -Because 'faça um login interativo antes; o App Installer registra o winget por usuário'
    }
    It 'winget --version retorna 0 e uma versão' {
        $wg.VersionExitCode | Should -Be 0
        $wg.Version | Should -Match '^v?\d+\.\d+'
    }
    It 'Fontes padrão winget e msstore configuradas' {
        $wg.SourcesExitCode | Should -Be 0
        $wg.SourcesOutput | Should -Match 'cdn\.winget\.microsoft\.com'
        $wg.SourcesOutput | Should -Match 'msstore'
    }
    It "Instala o pacote de teste ($WingetTestPackageId) e o encontra em 'winget list'" -Tag 'Mutating' {
        $r = Invoke-BigZWingetTestInstall -PackageId $WingetTestPackageId
        $r.ListExitCode | Should -Be 0 -Because "instalação retornou $($r.InstallExitCode)"
    }
}

Describe 'WSL 2 (edição DEV)' -Tag 'P0', 'WSL' -Skip:($Edition -ne 'dev') {
    BeforeAll { $wsl = Get-BigZWslState }

    It 'Recurso opcional <_> habilitado' -ForEach @('Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform') {
        if (Assert-BigZAdmin) { $wsl.Features.$_ | Should -Be 'Enabled' }
    }
    It 'wsl --version retorna 0 (WSL instalado)' {
        $wsl.VersionExitCode | Should -Be 0
    }
    It 'wsl --status retorna 0' {
        $wsl.StatusExitCode | Should -Be 0
    }
}
