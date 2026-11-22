# ADR-008 — Reuso de código de terceiros conforme a licença

- **Status:** Aceita · **Data:** 2026-11-21 · **Dono:** Tellah · **Revisores:** Cid, Beatrix

## Contexto
As referências técnicas têm licenças diferentes. Sem licença, o código é "todos os direitos reservados". A licença do BigZ recomendada é GPL-3.0-or-later (pendente de aprovação do usuário), compatível com código MIT e GPL-3.0 que entra no projeto.

## Decisão
| Projeto | Licença encontrada | Regra |
|---|---|---|
| **tiny11builder** (ntdevlabs) | Sem arquivo de licença ("This upstream checkout contains no standalone license file") | **Não copiar código, XML nem listas.** Só reimplementar ideias de conhecimento público (DISM/unattend), ou pedir permissão por escrito |
| **WinUtil** (ChrisTitusTech) | MIT | Pode reaproveitar, preservando aviso e copyright |
| **Win11Debloat** (Raphire) | MIT | Idem |
| **Sophia Script** (farag2) | MIT | Idem |
| **trusted-uninstaller-cli** (Ameliorated) | MIT | Idem. A GUI do AME Wizard é fechada: **não depender dela** |
| **Atlas** | GPL-3.0 | Reuso exige que o BigZ seja GPL-3.0 compatível (ok se o usuário aprovar GPL-3.0-or-later) |

Processo:
1. Todo trecho reaproveitado entra em `THIRD-PARTY-NOTICES.md` com origem, commit, autor, licença e aviso.
2. O PR que traz código de terceiros marca isso no template e passa por revisão de licença (Tellah).
3. Código sem licença ou com licença incompatível com GPLv3 (ex.: GPLv2-only, restrição de uso) **não entra**.
4. `builder/_refs/` é só leitura local, fica fora do versionamento (`.gitignore`) e não entra em releases.

## Consequências
- ✅ Evita um risco de DMCA vindo de terceiros (não só da Microsoft).
- ⚠️ Se a licença final **não** for GPL-3.0 compatível, o reuso do Atlas cai e este ADR precisa ser revisto.
- ⚠️ O tiny11builder pode ter publicado licença depois da consulta; reverificar online antes de qualquer pedido de uso (não verificado online, só no checkout local).

## Fontes
- Licença e comunidade (Tellah): [../../comunidade/01-licenca-e-comunidade.md](../../comunidade/01-licenca-e-comunidade.md), seção 4
- Aviso do tiny11builder: <https://github.com/ntdevlabs/tiny11builder/blob/winui-preview/NOTICE.md>
- GitHub sobre repositórios sem licença: <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository>
- Compatibilidade de licenças (FSF): <https://www.gnu.org/licenses/license-list.html>
- Atlas, licença: <https://github.com/Atlas-OS/Atlas/blob/main/LICENSE>
