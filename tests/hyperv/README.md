# Laboratório Hyper-V (`tests/hyperv/`)

Scripts para criar e operar a VM de teste do BigZ OS e rodar os testes P0 de [`tests/vm`](../vm/README.md) dentro dela via **PowerShell Direct**. Roteiro completo: [docs/qa/roteiro-vm-hyperv-referencia.md](../../docs/qa/roteiro-vm-hyperv-referencia.md). Licença das VMs: [ADR-010](../../docs/decisoes/ADR-010-licenca-das-vms-de-teste.md).

**Regras dos scripts**
- Todos **exigem PowerShell como administrador** e falham com mensagem clara sem elevação. **Nenhum se autoeleva** e nenhum ativa o Hyper-V.
- Só operam VMs criadas por `New-BigZTestVm.ps1`: marcador `BigZ-Lab` nas Notes e pasta em `C:\DEV\BigZ-Lab\vms\`. Outras VMs do usuário são recusadas.
- **Uma VM ligada por vez**, e só liga se houver memória livre para a inicialização da VM + 0,5 GB.
- Ações destrutivas (`Restore`, `Remove`) pedem confirmação.

| Script | O que faz |
|---|---|
| `Invoke-BigZLab.ps1 -Action …` | **Ponto de entrada único** (uma janela de UAC por ação). Grava transcrição e `last-status.json` em `C:\DEV\BigZ-Lab\logs\`, que agentes não elevados conseguem ler |
| `New-BigZTestVm.ps1` | Gen2, Secure Boot (modelo Microsoft Windows), vTPM, 4 GB dinâmica (mín. 2 GB, máx. 4 GB), 2 vCPU, VHDX dinâmico de 64 GB, `Default Switch`, ISO no DVD. Registra o SHA-256 da ISO nas Notes |
| `Start-BigZTestVm.ps1` | Liga a VM (checa "uma por vez" e a memória livre); `-Connect` abre o console |
| `Checkpoint-BigZTestVm.ps1` | Desliga de forma limpa, ejeta a ISO, põe o disco como 1º boot e cria o checkpoint (padrão `limpo`) |
| `Restore-BigZTestVm.ps1` | Volta ao checkpoint (padrão `limpo`), descartando o estado atual |
| `Invoke-BigZVmP0.ps1` | Copia `tests\vm` para `C:\BigZ\tests\vm` na VM, roda `Invoke-BigZVmChecks.ps1` e traz os resultados para `C:\DEV\BigZ-Lab\results\` |
| `Remove-BigZTestVm.ps1` | Remove a VM; com `-DeleteFiles`, apaga a pasta dela (disco e checkpoints) |
| `BigZ.HyperVLab.psm1` | Guardas comuns (testadas em `tests/unit/BigZ.HyperVLab.Tests.ps1`) |

## Uso típico

Um agente inicia a ação com UAC; o usuário aceita na tela. O agente lê o resultado em `C:\DEV\BigZ-Lab\logs\last-status.json`.

```powershell
$lab = 'C:\DEV\PROJETOS_MDEV\BigZ OS\tests\hyperv\Invoke-BigZLab.ps1'
function Start-BigZLabAction([string]$Arguments) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$lab`" $Arguments"
}

Start-BigZLabAction '-Action Status'
Start-BigZLabAction '-Action Create -IsoPath "C:\DEV\BigZ-Lab\iso\<arquivo>.iso"'   # cria, liga e abre o console
# ... o usuário instala o Windows, conclui a OOBE e roda o Windows Update na VM ...
Start-BigZLabAction '-Action Checkpoint'                                            # checkpoint "limpo"
Start-BigZLabAction '-Action Start'
Start-BigZLabAction '-Action P0 -Edition balanced -Label controle -InstallPester -SkipWinget'
Start-BigZLabAction '-Action Reset'                                                 # volta ao "limpo" (pede confirmação)
```

- O `-NoExit` mantém a janela elevada aberta para o usuário ver o resultado. Prompts (confirmação, credencial da VM) aparecem nessa janela e **só o usuário responde**.
- A credencial pedida no `P0` é a da **conta de laboratório da VM**, digitada no prompt do Windows. Nunca vai para o chat nem para arquivo.
- `-SkipWinget`: o winget é registrado por usuário e pode não funcionar pelo PowerShell Direct. Rode o bloco Winget num console interativo da VM (`tests/vm/README.md`).

## Validação feita (sem Hyper-V)

- PSScriptAnalyzer 1.25: **0 avisos** em `tests/` (mesma regra do CI).
- `tests/unit/BigZ.HyperVLab.Tests.ps1`: **16/16** no Pester 5.7.1, com as guardas de caminho, memória, elevação, marcador e "uma VM por vez" testadas com mocks.
- Os 7 scripts foram executados **sem elevação** e todos pararam na mensagem de administrador.
- ⏳ **Não executado com Hyper-V nem elevado** (o Hyper-V foi ativado mas ainda falta reiniciar o PC). A primeira execução real é com `-Action Status`.
