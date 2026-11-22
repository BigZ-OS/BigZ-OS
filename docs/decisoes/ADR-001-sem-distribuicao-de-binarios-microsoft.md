# ADR-001 — Não distribuir ISO, WIM ou binários da Microsoft

- **Status:** Aceita · **Data:** 2026-11-21 · **Dono:** Beatrix · **Revisores:** Auron, Cid

## Contexto
Os Windows modificados mais conhecidos distribuem ISOs prontas. Isso viola a licença do Windows e impede o usuário de verificar o conteúdo, e há casos reais de imagens com malware (clipper na partição EFI, minerador + RAT). Projetos que seguem no ar há anos (Atlas OS, ReviOS, tiny11builder, WinUtil) distribuem só scripts e configurações, aplicados sobre o Windows oficial do usuário. Em 2020, a BSA, em nome da Microsoft, derrubou no GitHub o "Ninjutsu OS", um Windows modificado com link de download.

## Decisão
1. O BigZ OS publica **apenas código, perfis, catálogos e documentação próprios**.
2. **Nunca** hospedamos, espelhamos ou linkamos diretamente ISO, WIM, ESD, SWM, VHD(X), pacotes ou qualquer binário da Microsoft, em nenhum canal (Releases, site, Drive, torrent, Archive).
3. O **builder** roda na máquina do usuário, sobre a **ISO oficial que ele fornece** ou baixa da página oficial da Microsoft. A ISO gerada é para uso do próprio usuário e não deve ser compartilhada; a documentação diz isso.
4. A **toolbox** atua pós-instalação no Windows oficial e licenciado.
5. Nada de patch em binários do Windows (`explorer.exe`, `uxtheme.dll` etc.).

## Consequências
- ✅ Alinhado à licença (§2.c.ii, publicar/copiar; §2.c.vi, engenharia reversa) e ao modelo que sobrevive na comunidade.
- ✅ O usuário pode auditar tudo: código aberto + ISO oficial + SHA-256.
- ⚠️ Maior atrito para o usuário (precisa da ISO e de alguns minutos de build). Mitigação: UX guiada e o modo `-Plan`.
- ⚠️ Não elimina a cláusula §2.c.iv ("work around technical restrictions"): ver ADR-005 e **[ADVOGADO]**.
- O CI bloqueia esses tipos de arquivo (`.gitignore` já exclui `*.iso`, `*.wim`, `*.esd`, `*.swm`, `*.vhd(x)`).

## Fontes
- Licença do Windows 11 (OEM, abr/2024), §2.c, §5, §6: <https://www.microsoft.com/content/dam/microsoft/usetm/documents/windows/11/oem-(pre-installed)/UseTerms_OEM_Windows_11_English.pdf>
- Microsoft, permissões de copyright ("does not allow redistribution"): <https://www.microsoft.com/en-us/legal/intellectualproperty/copyright/permissions>
- Atlas, por que não há ISO: <https://docs.atlasos.net/faq/install-faq/atlas-iso-files/>
- Caso Ninjutsu OS: <https://torrentfreak.com/removing-annoying-windows-10-features-is-a-dmca-violation-microsoft-says-200611/> · <https://github.com/github/dmca/commit/e6911fbf79c67c6f9e834cb4bc7cdc10679318e7>
- Malware em ISOs piratas: <https://www.techspot.com/news/99063-trojanclipper231-crypto-hijacker-infecting-windows-hidden-efi-partition.html> · <https://www.esentire.com/blog/pirated-windows-os-backdoored-with-cryptominer-and-xtreme-rat>
- Relatório completo: [02-seguranca-legal-qa.md](../02-seguranca-legal-qa.md), seções 1.1–1.5
