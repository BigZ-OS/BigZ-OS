# ADR-005 — Política de risco de tweaks 🟢/🟡/🔴

- **Status:** Aceita · **Data:** 2026-11-21 · **Donos:** Beatrix + Cid · **Revisores:** Rikku, Auron

## Contexto
O medo nº 1 da comunidade é malware e Windows quebrado. Os tweaks que mais causam dano são conhecidos: apagar WinSxS, remover o servicing ou o Windows Update, remover o Defender, desligar o UAC. Malware real em Windows pirata também desativa o Defender. O Atlas foi criticado publicamente por isso e voltou atrás. A edição Full Performance é a de maior pressão por cortes.

## Decisão
**Classes** (derivadas de `risk` + `securityImpact`, ADR-004):

| Classe | Definição | Tratamento |
|---|---|---|
| 🟢 Verde | Preferência reversível, sem redução de proteção (`securityImpact: none`, `risk: low/medium`) | Pode ser padrão da edição |
| 🟡 Amarelo | Reduz proteção ou desempenho/compatibilidade de forma relevante, mas é reversível pelo motor | **Só opt-in explícito**: tela de risco + fonte + "entendo" + reversão em 1 clique + selo "Modo de risco ativo" |
| 🔴 Vermelho | Quebra servicing, recuperação ou proteção de forma difícil de reverter, ou contraria a licença | **Proibido em todas as edições.** O validador rejeita |

**Lista protegida 🔴 (mínimo, para o validador):**
- Apagar ou "limpar" o WinSxS manualmente (só `DISM /StartComponentCleanup` é permitido) · `ResetBase` na v0
- Remover pacotes de servicing, Windows Update ou seus serviços/tarefas; **desativar** o Windows Update (pausar/adiar por política oficial é 🟡/🟢)
- **Remover** o Defender; desligar Tamper Protection por script; desligar o Defender sem outro AV registrado
- **Desligar o UAC** (`EnableLUA=0`) ou `ConsentPromptBehaviorAdmin=0`
- Remover Microsoft Store, App Installer (winget), frameworks Appx, **WebView2**, **WinRE**/Restauração do Sistema
- Patch em binários do Windows; burlar ativação (ADR-007)
- Desligar BitLocker num disco já criptografado sem backup da chave

**Candidatos 🟡 (todos fora da v0):** desligar SmartScreen; Defender passivo com outro AV; desligar HVCI/Virtual Machine Platform (quebra o WSL); desligar mitigações de CPU; burlar TPM/CPU (**[ADVOGADO]**, licença §2.c.iv); não ativar a criptografia automática na instalação limpa.

**Fases:**
- **v0 (F1–F2):** o motor **bloqueia todo item `securityImpact: reducesProtection`** em qualquer modo, conforme a arquitetura do Cid. Só itens 🟢 são liberados.
- **F3:** cada 🟡 entra com PR próprio, fonte, 2 aprovações (Beatrix obrigatória) e testes na matriz. Isso vale sobretudo para o "modo extremo" da Full Performance, que continua **opt-in e reversível**, com padrão seguro.

**Base comum preservada em todas as edições:** Windows Update, Defender, SmartScreen, UAC, firewall, VBS/HVCI (conforme o hardware), TPM, Secure Boot, BitLocker, WinRE, WinSxS, Store, App Installer, frameworks Appx, WebView2, Xbox/Gaming Services.

## Consequências
- ✅ "Segurança ligada por padrão" vira regra verificável: os testes P0 em `tests/vm/` falham se a base comum for violada.
- ✅ Diferencial público frente a Ghost Spectre e similares.
- ⚠️ A Full Performance terá ganhos menores no início; promessas de desempenho só com benchmark medido (plano consolidado).
- ⚠️ A lista protegida precisa ser mantida por build do Windows (Cid + Beatrix).

## Fontes
- Relatório de segurança, seção 2.2 (tabela por tweak, com fontes): [02-seguranca-legal-qa.md](../02-seguranca-legal-qa.md)
- Arquitetura v0, seções 3–4 (bloqueio de operações que reduzem proteção; base comum): [01-arquitetura-v0.md](../01-arquitetura-v0.md)
- WinSxS: <https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/clean-up-the-winsxs-folder>
- UAC: <https://learn.microsoft.com/en-us/windows/security/application-security/application-control/user-account-control/architecture>
- Defender, modo passivo / compatibilidade: <https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-antivirus-compatibility>
- Tamper Protection: <https://learn.microsoft.com/en-us/defender-endpoint/tamper-protection-overview>
- Jogos × HVCI/VMP (Microsoft): <https://support.microsoft.com/article/a255f612-2949-4373-a566-ff6f3f474613>
- tiny11 Core não recebe servicing: <https://github.com/ntdevlabs/tiny11builder>
- Críticas ao Atlas (Defender/mitigações): <https://www.vice.com/en/article/windows-for-gamers-rolls-dice-with-your-security-atlasos>
