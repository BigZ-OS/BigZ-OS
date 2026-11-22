# BigZ OS — Carta do Projeto

> Documento-base para todo o time. Leia antes de qualquer tarefa.
> Fonte original: `IDEIA DO PROJETO QUE PODE MUDAR A MINHA VIDA.docx` (raiz do projeto).

## Visão
Um Windows totalmente personalizável, **gratuito e seguro**, em 3 edições:

| Edição | Público | Foco |
|---|---|---|
| **DEV** | Desenvolvedores | Pronto para trabalhar: ferramentas de dev, toolbox (navegador, antivírus, apps), barra de tarefas/menus/Explorer personalizados, ótimo desempenho |
| **Balanced** | Uso geral | Seguro, estável, personalizável e diferente; toolbox completa |
| **Full Performance** | Gamers / desempenho extremo | Remove tudo que pesa; toolbox só de performance |

Inspirações: Ghost Spectre (edições modificadas + toolbox), Chris Titus WinUtil (toolbox), Atlas OS, ReviOS, Tiny11, etc.
Meta: ser a alternativa gratuita e confiável num mundo onde as melhores opções são pagas ou inseguras. Monetização: apenas "Buy Me a Coffee".

## Regras inegociáveis
1. **Legalidade:** NÃO redistribuímos ISOs/imagens do Windows nem binários da Microsoft (viola a licença da Microsoft e expõe o projeto a remoção/DMCA). Nada de ativadores, cracks ou bypass de licença.
   Modelo adotado (como Atlas OS / Tiny11 builder / WinUtil): **o BigZ OS é um conjunto de scripts/ferramentas open source** que o usuário aplica sobre **o próprio Windows oficial** — um *builder* que transforma a ISO oficial do usuário em uma das 3 edições, e uma *toolbox* pós-instalação.
2. **Segurança e transparência:** todo código aberto, auditável, sem binários opacos; releases assinadas/checksums; cada tweak documentado e reversível quando possível.
3. **Licença:** gratuito para todos; uso comercial exige atribuição e contribuição de volta à comunidade (licença final a definir pelo setor de Comunidade).
4. **Infra:** repositório **público no GitHub**; backup do projeto no **Google Drive**; hospedagem e banco SQL **gratuitos**, **proibido Supabase e Vercel**.
5. **Fontes:** nada inventado. Toda afirmação de pesquisa leva link. Dados não confirmados são marcados como "não verificado".
6. **Ações externas** (criar repo, publicar, postar em fóruns, cadastrar contas, pagar) só com aprovação do usuário, via Auron.

## Estrutura de pastas
- `docs/` — carta, arquitetura, decisões (ADRs), roadmap
- `pesquisa/` — relatórios de pesquisa de mercado/comunidade
- `design/` — identidade visual, UX do shell (taskbar, menus, Explorer)
- `toolbox/` — catálogo e código da toolbox
- `builder/` — scripts que geram as 3 edições a partir da ISO oficial
- `infra/` — hospedagem, banco, CI/CD, backup
- `comunidade/` — licença, README, CONTRIBUTING, código de conduta, canais

## Organização (empresa BigZ)
| Agente | Setor | Responsabilidade |
|---|---|---|
| **Auron** | Diretoria | Recebe os comandos do usuário, planeja, delega, integra e decide |
| **Lulu** | Pesquisa & Inteligência | Comunidade, Reddit, fóruns, concorrentes, dores e lacunas |
| **Cid** | Engenharia de Sistema | Arquitetura e *builder* das edições (DISM, unattend, PowerShell) |
| **Rikku** | Toolbox & Apps | Toolbox, catálogo de apps (winget), tweaks |
| **Beatrix** | Segurança, QA & Conformidade | Riscos legais/técnicos, testes em VM, auditoria de tweaks |
| **Yuna** | Design & UX | Identidade visual, shell personalizado, site |
| **Cloud** | Infra & DevOps | GitHub, CI, hospedagem/SQL gratuitos, backup no Drive |
| **Tellah** | Documentação & Comunidade | Licença, README, docs, canais, Buy Me a Coffee |

## Fluxo de trabalho
- Cada agente entrega em Markdown na sua pasta, com fontes, e avisa o Auron por mensagem com um resumo curto.
- Decisões importantes viram ADR em `docs/decisoes/`.
- Idioma: Português (Brasil). Código e commits podem ser em inglês.
