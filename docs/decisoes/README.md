# Registro de decisões (ADRs)

Formato curto: **Status · Contexto · Decisão · Consequências · Fontes**. Uma decisão por arquivo. Para mudar uma decisão aceita, crie um ADR novo que a substitua (`Substitui: ADR-00X`) e marque a antiga como **Substituída**.

| ADR | Título | Status | Dono |
|---|---|---|---|
| [001](ADR-001-sem-distribuicao-de-binarios-microsoft.md) | Não distribuir ISO/WIM/binários da Microsoft; builder local + toolbox | Aceita | Beatrix |
| [002](ADR-002-stack-do-builder.md) | Builder em PowerShell + DISM + oscdimg (ADK) + autounattend + perfis JSON | Aceita | Cid |
| [003](ADR-003-stack-da-toolbox.md) | Toolbox v0 em Windows PowerShell 5.1 + WPF, CLI e GUI com o mesmo motor | Aceita | Cid |
| [004](ADR-004-contrato-json-de-tweaks-e-apps.md) | Contrato JSON único de tweak/app | Aceita | Cid + Rikku |
| [005](ADR-005-politica-de-risco-de-tweaks.md) | Política de risco 🟢/🟡/🔴 | Aceita | Beatrix + Cid |
| [006](ADR-006-uso-de-marcas-microsoft.md) | Marca: sem "Windows" no nome/domínio/logo | Aceita | Beatrix |
| [007](ADR-007-sem-ativadores.md) | Nada de ativadores, KMS ou MAS | Aceita | Beatrix |
| [008](ADR-008-reuso-de-codigo-de-terceiros.md) | Reuso de código de terceiros conforme a licença | Aceita | Tellah |
| [009](ADR-009-infraestrutura.md) | Infra: Cloudflare Pages/Workers/D1 + GitHub Pages + Releases; telemetria desligada | Aceita (execução depende do usuário) | Cloud |

Base: [Plano consolidado](../03-plano-consolidado.md) · [Carta](../00-CARTA-DO-PROJETO.md).

> As notas jurídicas destes ADRs **não são parecer jurídico**. Os pontos marcados com **[ADVOGADO]** aguardam revisão profissional (perguntas na seção 1.5 de [02-seguranca-legal-qa.md](../02-seguranca-legal-qa.md)).
