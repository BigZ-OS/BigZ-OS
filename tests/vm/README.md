# Testes P0 dentro da VM (`tests/vm/`)

Testes **Pester 5/6** que verificam se uma instalação continua com a **base comum de segurança** da [ADR-005](../../docs/decisoes/ADR-005-politica-de-risco-de-tweaks.md) depois de aplicar uma edição do BigZ OS. Eles cobrem o checklist P0 da seção 4.3 de [02-seguranca-legal-qa.md](../../docs/02-seguranca-legal-qa.md).

> ⚠️ Rodar **somente dentro de uma VM de laboratório**. Os testes só leem o estado do sistema; a exceção é a tag `Mutating`, que instala um pacote via winget e só roda com `-IncludeMutating`.

| Arquivo | Função |
|---|---|
| `BigZ.VmChecks.psm1` | Coletores somente leitura (registro, serviços, Defender, Appx, winget, WSL, TPM, WinRE...) |
| `P0.VmState.Tests.ps1` | Os testes Pester (por tag) |
| `Invoke-BigZVmChecks.ps1` | Script que roda os testes: exige admin, carrega o Pester 5.5+, roda e salva `state.json`, `p0-results.xml` (NUnit) e `summary.json` em `results/` |

## Como rodar (dentro da VM)

```powershell
# PowerShell como administrador, logado com o usuário de teste (o winget é por usuário)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass   # vale só para esta janela
cd C:\BigZ\tests\vm
.\Invoke-BigZVmChecks.ps1 -Edition balanced -Label controle -InstallPester
```

- `-Edition`: `dev` · `balanced` · `full-performance` (chaves canônicas da ADR-004). O bloco de WSL só roda em `dev`.
- `-Label`: nome curto da execução (`controle`, `pos-perfil`, `pos-reverter`...).
- `-InstallPester`: instala o Pester 5.5+ do PowerShell Gallery no escopo do usuário. O Windows vem com o Pester 3.4, que **não** serve.
- `-SkipOnlineSearch`: pula a busca real no Windows Update (tag `Online`, pode levar minutos).
- `-SkipActivation`: pula o teste de ativação (ex.: VM ainda não ativada).
- `-IncludeMutating`: inclui a instalação de teste via winget (padrão `Microsoft.PowerShell`).
- `-AllowOptIn`: aceita opt-ins 🟡 (só em `full-performance`). **Na v0 nenhum item do catálogo usa opt-in**; o parâmetro existe para a F3.
- Código de saída = número de testes que falharam (0 = P0 verde).

## Tags

`P0` (todos) · `Base` (Secure Boot, TPM, WinRE, saúde da imagem, BitLocker) · `Activation` · `Update` · `Online` · `Defender` (inclui SmartScreen e firewall) · `UAC` · `Store` (inclui WebView2) · `Gaming` · `Winget` · `Mutating` · `WSL`

## Ordem obrigatória

1. **VM de controle** (Windows oficial, sem BigZ), já com o Windows Update em dia → precisa dar **0 falhas**. Se algo falhar aqui, o problema é do teste ou do ambiente: corrija antes de culpar o BigZ.
2. Restaurar o checkpoint, aplicar a edição do BigZ, rodar o Windows Update e então o P0.
3. Para tweaks reversíveis: aplicar → P0 → **reverter** → P0 e comparar os `state.json` das duas execuções.

Roteiro completo da VM: [docs/qa/roteiro-vm-hyperv-referencia.md](../../docs/qa/roteiro-vm-hyperv-referencia.md).

## O que foi validado e o que falta

- ✅ Sem erros de parse e sem avisos no PSScriptAnalyzer 1.25 (as supressões no arquivo de testes são falsos positivos conhecidos do escopo do Pester).
- ✅ Execução **sem admin** num Windows 11 Pro 26300 real (não VM), com Pester **5.7.1** e **6.2.0**, excluindo as tags `Online` e `Mutating`. A edição `balanced` passou sem falhas, com os testes que exigem admin pulados. Em `dev`, só falharam os testes de WSL, como esperado, porque o WSL não está instalado naquele PC.
- ⏳ **Ainda não executado como administrador nem dentro de uma VM.** Nomes de pacotes Appx (`Microsoft.StorePurchaseApp`, `Microsoft.UI.Xaml.*`, `Microsoft.Xbox*`), a detecção do WinRE pelo `reagentc /info` e o recurso `Microsoft-Windows-Subsystem-Linux` precisam ser confirmados na primeira execução na VM de controle (não verificado).
- ⏳ O `winget` dentro de sessões PowerShell Direct (não interativas) não foi testado. Prefira rodar o bloco Winget num console interativo da VM.
