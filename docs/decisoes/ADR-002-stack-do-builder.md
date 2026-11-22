# ADR-002 — Stack do builder: PowerShell + DISM + oscdimg + autounattend + perfis JSON

- **Status:** Aceita · **Data:** 2026-11-21 · **Dono:** Cid · **Revisores:** Beatrix, Auron

## Contexto
O builder transforma a ISO oficial do usuário em uma das 3 edições (ADR-001). Ele precisa usar só ferramentas da Microsoft ou do próprio sistema, ser auditável e não depender de binários de terceiros. As referências (tiny11builder, Atlas/AME) mostram o fluxo: montar a imagem, remover Appx, editar o registro offline e gerar a ISO. Também mostram os riscos (remoção de componentes protegidos, `ResetBase`, perda de servicing).

## Decisão
- Script `Build-BigZIso.ps1` em **PowerShell**, usando **DISM** e **`oscdimg` do ADK oficial instalado pelo usuário**, cuja identidade e assinatura ficam registradas no manifesto.
- Configuração do Setup por **`autounattend.xml`** gerado de um template próprio. Conta, ativação, disco e OOBE ficam nos fluxos interativos do Windows.
- Edições descritas como **perfis JSON versionados** (`schemaVersion`), validados contra o catálogo (ADR-004).
- Escopo inicial: **Windows 11 25H2 x64, Home e Pro, UEFI**. A 26H2 entra depois de passar na matriz de QA.
- Modo **`-Plan`** obrigatório antes do build: só inspeciona e mostra o que vai mudar.
- A v0 se limita a **remover Appx por identidade verificada** e a valores de registro offline tipados e revisados. Componentes protegidos (ADR-005) ficam de fora.
- Saída: ISO com um índice + SHA-256 + manifesto JSON local (hash da ISO de origem, perfil, versões).

## Consequências
- ✅ Nenhum binário de terceiros no pipeline; tudo auditável.
- ✅ O manifesto permite reproduzir e investigar um build.
- ⚠️ Exige ADK instalado e privilégio de admin no build. A UX precisa guiar isso.
- ⚠️ A reversão de um build é refazer a partir da ISO original (documentar).
- Código do tiny11builder **não pode ser copiado** (ADR-008); a implementação é original.

## Fontes
- Arquitetura v0 (Cid): [01-arquitetura-v0.md](../01-arquitetura-v0.md), seções 1–2
- DISM, gerenciamento de imagem: <https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-image-management-command-line-options-s14?view=windows-11>
- DISM, Appx: <https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-app-package--appx-or-appxbundle--servicing-command-line-options?view=windows-11>
- Oscdimg: <https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/oscdimg-command-line-options?view=windows-11>
- ADK: <https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install/>
- Automação do Setup: <https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-automation-overview>
- WinSxS (não apagar): <https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/clean-up-the-winsxs-folder?view=windows-11>
