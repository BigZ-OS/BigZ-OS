# Roteiro — VM Hyper-V de referência (QA v0)

> Dona: Beatrix · Data: 2026-11-21 · Status: **roteiro; nada foi executado**.
> ⛔ = passo que **precisa da aprovação do usuário** (via Auron) antes de executar neste PC.

Objetivo: uma VM **Geração 2, com Secure Boot, vTPM e Windows 11 Enterprise Evaluation (90 dias)** que sirva de **controle** (Windows oficial) e de base para testar as edições do BigZ com os testes P0 de [`tests/vm/`](../../tests/vm/README.md).

## 0. Estado deste PC (lido em 2026-11-21, somente leitura)

| Item | Valor | Impacto |
|---|---|---|
| Sistema | Windows 11 Pro, build 26300 | Pro tem Hyper-V (o Home não tem) |
| CPU | AMD Ryzen 5 7520U, 4 núcleos / 8 threads | Ok para 1 VM com 2–4 vCPUs |
| **RAM** | **7,3 GB** | ⚠️ **Gargalo.** O Windows 11 exige 4 GB. Só cabe **1 VM com 4 GB**, com o host apertado. A DEV com WSL aninhado na VM vai ficar lenta. **Recomendação:** subir a RAM para 16 GB ou usar uma máquina de testes dedicada para a matriz completa |
| Disco livre (C:) | ~332 GB | Ok (64–80 GB por VM + checkpoints) |
| Virtualização no firmware | Habilitada | Ok |
| Hypervisor em execução | Sim (`HypervisorPresent = True`) | Algum recurso que usa o hypervisor já está ligado (VBS, VMP/WSL ou Hyper-V). **Não deu para saber se o recurso Hyper-V já está ativo** sem admin (não verificado) |

Requisitos mínimos do Windows 11: 4 GB de RAM, 64 GB de disco, TPM 2.0, UEFI com Secure Boot ([Microsoft](https://www.microsoft.com/en-us/windows/windows-11-specifications)).

## 1. Preparar o host

1. **Conferir se o Hyper-V já está ativo** (PowerShell como admin, só leitura):
   ```powershell
   Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All | Select-Object FeatureName, State
   ```
2. ⛔ **Ativar o Hyper-V** (se `State` não for `Enabled`). Exige reinício. Pode afetar o desempenho de VirtualBox/VMware no mesmo PC; o efeito em anti-cheats não foi verificado.
   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   ```
   Fonte: [Install Hyper-V (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/install-hyper-v)
3. Criar as pastas do laboratório **fora do repositório**. ISOs e discos virtuais nunca entram no Git, nas releases nem no backup do Drive (ADR-001):
   ```powershell
   New-Item -ItemType Directory -Force C:\BigZ-Lab\ISO, C:\BigZ-Lab\VM, C:\BigZ-Lab\Results | Out-Null
   ```

## 2. Obter a ISO de avaliação

1. ⛔ Baixar o **Windows 11 Enterprise Evaluation (ISO, x64, pt-BR ou en-US)** no [Microsoft Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-enterprise). O site pede um cadastro com dados pessoais: o **usuário** preenche, nenhum agente.
2. Registrar o hash da ISO (identidade do teste):
   ```powershell
   Get-FileHash C:\BigZ-Lab\ISO\<arquivo>.iso -Algorithm SHA256 | Tee-Object C:\BigZ-Lab\ISO\SHA256.txt
   ```
   Não confirmei se o Evaluation Center publica hashes de referência para a ISO (não verificado). Se publicar, compare.
3. Notas de licença:
   - A avaliação vale **90 dias** e, segundo a página, a instalação não pode ser desfeita ([Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-enterprise)). Plano: reinstalar a VM a cada ciclo. Se ela pode ou não ser convertida em versão paga não foi verificado.
   - A licença do Windows exige **uma licença por instância**, física ou virtual (licença OEM, §2.d.iv). Cada VM de avaliação é uma instância.
   - A avaliação é **Enterprise**, e os usuários finais terão **Home/Pro**. Antes do v1, validar Home/Pro com licença real ([02-seguranca-legal-qa.md](../02-seguranca-legal-qa.md), seção 4.1).

## 3. ⛔ Criar a VM de referência

Valores para **este PC (7,3 GB)**. Com 16 GB, use `-MemoryStartupBytes 8GB` e `-Count 4`.

```powershell
# PowerShell como administrador no host
$vm  = 'BigZ-REF-25H2'
$iso = 'C:\BigZ-Lab\ISO\<arquivo>.iso'

New-VM -Name $vm -Generation 2 -MemoryStartupBytes 4GB `
       -NewVHDPath "C:\BigZ-Lab\VM\$vm\$vm.vhdx" -NewVHDSizeBytes 80GB `
       -SwitchName 'Default Switch' -Path 'C:\BigZ-Lab\VM'

Set-VMMemory    -VMName $vm -DynamicMemoryEnabled $false      # memória fixa: mais previsível e indicada p/ virtualização aninhada
Set-VMProcessor -VMName $vm -Count 2
Set-VM          -VMName $vm -AutomaticCheckpointsEnabled $false -CheckpointType Standard

# Secure Boot com o modelo "Microsoft Windows" + vTPM
Set-VMFirmware      -VMName $vm -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows
Set-VMKeyProtector  -VMName $vm -NewLocalKeyProtector
Enable-VMTPM        -VMName $vm

# Mídia de instalação e ordem de boot
Add-VMDvdDrive  -VMName $vm -Path $iso
Set-VMFirmware  -VMName $vm -FirstBootDevice (Get-VMDvdDrive -VMName $vm)

# Copiar arquivos host -> VM sem pasta compartilhada
Enable-VMIntegrationService -VMName $vm -Name 'Guest Service Interface'

# Só para a VM da edição DEV (WSL 2 dentro da VM): virtualização aninhada
# Set-VMProcessor -VMName $vm -ExposeVirtualizationExtensions $true
```

Notas:
- A Geração 2 é a única com UEFI, Secure Boot e vTPM ([Gen 1 × Gen 2](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/plan/should-i-create-a-generation-1-or-2-virtual-machine-in-hyper-v)). Depois de ligar a VM com o TPM ativo, o modelo de Secure Boot fica travado; defina-o **antes** do primeiro boot ([guia Tech Community](https://techcommunity.microsoft.com/blog/itopstalkblog/how-to-run-a-windows-11-vm-on-hyper-v/3713948)).
- Virtualização aninhada (WSL dentro da VM): [Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/enable-nested-virtualization). Com 4 GB de RAM o desempenho vai ser baixo (não medido).
- `Default Switch` dá internet por NAT, que o Windows Update e o winget precisam. Não conecte a VM à rede local de outra forma.
- **Sem pasta compartilhada e sem disco físico** ligados à VM. Não use contas pessoais dentro dela.

## 4. Instalar o Windows (VM de controle)

1. `Start-VM -Name $vm; vmconnect.exe localhost $vm` → aperte uma tecla para dar boot pelo DVD.
2. Idioma e teclado (pt-BR ou en-US) → instalação personalizada no disco virtual vazio.
3. OOBE:
   - **Conta:** crie uma **conta local de laboratório** (ex.: `bigz-qa`) com senha forte só de laboratório. No Enterprise a conta local deve estar disponível pela opção de ingresso em domínio (não verificado). Se a configuração exigir conta Microsoft, use uma conta **de teste dedicada**, nunca a pessoal.
   - Desmarque os diagnósticos opcionais. **Não** use ativadores (ADR-007).
4. Depois do primeiro login, ainda na VM:
   ```powershell
   winver                                  # anotar build (ex.: 26200.xxxx)
   slmgr /xpr                              # data de expiração da avaliação
   ```
5. **Fase "Windows Update"**: *Configurações → Windows Update → Verificar* até não haver pendências (vários reinícios). Depois, num PowerShell admin:
   ```powershell
   Update-MpSignature                      # assinaturas do Defender
   ```
   Na Microsoft Store: *Biblioteca → Obter atualizações*. Isso atualiza o App Installer e, com ele, o winget.
6. Ejetar a ISO (no host): `Set-VMDvdDrive -VMName $vm -Path $null`

## 5. Checkpoint de controle e testes P0

No host:
```powershell
Stop-VM -Name $vm
Checkpoint-VM -Name $vm -SnapshotName '00-controle-limpa-atualizada'
Start-VM -Name $vm
```

Copiar os testes para a VM (PowerShell Direct, no host):
```powershell
$cred = Get-Credential bigz-qa                     # a senha de laboratório é digitada no prompt, nunca no chat
$s = New-PSSession -VMName $vm -Credential $cred
Copy-Item -ToSession $s -Path 'C:\DEV\PROJETOS_MDEV\BigZ OS\tests\vm' -Destination 'C:\BigZ\tests\' -Recurse -Force
```
Fonte: [PowerShell Direct](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/powershell-direct)

Rodar **dentro da VM**, num PowerShell **interativo** como administrador (por causa do winget, que é registrado por usuário):
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
cd C:\BigZ\tests\vm
.\Invoke-BigZVmChecks.ps1 -Edition balanced -Label controle -InstallPester -IncludeMutating
```
**Critério:** a VM de controle precisa dar **0 falhas**. Falha no controle = corrigir o teste ou o ambiente e registrar em issue (não é bug do BigZ).

Trazer os resultados (no host):
```powershell
Copy-Item -FromSession $s -Path 'C:\BigZ\tests\vm\results\*' -Destination 'C:\BigZ-Lab\Results\' -Recurse
Remove-PSSession $s
```

## 6. Ciclo de teste de uma edição

| Passo | Ação | Checkpoint |
|---|---|---|
| 1 | `Restore-VMCheckpoint -VMName $vm -Name '00-controle-limpa-atualizada' -Confirm:$false` | — |
| 2 | Aplicar a edição: toolbox sobre o Windows instalado; ou, para o builder, nova VM a partir da ISO gerada pelo `Build-BigZIso.ps1` | `01-<edição>-aplicada` |
| 3 | Fase Windows Update (seção 4.5) | `02-<edição>-pos-update` |
| 4 | `Invoke-BigZVmChecks.ps1 -Edition <edição> -Label pos-perfil` | — |
| 5 | Reverter os tweaks pela toolbox → `-Label pos-reverter` → comparar o `state.json` com o do controle | — |
| 6 | Upgrade in-place / feature update (linha 9 da matriz, quando houver build mais nova) | — |

Matriz e checklist completos (jogos, drivers, ferramentas dev): [02-seguranca-legal-qa.md](../02-seguranca-legal-qa.md), seções 4.2–4.3. Drivers de GPU, anti-cheat e benchmark exigem **máquina física**, porque a VM não tem GPU dedicada.

## 7. Manutenção e limpeza

- **Expiração:** `slmgr /xpr` na VM. Recrie a VM a partir de uma ISO nova antes de vencer ou a cada nova build-alvo.
- **Espaço:** checkpoints crescem; apague os antigos com `Remove-VMCheckpoint`.
- **Remover tudo** (⛔ apaga dados da VM):
  ```powershell
  Stop-VM -Name $vm -TurnOff; Remove-VM -Name $vm -Force
  Remove-Item -Recurse -Force "C:\BigZ-Lab\VM\$vm"
  ```

## Pendências / não verificado

- Hyper-V já ativo neste PC: não verificado (precisa de admin).
- Hash de referência da ISO de avaliação: não verificado.
- Conta local no OOBE do Enterprise: não verificado.
- Desempenho da DEV (WSL aninhado) com 4 GB: não medido.
- VirtualBox 7 como segundo hipervisor da matriz: roteiro a escrever depois de validar o Hyper-V.
