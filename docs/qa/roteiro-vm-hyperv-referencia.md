# Roteiro — VM Hyper-V de referência (QA, F2)

> Dona: Beatrix · Atualizado: 2026-11-21 · Status: **scripts prontos; nada executado com Hyper-V.**
> ⛔ = passo que só o **usuário** faz ou aprova (UAC, cadastro, compra de licença).
> Scripts: [`tests/hyperv/`](../../tests/hyperv/README.md) · Licença: [ADR-010](../decisoes/ADR-010-licenca-das-vms-de-teste.md)
> Sequência pronta para a primeira ISO do builder: [sequencia-iso-testonly-balanced.md](sequencia-iso-testonly-balanced.md)

## 0. Este PC e a política de RAM

| Item | Valor | Impacto |
|---|---|---|
| Sistema | Windows 11 Pro, build 26300 | Tem Hyper-V. Ativado pelo Auron, **falta reiniciar** |
| CPU | Ryzen 5 7520U, 4 núcleos / 8 threads | VM com 2 vCPU |
| **RAM** | **7,3 GB no total, ~1,5 GB livres com os agentes rodando** | ⚠️ O Hyper-V precisa ter livre a **memória de inicialização** da VM (4 GB) no momento do boot |
| Disco | ~332 GB livres em C: | VHDX dinâmico de 64 GB + checkpoints: reserve ~100 GB |

**Política (aplicada pelos scripts):**
1. **Uma VM ligada por vez.** `Start-BigZTestVm.ps1` recusa ligar se houver qualquer outra VM ligada.
2. **Só liga com ≥ 4,5 GB livres** (4 GB da VM + 0,5 GB de margem). Com ~1,5 GB livres, **não liga**: é preciso liberar ~3 GB antes.
3. VM: **4 GB de memória dinâmica, mínimo 2 GB, máximo 4 GB**. Depois do boot, o Hyper-V pode recolher até 2 GB quando o Windows convidado estiver ocioso, mas a **inicialização sempre precisa dos 4 GB** (requisito do Windows 11; não burlamos requisitos, ADR-005).
4. Edição **DEV com WSL dentro da VM** (virtualização aninhada) usa memória **fixa** de 4 GB. Ela vai ficar lenta neste PC (não medido). Prefira testá-la por último.

**Quando pausar os agentes** (o usuário pausa no OpenBot):

| Fase | O que fica ligado | Pausar |
|---|---|---|
| Escrita de scripts, revisão, docs (sem VM) | Todos os agentes | Nada |
| **Ligar a VM** (`Create`, `Start`, `Reset`) e **instalar o Windows / Windows Update** | Só o Auron (quem dispara as ações) | **Todos os outros agentes**; feche também o navegador e apps pesados. Confira com `-Action Status` (mostra a memória livre) |
| **P0 na VM** (`-Action P0`) | Auron (+ Beatrix só para ler os resultados depois) | Os demais |
| Build da ISO pelo builder (DISM, F2 do Cid) | Auron + Cid | Os demais. **Com a VM desligada**: DISM e VM juntos não cabem |
| VM desligada | Todos | Nada |

Regra prática: se `Status` mostrar **menos de 1 GB livre com a VM ligada**, pause mais um agente ou desligue a VM. Recomendação de hardware para a matriz completa: **16 GB de RAM** ou uma máquina de testes dedicada.

## 1. Mídia (ISO)

| ISO | Para quê | Situação |
|---|---|---|
| **Consumidor multi-edição** (Ferramenta de Criação de Mídia, 26H2, pt-BR, x64) em `C:\DEV\BigZ-Lab\iso\` | **Entrada do builder** (`-Plan`, inventário, build) | ✅ É a mídia dos usuários. ⚠️ **Instalar na VM exige licença Home/Pro real para a VM** (ADR-010). A licença do host não cobre a VM |
| ⛔ **Windows 11 Enterprise Evaluation** (90 dias) | **Instalação nas VMs de teste**; com o builder, só em `-TestOnly` | O **usuário** baixa pelo navegador no [Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-enterprise), porque o site pede cadastro e bloqueia download automatizado |

A versão atual na página da Microsoft é a **26H2** (informação do Auron). A build exata sai do inventário da ISO (Cid). Registre o SHA-256 de toda ISO: `New-BigZTestVm.ps1` grava o hash nas Notes da VM.

## 2. Pré-requisitos

1. ⛔ Reiniciar o PC para concluir a ativação do Hyper-V.
2. ⛔ ISO de avaliação em `C:\DEV\BigZ-Lab\iso\`, ou uma licença Home/Pro dedicada se for instalar a ISO de consumidor.
3. Pausar os agentes conforme a seção 0.

## 3. Criar a VM e instalar o Windows

Todas as ações passam por `Invoke-BigZLab.ps1`, uma janela de UAC por ação. Um agente dispara assim (o usuário aceita o UAC):

```powershell
$lab = 'C:\DEV\PROJETOS_MDEV\BigZ OS\tests\hyperv\Invoke-BigZLab.ps1'
Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$lab`" -Action Status"
```
O resultado fica em `C:\DEV\BigZ-Lab\logs\last-status.json` e na transcrição `*.log` da mesma pasta, que agentes conseguem ler. A janela elevada não é legível por agentes (UIPI).

1. `-Action Status`: confirma o Hyper-V e a memória livre.
2. `-Action Create -IsoPath "C:\DEV\BigZ-Lab\iso\<arquivo>.iso"`: cria a VM `BigZ-REF` (Gen2, Secure Boot, vTPM, 4 GB dinâmica com mínimo de 2 GB, 2 vCPU, 64 GB dinâmico em `C:\DEV\BigZ-Lab\vms\`, `Default Switch`), liga e abre o console.
3. ⛔ No console da VM (o usuário opera, porque a janela é elevada):
   - aperte uma tecla para dar boot pelo DVD → idioma → instalação personalizada no disco vazio;
   - **Conta:** conta **local de laboratório** (ex.: `bigz-qa`) com senha só de laboratório. Se o Enterprise exigir conta Microsoft, use uma conta **de teste dedicada**, nunca a pessoal (comportamento da OOBE não verificado);
   - aceite os termos de licença **lendo-os**. Na primeira vez, guarde uma cópia dos termos da avaliação (ADR-010, ponto para o advogado);
   - não use ativadores nem chaves que não sejam suas (ADR-007).
4. Na VM: rode o **Windows Update** até não haver pendências; num PowerShell admin, `Update-MpSignature`; na Store, *Biblioteca → Obter atualizações*. Anote `winver` e `slmgr /xpr` (expiração da avaliação).
5. `-Action Checkpoint`: desliga de forma limpa, ejeta a ISO e cria o checkpoint **`limpo`**.

## 4. Rodar o P0 (VM de controle)

1. `-Action Start`
2. `-Action P0 -Edition balanced -Label controle -InstallPester -SkipWinget`. A credencial da conta de laboratório é pedida na janela elevada. Os resultados ficam em `C:\DEV\BigZ-Lab\results\<data>-balanced-controle\` (`summary.json`, `p0-results.xml`, `state.json`).
3. Bloco Winget: no console da VM, num PowerShell admin interativo, `C:\BigZ\tests\vm\Invoke-BigZVmChecks.ps1 -Edition balanced -Label controle-winget` (o winget é registrado por usuário).
4. **Critério:** a VM de controle precisa dar **0 falhas**. Falha no controle é problema do teste ou do ambiente: abrir issue e corrigir antes de testar o BigZ.

## 5. Ciclo de uma edição

| Passo | Ação | Observação |
|---|---|---|
| 1 | `-Action Reset` | Volta ao `limpo` (pede confirmação) e liga |
| 2 | Aplicar a edição: toolbox sobre o Windows instalado; ou o builder (ISO gerada → `-Action Create -Name BigZ-BAL -IsoPath …`) | Uma VM por vez: desligue a outra antes |
| 3 | Windows Update na VM | — |
| 4 | `-Action Checkpoint -CheckpointName <edição>-aplicada` | Opcional |
| 5 | `-Action P0 -Edition <edição> -Label pos-perfil` | — |
| 6 | Reverter os tweaks na toolbox → `-Action P0 … -Label pos-reverter` → comparar `state.json` com o do controle | — |

Matriz e checklist completos: [02-seguranca-legal-qa.md](../02-seguranca-legal-qa.md), seções 4.2–4.3. GPU, drivers, anti-cheat e benchmark exigem **máquina física**.

## 6. Manutenção e limpeza

- **Expiração da avaliação:** `slmgr /xpr` na VM. Antes de vencer, recrie a VM (`-Action Remove -DeleteFiles` e depois `Create`). **Não** estender o prazo (ADR-010).
- **Espaço:** checkpoints crescem; remova os antigos com o Gerenciador do Hyper-V ou `Remove-VMSnapshot`.
- **Remover tudo:** `-Action Remove -DeleteFiles` (pede confirmação; só apaga dentro de `C:\DEV\BigZ-Lab\vms\`).

## Pendências / não verificado

- Primeira execução real dos scripts (depois do reinício): começar por `-Action Status`.
- Hash de referência da ISO de avaliação no site da Microsoft: não verificado.
- Conta local no OOBE do Enterprise: não verificado.
- Nome `Default Switch` em hosts pt-BR: o script valida e lista os switches disponíveis se não encontrar.
- Desempenho da DEV (WSL aninhado) com 4 GB: não medido.
- VirtualBox 7 como segundo hipervisor: adiado até o Hyper-V estar validado.
