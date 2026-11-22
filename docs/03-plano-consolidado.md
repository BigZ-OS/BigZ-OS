# BigZ OS — Plano Consolidado v0 (Auron)

Data: 21/11/2026. Base: as 7 entregas da rodada 1.

| Setor | Entrega |
|---|---|
| Pesquisa (Lulu) | `pesquisa/01-comunidade-e-concorrencia.md` |
| Engenharia (Cid) | `docs/01-arquitetura-v0.md` |
| Segurança/Legal/QA (Beatrix) | `docs/02-seguranca-legal-qa.md` |
| Toolbox (Rikku) | `toolbox/01-catalogo-v0.md` |
| Design (Yuna) | `design/01-identidade-e-ux-v0.md`, `design/logo/*.svg`, `design/toolbox-wireframe.svg` |
| Infra (Cloud) | `infra/01-plano-infra.md`, `.gitignore`, `.gitattributes`, git local |
| Comunidade (Tellah) | `comunidade/01-licenca-e-comunidade.md`, `02-plano-de-comunidade.md`, README, CONTRIBUTING, CODE_OF_CONDUCT |

## 1. Posicionamento (o que nos diferencia)
A comunidade prefere "instalação limpa + ferramenta open source auditável" a ISOs de terceiros, e o maior medo é malware e Windows quebrado. O BigZ OS vai ser **o Windows personalizado em que dá para confiar**:
1. **Plano antes de aplicar (dry-run):** o usuário vê tudo que vai mudar, com o risco de cada item.
2. **Reversão real por ajuste**, sem precisar reinstalar.
3. **Segurança ligada por padrão:** Update, Defender, UAC, SmartScreen, Store e Xbox preservados.
4. **Nenhum binário opaco:** build só no CI público, SHA256SUMS e atestado de origem.
5. **Testes automáticos em VM** para cada build do Windows, com a matriz de compatibilidade publicada.
6. **Lacunas de mercado:** perfil DEV "pronto para trabalhar" (nenhum concorrente tem) e Full Performance com benchmark reproduzível, compatível com anticheat.

## 2. Decisões tomadas (viram ADRs em `docs/decisoes/`)
| # | Decisão | Base |
|---|---|---|
| ADR-001 | Não distribuir ISO/WIM/binário da Microsoft. Builder local sobre a ISO oficial do usuário + toolbox pós-instalação | Licença do Windows 11, §2.c.ii e §2.c.iv; caso Ninjutsu OS (Beatrix) |
| ADR-002 | Builder em PowerShell + DISM + `oscdimg` do ADK + `autounattend.xml` + perfis JSON. Começa com Windows 11 25H2 x64, Home/Pro, UEFI | Cid |
| ADR-003 | Toolbox v0 em Windows PowerShell 5.1 + WPF, com CLI e GUI usando o mesmo motor. WinUI 3 fica para reavaliar depois | Cid |
| ADR-004 | Contrato JSON único de tweak e app (fase, escopo, risco, verificação, reversão), aprovado por Cid e Rikku | Cid + Rikku |
| ADR-005 | Política 🟢/🟡/🔴: nada 🔴 em nenhuma edição (WinSxS, Defender, Store, WebView2, WinRE, UAC, desligar Windows Update). Na Full Performance, o modo extremo é opt-in e reversível | Beatrix + Cid |
| ADR-006 | Sem "Windows" no nome, domínio ou logo. Só "para Windows 11" de forma referencial, com rodapé de marca. Sem fontes ou ícones da Microsoft | Beatrix |
| ADR-007 | Nada de ativadores, KMS ou MAS, nem na documentação | Beatrix + Lulu |
| ADR-008 | tiny11builder não tem licença: não copiar código dele, só reimplementar. MIT (WinUtil, Win11Debloat, Sophia) pode ser reaproveitado com aviso. Atlas é GPL-3.0 | Tellah |
| ADR-009 | Infra: Cloudflare Pages + Workers + D1 como principal, GitHub Pages como reserva, GitHub Releases para downloads. Telemetria desligada por padrão. Sem Supabase/Vercel | Cloud |

### Divergências resolvidas
- **Shell personalizado (Yuna) × "shell padrão" (Cid):** a base de cada edição usa o shell do Windows. Os visuais da Yuna (Open-Shell, Nilesoft, TranslucentTB) entram como **presets opcionais na toolbox**, já pré-selecionados por edição, com reversão. Ferramentas que fazem patch em binários do Windows ficam fora.
- **Full Performance "latência zero / 100% silencioso" (Yuna):** sem promessas de desempenho até haver benchmark medido. A Game Bar continua (Cid).
- **Licença × SignPath (Beatrix):** a recomendação do Tellah (GPL-3.0-or-later) é aprovada pela OSI, então o problema some. O usuário precisa aprovar.

## 3. Roadmap
| Fase | Meta | Entregável |
|---|---|---|
| **F0 — Fundação** (agora) | Repo, licença, CI de lint, ADRs, SECURITY.md | Repo público com README e estrutura |
| **F1 — MVP Toolbox** | CLI + GUI com dry-run, aplicar/reverter, 10–15 tweaks 🟢 e catálogo winget | `bigz-toolbox v0.1` no Windows oficial |
| **F2 — MVP Builder** | `Build-BigZIso.ps1 -Plan` e build do perfil Balanced | ISO gerada localmente e testada em Hyper-V |
| **F3 — 3 edições** | Perfis DEV e Full Performance + presets visuais da Yuna | Release v0.3 com matriz de testes |
| **F4 — Comunidade** | Site (Cloudflare Pages), docs "por que" de cada tweak, Discussions, Buy Me a Coffee / Sponsors | Lançamento público |

## 4. Rodada 2 (interna, sem ações externas)
- **Cid:** esqueleto do repositório (layout da arquitetura), módulo do motor de tweaks (plan/apply/verify/revert) e `Build-BigZIso.ps1 -Plan` (só inspeção).
- **Rikku:** `catalog/apps.json` e `catalog/tweaks.json` com os primeiros itens 🟢, e o protótipo da GUI WPF a partir do wireframe da Yuna.
- **Beatrix:** ADRs 001–009 em `docs/decisoes/`, SECURITY.md, testes Pester do checklist P0 e roteiro da VM Hyper-V de referência.
- **Cloud:** `.github/` (templates, workflow de lint PSScriptAnalyzer, workflow de release com SHA256SUMS), Actions fixadas por SHA.
- **Yuna:** remover qualquer referência a marca da Microsoft, adicionar o rodapé de marca, exportar presets visuais por edição como itens do catálogo (com a Rikku) e remover promessas de desempenho.
- **Tellah:** finalizar LICENSE (depois da aprovação), README na raiz, página "Segurança e transparência", modelo de documentação "por que" por tweak.
- **Lulu:** rodada 2 da pesquisa (fóruns que faltaram, Discussions do Atlas/WinUtil, os tweaks que mais quebram coisas, para a suíte de testes).

## 5. Pendências do usuário
1. **Licença:** GPL-3.0-or-later (código) + CC BY-SA 4.0 (assets)? Nenhuma licença livre pode proibir uso comercial. A GPL obriga dar crédito e abrir o código das versões modificadas que forem distribuídas.
2. **GitHub:** conta/organização e nome do repo (sugestão `BigZ-OS/BigZ-OS`). Aprovar a criação pública e o push inicial.
3. **Cloudflare:** conta para o site e o D1 (pode ficar para a F4).
4. **Google Drive:** aprovar instalar o rclone e o login OAuth para o backup semanal.
5. **E-mail de contato** público do projeto (SECURITY.md / Código de Conduta).
6. **Advogado** (antes do lançamento público): as 6 perguntas da seção 1.5 do relatório da Beatrix.
7. **Buy Me a Coffee no Brasil:** conferir se a plataforma está disponível (não verificado). GitHub Sponsors tem taxa 0% para pessoa física.
