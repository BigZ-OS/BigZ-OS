# Sequência — instalar `BigZ-Balanced-TESTONLY.iso` na VM e rodar o P0

> Dona: Beatrix · 2026-11-22 · Para o Auron executar com o usuário. **2 avisos de UAC** no caminho feliz.
> ISO: `C:\DEV\BigZ-Lab\out\BigZ-Balanced-TESTONLY.iso` (job `f1ef24cc…`, Enterprise Evaluation 26300 **ko-KR**, perfil balanced, `testOnly: true`).
> Licença: Enterprise Evaluation, conforme o [ADR-010](../decisoes/ADR-010-licenca-das-vms-de-teste.md). Sem chave, sem ativador, sem rearm.

## Antes de começar (sem UAC)

1. **Memória:** são precisos **≥ 4,5 GB livres** (agora ~2,5 GB). **Pause todos os agentes, menos o Auron**, e feche o navegador. Sem isso, o `Create` recusa e explica o motivo.
2. Disco: a VM usa até 64 GB em `C:\DEV\BigZ-Lab\vms\`. Se precisar de espaço, a limpeza dos 7,68 GB de `work\` é com o Cid (`-CleanupJob`).
3. Comando para disparar cada ação (o usuário aceita o UAC):
   ```powershell
   $lab = 'C:\DEV\PROJETOS_MDEV\BigZ OS\tests\hyperv\Invoke-BigZLab.ps1'
   function Start-BigZLabAction([string]$Arguments) {
       Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$lab`" $Arguments"
   }
   ```
   Resultado de cada ação: `C:\DEV\BigZ-Lab\logs\last-status.json` e o `*.log` do mesmo horário.

## UAC 1 — criar, ligar e abrir o console

```powershell
Start-BigZLabAction '-Action Create -Name BigZ-BAL -IsoPath "C:\DEV\BigZ-Lab\out\BigZ-Balanced-TESTONLY.iso"'
```
O script confere o SHA-256 com o `.sha256` (se não conferir, para sem criar nada), cria a VM `BigZ-BAL`, **abre o console primeiro** e liga a VM.

## Manual — instalação (o usuário, no console da VM; o Setup está em coreano)

Os rótulos em coreano abaixo são os **esperados** (não verificados na tela). Guie-se pela **posição**: o botão de avançar fica sempre no **canto inferior direito**.

| # | Tela | O que fazer |
|---|---|---|
| 1 | Preta, `Press any key to boot from CD or DVD...` (em inglês) | **Clique dentro do console e aperte qualquer tecla em até ~5 s.** Se perder: no console, *Ação → Redefinir* (ou Ctrl+Alt+Del pelo ícone da barra) e tente de novo |
| 2 | Idioma / formato de hora e moeda | Deixe como está → **다음** (Avançar) |
| 3 | Teclado | Deixe como está → **다음** |
| 4 | Opção de instalação ("Instalar Windows 11" × "Reparar") | Deixe **Instalar** marcado, **marque a caixa de seleção** de que tudo no disco será apagado (o disco da VM está vazio) → **다음** |
| 5 | Se aparecer **chave de produto** | **Não digite nenhuma chave.** A Evaluation normalmente não pede (não verificado). Se pedir, pare e avise o Auron |
| 6 | **Termos de licença** | **Leia** (o testador aceita, ADR-010). Na primeira vez, tire um print e salve fora da VM → **동의** (Aceitar) |
| 7 | Onde instalar | Um único disco "0" de ~64 GB, não alocado → **다음** |
| 8 | Pronto para instalar | **설치** (Instalar) |
| 9 | Reinícios | **NÃO aperte nenhuma tecla** quando voltar o "Press any key to boot from CD or DVD": é só esperar. Se apertar, a instalação recomeça |

## Manual — OOBE (configuração inicial, também em coreano)

| # | Tela | O que fazer |
|---|---|---|
| 1 | País/região | Pode deixar o padrão → **예** (Sim) |
| 2 | Teclado / segundo teclado | Aceite o padrão → **건너뛰기** (Ignorar) no segundo teclado |
| 3 | Rede | A VM já está na `Default Switch` (internet por NAT). Aguarde a checagem de atualizações |
| 4 | Nome do dispositivo | Se pedir, digite `BIGZ-BAL` → **다음** (ou pule) |
| 5 | **Conta** | Crie uma **conta LOCAL de laboratório**: usuário `bigzqa`, senha **só de laboratório** e 3 perguntas de segurança. No Enterprise, a conta local costuma ficar em *Opções de entrada → Ingressar no domínio* (não verificado). **Nunca** use a conta Microsoft pessoal; se for obrigatória, use uma conta de teste dedicada e avise o Auron |
| 6 | ⚠️ **Digitação em coreano** | Se as letras saírem em hangul, aperte **Alt da direita** (ou a tecla 한/영) para alternar para letras latinas (atalho do IME coreano, não verificado nesta VM). Confira a senha pelo ícone de "mostrar" antes de avançar |
| 7 | Privacidade | Desligue **todas** as opções opcionais → **동의** / aceitar |
| 8 | Área de trabalho | Pronto |

## Manual — atualizar a VM (na VM, com o usuário `bigzqa`)

1. *Configurações → Windows Update → Verificar atualizações*: repita até **não haver pendências** (vários reinícios; em cada um, **não** aperte tecla no "boot from CD").
2. PowerShell **como administrador** na VM: `Update-MpSignature`
3. Microsoft Store → *Biblioteca → Obter atualizações* (atualiza o App Installer e, com ele, o winget).
4. Confira a ativação: *Configurações → Sistema → Ativação*, ou `slmgr /xpr`. A Evaluation ativa online; se ainda não estiver ativada, use `-SkipActivation` no passo seguinte e anote.
5. Deixe a VM **ligada**, na área de trabalho.

## UAC 2 — checkpoint "limpo" + P0 (um aviso só)

```powershell
Start-BigZLabAction '-Action Baseline -Name BigZ-BAL -Edition balanced -Label balanced-testonly -InstallPester -SkipWinget'
```
Faz, em sequência: desliga a VM de forma limpa → ejeta a ISO → cria o checkpoint **`limpo`** → religa (checa a memória) → copia `tests\vm` pelo PowerShell Direct → roda o P0 → traz os resultados.
- A janela elevada pede a **credencial `bigzqa`** (prompt do Windows; o usuário digita).
- Resultados: `C:\DEV\BigZ-Lab\results\<data>-balanced-balanced-testonly\` (`summary.json`, `p0-results.xml`, `state.json`) e `last-status.json` (`ExitCode` = nº de falhas).

## Manual — bloco winget (na VM, console interativo)

PowerShell **como administrador** na VM:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
C:\BigZ\tests\vm\Invoke-BigZVmChecks.ps1 -Edition balanced -Label balanced-testonly-winget -IncludeMutating
```
O resultado fica em `C:\BigZ\tests\vm\results\` dentro da VM. Para trazê-lo ao host, rode `-Action P0` de novo ou copie manualmente.

## Como ler o resultado

| Resultado | Leitura |
|---|---|
| 0 falhas | Balanced TESTONLY passa no P0 da base comum (ADR-005) **nesta build Enterprise** |
| Falhas em Update/Defender/UAC/Store/winget | **Bloqueante.** Antes de culpar o BigZ, rodar a **VM de controle** com a ISO oficial `C:\DEV\BigZ-Lab\iso\26300…CLIENTENTERPRISEEVAL…ko-kr.iso` (`-Name BigZ-REF`, mesma sequência, depois de **remover ou desligar** a `BigZ-BAL`: uma VM por vez) e comparar os `state.json` |
| Só `Activation` falhou | VM ainda não ativada: repetir após ativar; não é falha do perfil |
| Falha em Appx `Microsoft.BingNews` | Não testamos esse pacote; o perfil o remove de propósito |

Lembrete: um resultado em **Enterprise Evaluation** não comprova Home/Pro (ADR-010).

## Depois

- Voltar ao estado limpo: `-Action Reset -Name BigZ-BAL` (pede confirmação).
- Remover: `-Action Remove -Name BigZ-BAL -DeleteFiles` (pede confirmação).
- Despausar os agentes **depois de desligar a VM**.
