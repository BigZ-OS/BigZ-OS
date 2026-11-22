# 02 — Rodada 2: lacunas, tweaks "quebradores", pedidos de devs e prova de desempenho

> Autora: Lulu (Pesquisa & Inteligência) · Coleta: 2026-11-21 · Para: Auron (Diretoria) · Continua o [01-comunidade-e-concorrencia.md](01-comunidade-e-concorrencia.md)
> Regras: toda afirmação tem link; o que não confirmei está como **[não verificado]**. Só leitura de páginas públicas; nenhuma conta criada, nada postado.
> Nota sobre Reddit: o navegador traduziu os textos para português automaticamente. O que está entre aspas é paráfrase da tradução — confira o original antes de citar literalmente.

## 0. Resumo executivo

1. **Achado novo e crítico para a edição DEV:** a Microsoft lançou o [Windows Developer Config](https://github.com/microsoft/WindowsDeveloperConfig) (MIT, ~3,6 mil estrelas): um comando `winget configure` que instala ferramentas, aplica ajustes (Developer Mode, caminhos longos, sudo, Terminal, WSL + Ubuntu) e reinicia. Uma edição DEV que só "instala ferramentas" não se diferencia. O caminho é **consumir esse perfil e acrescentar o que ele não faz** (§4).
2. **Padrão dos tweaks que quebram** (§3): quase todos caem em quatro grupos — (a) serviços colocados em "Manual/Desativado", (b) remoção de Defender/Store/componentes de servicing, (c) telemetria/políticas que afetam Explorer/Busca/Xbox, (d) bypass de TPM/Secure Boot. Cada grupo tem caso documentado com fonte.
3. **Dev + "Windows otimizado" conflitam** onde mexem em virtualização/serviços: há issues de WSL e VM no Atlas ([#1615](https://github.com/Atlas-OS/Atlas/issues/1615), [#1327](https://github.com/Atlas-OS/Atlas/issues/1327), [#818](https://github.com/Atlas-OS/Atlas/issues/818)). O Docker Desktop exige WSL2 ou Hyper-V ([Docker forum](https://forums.docker.com/t/docker-desktop-vm-fails-to-start-hyper-v-hypervisor-not-running-despite-all-prerequisites/150088)).
4. **Prova de desempenho aceita pela comunidade** (§5): capturas de frametime (PresentMon/CapFrameX), várias passadas por sistema, 1% e 0,1% lows além da média, hardware/driver/versão do Windows declarados. Testes independentes de Atlas/ReviOS mostram **ganho de média pequeno e 1% lows variáveis**.
5. **Risco de continuidade do Atlas:** o mantenedor principal saiu em 2024 ([Discussion #1252](https://github.com/orgs/Atlas-OS/discussions/1252)) e em 2026-10 usuários perguntam se o projeto está parado ([#1751](https://github.com/orgs/Atlas-OS/discussions/1751)); há trabalho em andamento para o 0.6.0 ([#1767](https://github.com/Atlas-OS/Atlas/issues/1767), [#1752](https://github.com/Atlas-OS/Atlas/issues/1752)).
6. **Acesso:** ElevenForum, My Digital Life e a busca do TenForums estão atrás de verificação anti-bot (Cloudflare). **Não contornei** (§1.4).

---

## 1. Lacunas da rodada 1 — fechamento

### 1.1 GitHub Discussions
- **Atlas** ([lista](https://github.com/Atlas-OS/Atlas/discussions)):
  - Mantenedor principal saiu em 2024-10, citando "13,5 mil estrelas e 1,9 milhão de downloads" ([#1252](https://github.com/orgs/Atlas-OS/discussions/1252)).
  - Em 2026-10-27: "o projeto está parado?" e "quando sai o 0.6.0 com Windows 11 26H2?" ([#1751](https://github.com/orgs/Atlas-OS/discussions/1751)).
  - Outros: pergunta sobre 26H1 ([#1733](https://github.com/orgs/Atlas-OS/discussions/1733)), 26H2 ([#1677](https://github.com/orgs/Atlas-OS/discussions/1677)), conta Microsoft ([#1760](https://github.com/orgs/Atlas-OS/discussions/1760)), "AtlasOS vs Amelabs Privacy+?" ([#1485](https://github.com/orgs/Atlas-OS/discussions/1485)), jogo crashando com HEAP_CORRUPTION em 0.5.0 ([#1748](https://github.com/orgs/Atlas-OS/discussions/1748)). Títulos lidos; **conteúdo das respostas não lido [não verificado]**.
  - Sinal de manutenção: o repositório recebeu push em 2026-11-21 (API do GitHub) e há PRs para 26H2 ([#1752](https://github.com/Atlas-OS/Atlas/issues/1752)) e "Prepare Atlas 0.6.0" ([#1767](https://github.com/Atlas-OS/Atlas/issues/1767)).
- **WinUtil** ([lista](https://github.com/ChrisTitusTech/winutil/discussions)):
  - **"Quero uma lista legível do que o MicroWin remove."** Três usuários pedem: o doc é "abstrato demais" (*"remove telemetria e tracking"*, *"app debloat"*), e dizem que ferramentas para não-técnicos não podem exigir ler o código ([#2718](https://github.com/ChrisTitusTech/winutil/discussions/2718)). Isso reforça a oportunidade nº1 da rodada 1 (plano de mudanças).
  - Outros títulos: remoção correta do Edge ([#2442](https://github.com/ChrisTitusTech/winutil/discussions/2442)), "MicroWin Mild — login local e só o que a descrição diz" ([#1317](https://github.com/ChrisTitusTech/winutil/discussions/1317)), lista de apps banidos/indisponíveis ([#4742](https://github.com/ChrisTitusTech/winutil/discussions/4742)).

### 1.2 r/Tiny11 (~20 mil membros, [página](https://www.reddit.com/r/Tiny11/))
- Top do ano: "acordei com isso…" — usuário de Tiny11 há 2 anos vê de repente tela de conta Microsoft; respostas sugerem "voltar/pular", desligar a "experiência de boas-vindas" nas Configurações, ou trocar para Windows 10 LTSC/IoT ([r/Tiny11](https://www.reddit.com/r/Tiny11/comments/1pfpqte/), 167 pontos, 97 comentários, R).
- Teste do Tiny11 26H2 em "PC fraco com 4 GB" — comentários apontam que o hardware (Ryzen 5 5600 em VM) não é fraco; ceticismo da própria comunidade com benchmarks informais ([r/Tiny11](https://www.reddit.com/r/Tiny11/comments/1xu1z8p/), 96 pontos, R).
- **Distribuição por ISO pronta:** a comunidade compartilha "Tiny11 25H2" por link do archive.org ([post](https://www.reddit.com/r/Tiny11/comments/1s2e6nr/), [archive.org](https://archive.org/details/tiny11_25H2)). **Quem publicou e se é do autor original: [não verificado].** Mostra que mesmo o builder "legal" acaba virando ISO circulando.

### 1.3 Fórum do NTLite (via busca; acesso direto listou só threads recentes)
- **Remover componentes "seguros" quebrou o Windows Update.** Resposta do desenvolvedor: habilitar compatibilidade com *Servicing Stack* e *Windows Update* no preset; sem isso o NTLite não mantém arquivos do WinSxS necessários ([thread](https://ntlite.com/community/threads/solved-removing-several-safe-to-remove-components-now-bricks-windows-update.6006/)).
- Moderador: remover Defender tende a quebrar o WU; melhor desativar serviços do que remover; "quanto menos remover, mais estável" ([mesma thread](https://ntlite.com/community/threads/solved-removing-several-safe-to-remove-components-now-bricks-windows-update.6006/), conforme resumo da busca; **texto completo não lido [não verificado]**).
- Outros casos: "component store is corrupt (25H2)" ([#6025](https://ntlite.com/community/threads/component-store-is-corrupt-w11-25h2.6025/)), digitação por gestos quebra após remoções ([#5805](https://ntlite.com/community/threads/windows-gesture-typing-breaks-after-component-removals.5805/)), "Windows 11 24H2 baixando e reinstalando componentes removidos" ([#5311](https://ntlite.com/community/threads/windows-11-24h2-automatically-redownloading-and-reinstalling-removed-components-packages.5311/)), e "como impedir o Windows de restaurar o que foi removido" ([#5914](https://ntlite.com/community/threads/how-to-stop-windows-from-restoring-removed-things.5914/)). Títulos lidos; conteúdo **[não verificado]**.

### 1.4 Fóruns que não consegui ler
- **ElevenForum, My Digital Life, busca do TenForums:** páginas de verificação anti-bot (Cloudflare). Seguindo a regra de segurança, **não contornei**. Para ElevenForum só tenho trechos de resultado de busca: p.ex. [Windows Update sumiu ao sair do Atlas 0.2.0 para Windows 11](https://www.elevenforum.com/t/trouble-with-windows-update-after-upgrading-from-atlasos-to-windows-11.19730/) (caso antigo, versão legada).
- **Próximo passo possível:** se o Auron aprovar, a Lulu pode pedir ao usuário uma "leitura assistida" (o usuário abre a página e eu leio) — **só com aprovação**.

---

## 2. Ferramentas em profundidade

### 2.1 O&O ShutUp10++
- **O que faz:** freeware portátil de privacidade para Windows 10/11. Cada ajuste tem nível "recomendado / com ressalvas / não recomendado"; ações aplicam todos os de um nível; perfis exportáveis ([recursos](https://www.oo-software.com/en/shutup10/features), [edições](https://www.oo-software.com/en/shutup10/editions)). O FAQ afirma que mudanças são reversíveis e que cria ponto de restauração quando a opção está ativa ([FAQ](https://manuals.oo-software.com/ooshutup10/docs/faq)) — detalhes vieram de resumo de busca; **página do FAQ redirecionou na leitura direta [não verificado no texto]**.
- **Modelo:** gratuito, **código fechado**; existe edição **Premium** que, segundo o resumo, reaplica ajustes após atualizações de recurso e remove Copilot/Recall ([edições](https://www.oo-software.com/en/shutup10/editions); **preço não verificado**).
- **Pontos fortes:** reversão por ajuste, níveis de risco, marca estabelecida. Revisões independentes: [gHacks](https://www.ghacks.net/2021/10/09/improve-your-privacy-with-oo-shutup10-for-windows-11/), [Dedoimedo](https://www.dedoimedo.com/computers/oo-shutup-appbuster-review.html).
- **Críticas:** os rótulos de recomendação são julgamento do fornecedor (não auditoria independente) — comentário no [AlternativeTo](https://alternativeto.net/software/shutup10/about) acha alguns rótulos estranhos (R); um comentário no gHacks relata perda de logins mesmo com backup (**anedota, não verificada**); atualizações de recurso podem reverter ajustes ([resumo de busca; ver Premium acima]).
- **Lição para o BigZ OS:** o que diferencia o O&O é **explicar o risco de cada ajuste e permitir reverter um a um** — oportunidade nº2 da rodada 1. O código aberto do BigZ é diferencial de confiança.

### 2.2 Winhance (memstechtips)
- **O que faz:** app C# para debloat/otimização/customização de Windows 10 e 11, com instalador e versão portátil; "faz quase tudo do UnattendedWinstall sem reinstalar" ([README](https://github.com/memstechtips/Winhance)). Existe também o [UnattendedWinstall](https://github.com/memstechtips/UnattendedWinstall) (autounattend). Testado em Win 10 22H2 e Win 11 23H2/24H2/25H2 (README).
- **Modelo/atividade:** grátis; ~15 mil estrelas; 3 issues abertas; push em 2026-11-19; **licença `NOASSERTION`** (API do GitHub) → ambiguidade a verificar no arquivo LICENSE (**[não verificado]**).
- **Instalação:** `irm "https://get.winhance.net" | iex` ou instalador `.exe` (README) — mesmo padrão de WinUtil.
- **Críticas (issues fechadas, títulos lidos):** programas de inicialização deixam de iniciar após atualização do app ([#377](https://github.com/memstechtips/Winhance/issues/377), 26 comentários); Menu Iniciar vazio ([#285](https://github.com/memstechtips/Winhance/issues/285)); "como reverter ao original" ([#43](https://github.com/memstechtips/Winhance/issues/43)); falha ao abrir após instalar ([#648](https://github.com/memstechtips/Winhance/issues/648)); instalação de apps de terceiros cancelada por HttpClient ([#267](https://github.com/memstechtips/Winhance/issues/267)). **Causas não lidas [não verificado].**
- **Na comunidade:** é recomendado como alternativa ao WinUtil por fazer "tudo que o Chris faz, e mais" ([r/AtlasOS](https://www.reddit.com/r/AtlasOS/comments/1s2lb4g/), R).

### 2.3 ReviOS (Revision)
- **O que faz:** playbook para o AME Wizard, aplicável ao Windows em uso ou **injetado em ISO offline**; inclui o **Revision Tool** (app nativo: configurações do sistema, apps da Store, alternar recursos) ([docs](https://revi.cc/docs/what-is-revi)).
- **Suporte declarado (docs oficiais):** Windows 10 21H2/22H2 (x64) e Windows 11 **23H2, 24H2, 25H2, 26H1 (28000) e 26H2 (26300)**, x64 e ARM64, todas as edições (Home/Pro/Enterprise/LTSC). "Playbooks são agnósticos à versão: não precisa esperar release específico para a build nova" ([docs](https://revi.cc/docs/what-is-revi)). **Isso responde parte da dor nº7 da rodada 1 (atraso em builds novas) — o ReviOS afirma resolver; a veracidade na prática não foi testada [não verificado].**
- **Modelo:** gratuito; playbook CC-BY-SA-4.0 (2,1 mil estrelas), Revision Tool GPL-3.0 (478 estrelas) — API do GitHub, 2026-11-21 ([playbook](https://github.com/meetrevision/playbook), [tool](https://github.com/meetrevision/revision-tool)).
- **Comportamento de Update/Defender (segundo FAQ, via resumo de busca):** atualizações pausadas até 2038, diálogo "Atualizar e desligar" oculto, **atualização de drivers via Windows Update desativada**; Defender é desativado durante a instalação e pode ser reativado pelo Revision Tool ([FAQ listado na busca](https://revi.cc/docs/faq/before/features)). **A página retornou 404 na leitura direta; tratar como [não verificado].**
- **Críticas (issues):** atualizações cumulativas falhando ([#49](https://github.com/meetrevision/playbook/issues/49), 2023, fechada), Edge não removido ([#33](https://github.com/meetrevision/playbook/issues/33)), **SMB 1.0 deixa de funcionar** ([#228](https://github.com/meetrevision/playbook/issues/228), aberta, 2026-07), WSA não inicia ([#79](https://github.com/meetrevision/playbook/issues/79)). Recomendações do Windows 11 não funcionam ([#61](https://github.com/meetrevision/playbook/issues/61)).
- **Comunidade:** "praticamente não mostra ganho de desempenho" ([r/OptimizedGaming](https://www.reddit.com/r/OptimizedGaming/comments/1r14g7b/), R) vs. quem usa há anos sem problemas (mesmo post).
- **Dependência:** roda sobre o AME Wizard (GUI parcialmente fechada — ver rodada 1).

### 2.4 Talon (Raven Dev Team)
- **O que faz:** "Windows do jeito que você quer, em 2 cliques" — remove IA, telemetria e processos de fundo; **integra motores externos** (Win11Debloat, WinUtil) ([README](https://github.com/ravendevteam/talon), [documentação](https://github.com/ravendevteam/talon/blob/main/DOCUMENTATION.md)). Versão "Lite" para Windows 10/sistemas em uso/edições que não sejam Home/Pro. Documentação diz que serve para instalações **novas** de Windows 11 Home/Pro.
- **Pontos de atenção de confiança (README):**
  - Método principal: `irm https://debloat.win | iex`.
  - Método legado: **"definir `C:` como exclusão no Windows Defender" temporariamente** para o Talon não ser interrompido (README). Isso é um padrão de risco: ensina o usuário a desligar a proteção do disco inteiro. O BigZ OS **não deve adotar** esse padrão.
  - O repositório é "espelho somente leitura": **não aceita Issues nem PRs**; feedback por formulário externo (README).
  - A documentação está marcada como **desatualizada**, com "recompensa paga" para quem atualizá-la (documentação).
  - Execução usa binário/Python; para compilar exige Python 3.12.4 (README).
- **Modelo/atividade:** BSD-3-Clause, ~2 mil estrelas, 0 issues (porque estão desativadas), push 2026-09-26. Imprensa: antivírus tende a sinalizar ([BetaNews](https://betanews.com/2025/02/14/no-more-bloat-talon-completely-fixes-microsoft-windows-11-in-just-two-clicks)).
- **Na comunidade:** não encontrei threads de Reddit sobre Talon nesta rodada **[não verificado]**.

### 2.5 Concorrente novo para o DEV: Windows Developer Config (Microsoft)
- **O que é:** conjunto de "setups opinativos" para dev box: **Windows Dev Config** (ferramentas + ajustes + WSL + Ubuntu, uma reinicialização), **WSL Comfort** (shell com zsh/bash, Starship, tema), **Workloads** (linguagens) e **AI tooling** (PyTorch, Ollama, llama.cpp, Foundry Local) ([README](https://github.com/microsoft/WindowsDeveloperConfig)).
- **Conteúdo da experiência "Standard":** Windows Terminal, PowerShell 7, Git, GitHub CLI, GitHub Copilot CLI, VS Code, .NET SDK 10, Python 3.14 + uv, Node LTS + nvm, Coreutils for Windows, Oh My Posh, PowerToys; ajustes de tema escuro, **caminhos longos**, padrões do Explorer, Start/Pesquisa; "Full" acrescenta **Developer Mode, Sudo, widgets desativados e políticas do Edge** (README).
- **Modelo:** MIT; ~3,6 mil estrelas; push 2026-11-06; descrito como GA no Build 2026 ([resumo da Impress Watch](https://forest.watch.impress.co.jp/docs/news/2115400.html), japonês — **não verificado no original**) e baseado em `winget configure` ([blog Microsoft Dev](https://developer.microsoft.com/blog/winget-configuration-set-up-your-dev-machine-in-one-command/), [heise](https://heise.de/-11318088), [docs Learn](https://learn.microsoft.com/windows/package-manager/winget/configure)).
- **O que ele NÃO cobre (inferência da Lulu a partir do README; confirmar com Cid/Rikku):** não aborda debloat/privacidade profunda, personalização de shell (barra/Explorer/menu), nem Defender/Dev Drive. Esse é o espaço do BigZ DEV.

---

## 3. Tweaks citados como "quebradores" (para a suíte de testes da Beatrix)

**Como ler:** *Quem relatou* = tipo de fonte (R relato de usuário; M mantenedor respondeu). *Build* = versão do Windows quando informada na issue; "n/i" = não informada. *Causa* só aparece quando o mantenedor ou uma análise confirmaram; senão "não confirmada". Datas = abertura da issue.

### 3.1 Serviços (Manual/Desativado)

| # | Tweak / ação | O que quebrou | Build / data | Fonte | Causa |
|---|---|---|---|---|---|
| 1 | WinUtil "Set Services to Manual" | **Windows Update falhou** (erro 0x800f0922, rollback) | n/i, 2023-10 | [winutil #1098](https://github.com/ChrisTitusTech/winutil/issues/1098) | Não confirmada |
| 2 | WinUtil, tweaks de serviço (Event Viewer em Manual) via MicroWin | **Explorer travando em qualquer pasta** após instalar a ISO MicroWin | 23H2, 2023-12 | [winutil #1250](https://github.com/ChrisTitusTech/winutil/issues/1250) | **Dono atribuiu aos tweaks de serviço** (Event Viewer) e disse que corrigiria |
| 3 | WinUtil, "Disable Telemetry" | Serviço `XboxGipSvc` preso em "Starting" | Win 11, 2024-03 | [winutil #1733](https://github.com/ChrisTitusTech/winutil/issues/1733) | Não confirmada (usuário suspeita do tweak de telemetria) |
| 4 | WinUtil, lista de serviços em Manual | O tweak "services to manual" passou a reduzir menos serviços em execução (de ~140–160 para ~98–99 no Windows 11, segundo o autor) — regressão de comportamento, não quebra do sistema | WinUtil 2026-01 | [winutil #3876](https://github.com/ChrisTitusTech/winutil/issues/3876) | Comentaristas notam: reduzir demais quebra dependências (~60–65 serviços como ponto "diário" na experiência de um usuário) — **anedota** |
| 5 | Atlas, desativar serviço de LanmanServer | **Loop de crash do Explorer** | n/i (Atlas de 2023), 2023-02 | [Atlas #572](https://github.com/Atlas-OS/Atlas/issues/572) | **Membro do Atlas confirmou** LanmanServer e corrigiu em commit |
| 6 | Atlas, desativar SysMain/Superfetch | **Tarefas de Manutenção Automática não rodam** | n/i, 2024-05 | [Atlas #1096](https://github.com/Atlas-OS/Atlas/issues/1096) | **Membro confirmou** (tarefas ligadas ao SysMain) |
| 7 | Atlas, Hyper-V desativado por padrão | **VM Hyper-V: "Inaccessible boot device"** após aplicar o playbook | Win 10 22H2 (Atlas 0.2.x), 2023-06 | [Atlas #818](https://github.com/Atlas-OS/Atlas/issues/818) | **Membro:** corrigido na 0.3.0 |

### 3.2 Windows Update, Defender, servicing

| # | Tweak / ação | O que quebrou | Build / data | Fonte | Causa |
|---|---|---|---|---|---|
| 8 | WinUtil MicroWin (ISO) | **Atualizações de build/cumulativas falham** na ISO MicroWin (várias máquinas) | 25H2 (26200), 2025-10 | [winutil #3651](https://github.com/ChrisTitusTech/winutil/issues/3651) | Não confirmada; usuários citam workaround de reinstalar |
| 9 | WinUtil MicroWin | "Windows Update not working again" | n/i, 2025-02 | [winutil #3214](https://github.com/ChrisTitusTech/winutil/issues/3214) | Não confirmada |
| 10 | NTLite, desmarcar "compatibilidade Windows Update/Servicing Stack" e remover componentes | **WU quebrado / component store corrompido** | 25H2 e outros, 2025–2026 | [NTLite #6006](https://ntlite.com/community/threads/solved-removing-several-safe-to-remove-components-now-bricks-windows-update.6006/), [#6025](https://ntlite.com/community/threads/component-store-is-corrupt-w11-25h2.6025/) | **Desenvolvedor do NTLite:** ativar compatibilidade de Servicing Stack |
| 11 | Remover **Defender** (NTLite/Tiny11 Core/Ghost Spectre) | Windows Update tende a quebrar; Core "não pode ser atualizado" | vários | [NTLite #6006](https://ntlite.com/community/threads/solved-removing-several-safe-to-remove-components-now-bricks-windows-update.6006/), [README do tiny11](https://github.com/ntdevlabs/tiny11builder) | README do tiny11: Core **remove suporte a update/recuperação** (documentado) |
| 12 | ReviOS, pausa de atualizações e drivers via WU desativados | Atualizações cumulativas falhando (2023) / **SMB1 deixa de funcionar** (2026-07) | n/i | [playbook #49](https://github.com/meetrevision/playbook/issues/49), [#228](https://github.com/meetrevision/playbook/issues/228) | Não confirmada |
| 13 | Win11Debloat (em Enterprise) | **Windows Hello/PIN/DISM com problemas** | Win 11 Enterprise, 2025-12 | [Win11Debloat #401](https://github.com/Raphire/Win11Debloat/issues/401) | Não confirmada |

### 3.3 Store, Xbox, contas, gaming

| # | Tweak / ação | O que quebrou | Build / data | Fonte | Causa |
|---|---|---|---|---|---|
| 14 | Atlas 0.5.0 (playbook) | **Instalar apps pela Store** (erro 0x80073CF9), Gaming Services não atualiza | 24H2/25H2, 2025-12 a 2026-11 | [#1556](https://github.com/Atlas-OS/Atlas/issues/1556) (139 comentários), [#1591](https://github.com/Atlas-OS/Atlas/issues/1591), [#1612](https://github.com/Atlas-OS/Atlas/issues/1612), [#1675](https://github.com/Atlas-OS/Atlas/issues/1675) | **Hipótese de usuário** em [#1763](https://github.com/Atlas-OS/Atlas/issues/1763): linhas órfãs no banco de implantação AppX; há PR de correção ([#1764](https://github.com/Atlas-OS/Atlas/issues/1764)). **Não confirmada pelos mantenedores na leitura.** |
| 15 | Atlas / Win11Debloat | Minecraft Bedrock/Xbox/Store não funcionam | n/i, 2026 | [r/AtlasOS](https://www.reddit.com/r/AtlasOS/comments/1rdsyyg/), [r/AtlasOS](https://www.reddit.com/r/AtlasOS/comments/1s2lb4g/) | Relatos (R) |
| 16 | Win11Debloat (modo Custom) | **Login em conta Microsoft/Xbox impossível** | "23H2 (acho)", 2026-03 | [Win11Debloat #537](https://github.com/Raphire/Win11Debloat/issues/537) | O dono não achou opção culpada; sugeriu reparo in-place — **não confirmada** |
| 17 | Win11Debloat | **Busca do Menu Iniciar** parou de funcionar; erro de permissão na inicialização | Win 11, 2025-10 | [Win11Debloat #361](https://github.com/Raphire/Win11Debloat/issues/361) (39 comentários; fechada "not planned") | Não confirmada |
| 18 | Atlas (clean install + 0.5.0) | **Ativação do Windows** falha (0x803F700F) | 25H2 (26200.7623), 2026-01 | [r/AtlasOS](https://www.reddit.com/r/AtlasOS/comments/1qifndn/) | Relato (R); alguns usuários sugeriram ferramentas de ativação — **a Carta proíbe; não documentar** |

### 3.4 Drivers, hardware, virtualização, dev

| # | Tweak / ação | O que quebrou | Build / data | Fonte | Causa |
|---|---|---|---|---|---|
| 19 | Atlas (n/i) | Instalador de **chipset AMD** trava (~64%) por semanas | 2026-03 | [Atlas #1618](https://github.com/Atlas-OS/Atlas/issues/1618) | **Mantenedor nega** (não instalam drivers); issue fechada como "completed" em 2026-05-13 — **correção aplicada não lida [não verificado]** |
| 20 | Atlas | **WSL falha** (`ERROR_PATH_NOT_FOUND`) após `wsl --install` | 2026-03 | [Atlas #1615](https://github.com/Atlas-OS/Atlas/issues/1615) (aberta) | Não confirmada; contribuidor pergunta por hardware e virtualização |
| 21 | Atlas | VirtualBox não cria VMs | n/i, 2025-01 | [Atlas #1327](https://github.com/Atlas-OS/Atlas/issues/1327) | Mantenedor fechou como "provavelmente não relacionado" |
| 22 | WinUtil, tweaks do laptop HP | **OMEN Gaming Hub não abre** | 2026-07 | [winutil #4872](https://github.com/ChrisTitusTech/winutil/issues/4872) | **Dono:** relacionado a WPBT (mecanismo do firmware OEM) |
| 23 | Win11Debloat | **Realtek Audio** não registra fones | n/i, 2024-06 | [Win11Debloat #78](https://github.com/Raphire/Win11Debloat/issues/78) | Título lido; causa **[não verificado]** |
| 24 | Atlas | **PATH sobrescrito** (cmd quebra) | 2024-04 | [Atlas #1076](https://github.com/Atlas-OS/Atlas/issues/1076) | Fechada "not planned"; primeiro caso foi Windows IoT Enterprise |

### 3.5 Telemetria/Explorer/UI

| # | Tweak / ação | O que quebrou | Build / data | Fonte | Causa |
|---|---|---|---|---|---|
| 25 | WinUtil "Telemetry – Disable" | **Explorer lento; pasta Downloads não carrega** | WinUtil 26.08.19, 2026-09 | [winutil #5088](https://github.com/ChrisTitusTech/winutil/issues/5088) | Fechada "not planned" por colaborador; **causa não conclusiva na leitura** |
| 26 | WinUtil, busca | **Windows Search parou** após tweaks | n/i, 2024-08 | [winutil #2541](https://github.com/ChrisTitusTech/winutil/issues/2541) | Não confirmada |
| 27 | WinUtil, preset Advanced (apps em segundo plano desativados) | **Overlay da Ferramenta de Captura** quebrado | n/i, 2025-06 | [winutil #3401](https://github.com/ChrisTitusTech/winutil/issues/3401) | Não confirmada |
| 28 | WinUtil, voltar ao menu Iniciar antigo | **Deixa de funcionar após KB5094126** | 2026-06 | [winutil #4687](https://github.com/ChrisTitusTech/winutil/issues/4687) | Windows Update alterou o comportamento; **causa técnica não lida** |
| 29 | WinUtil, escrever políticas no registro | Ajustes **não aparecem no gpedit** (sem armazenamento de política) | 2026-05 | [winutil #4532](https://github.com/ChrisTitusTech/winutil/issues/4532) | Limitação de método descrita no issue |
| 30 | WinUtil, preset que desativa IPv6 | Desativar IPv6 por padrão é considerado ruim | n/i | [winutil #3061](https://github.com/ChrisTitusTech/winutil/issues/3061) (18 reações) | Debate de boas práticas |
| 31 | Atlas Toolbox | **Copilot continua ativo** depois de desativado | 2026 | [Atlas #1757](https://github.com/Atlas-OS/Atlas/issues/1757) (aberta) | Não confirmada |
| 32 | Winhance (atualização do app) | Programas de inicialização deixam de iniciar; Menu Iniciar vazio | 2026-01 | [#377](https://github.com/memstechtips/Winhance/issues/377), [#285](https://github.com/memstechtips/Winhance/issues/285) | Causa não lida **[não verificado]** |

### 3.6 Bypass de requisitos / anticheat

| # | Tweak / ação | O que quebrou | Fonte | Causa |
|---|---|---|---|---|
| 33 | MicroWin: bypass de TPM/Secure Boot | **Anticheat Vanguard** quebra; só reinstalação "limpa" resolve | [winutil #2810](https://github.com/ChrisTitusTech/winutil/issues/2810) | Descrito pelo autor da issue; proposta: tornar opcional |
| 34 | ISOs modificadas em geral | Banimento/bloqueio em anticheat é temido | [r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/comments/1x4ojav/) | Pergunta de usuário (R) |

**Falso positivo útil para a suíte:** um erro EAC no Fortnite sob Atlas ([#1532](https://github.com/Atlas-OS/Atlas/issues/1532)) acabou sendo causado por perfil XMP agressivo — o mesmo erro ocorria no Windows normal. A suíte deve **comparar contra Windows stock na mesma VM/hardware** para não atribuir ao tweak o que é do ambiente.

### 3.7 Padrões que se repetem (sugestão de casos de teste)
(Julgamento da Lulu; a Beatrix decide o desenho final.)
1. **Windows Update ponta a ponta:** instalar a cumulativa do mês + atualização de recurso na build testada (24H2/25H2/26H2). Casos: #1098, #3651, NTLite #6006.
2. **Store + Xbox + Gaming Services:** instalar um app e um jogo da Store; abrir app Xbox. Casos: Atlas #1556/#1675.
3. **Explorer/Busca/Menu Iniciar/Downloads** após cada tweak de telemetria/serviço. Casos: #1250, #361, #2541, #5088.
4. **Conta Microsoft/Windows Hello/PIN.** Casos: #537, #401.
5. **WSL2 + Docker Desktop + VM (Hyper-V/VirtualBox).** Casos: Atlas #1615/#1327/#818.
6. **Driver installers** (chipset AMD/Intel, GPU, Realtek, OEM hub). Casos: #1618, #78, #4872.
7. **Anticheat** (Vanguard, EAC, BattlEye) com e sem bypass de TPM/Secure Boot. Caso: #2810.
8. **Reversão:** aplicar → desfazer → comparar estado com baseline (serviços, registro, componentes). Dor nº5 da rodada 1.
9. **Pós-feature-update:** os tweaks sobrevivem? ([FAQ do WinUtil](https://winutil.christitus.com/faq/): feature updates podem resetar tweaks.)
10. **Idempotência:** rodar duas vezes não muda o resultado (Microsoft usa esse critério — "Idempotent. CI-tested." — no [Windows Developer Config](https://github.com/microsoft/WindowsDeveloperConfig)).

---

## 4. Perfil DEV — o que devs pedem/precisam

**Limite da evidência:** não achei, nesta rodada, threads de Reddit de devs pedindo "um Windows pronto para dev" de forma direta. O que existe é (a) o que a Microsoft escolheu embutir, (b) dores recorrentes de WSL/Docker/Defender em issues e fóruns e (c) dados sobre preferência de SO. Tratar como **evidência indireta**.

### 4.1 Mercado/preferência
- **Stack Overflow 2025:** Windows é o SO primário mais usado entre desenvolvedores profissionais (~49,5% vs 32,9% macOS), segundo [Windows Latest](https://www.windowslatest.com/2026/09/22/microsoft-keeps-rebuilding-windows-for-developers-but-a-new-poll-puts-windows-at-just-12/) citando a pesquisa ([resultado oficial](https://survey.stackoverflow.co/2025/) — **valor não confirmado na página oficial por mim [não verificado]**).
- **Enquete do Pragmatic Engineer** (~4 mil respostas no X): macOS 61,6%, Linux 24,2%, Windows 12,8% — o próprio autor diz ser "bolha" de startups/Big Tech ([Windows Latest](https://www.windowslatest.com/2026/09/22/microsoft-keeps-rebuilding-windows-for-developers-but-a-new-poll-puts-windows-at-just-12/)). Motivo apontado: ambiente Unix e semelhança com produção (opinião do artigo).

### 4.2 Ferramentas e configurações que a Microsoft já embute (baseline que o DEV precisa igualar ou superar)
Fonte: [Windows Developer Config](https://github.com/microsoft/WindowsDeveloperConfig).
- **Ferramentas:** Windows Terminal, PowerShell 7, Git, GitHub CLI, Copilot CLI, VS Code, .NET SDK, Python + uv, Node LTS + nvm, Coreutils for Windows, Oh My Posh, PowerToys.
- **Ajustes:** tema escuro, **caminhos longos**, padrões do Explorer, Developer Mode, **Sudo**, widgets desligados, políticas do Edge, WSL + Ubuntu.
- **Perfis extras:** WSL Comfort, workloads de linguagem, AI tooling (GPU/PyTorch/Ollama).

### 4.3 Dores recorrentes
1. **WSL2: arquivos no lado errado ficam lentos.** A Microsoft recomenda guardar projetos no sistema de arquivos do Linux (`/home/...`) e não em `/mnt/c/...` ([docs WSL](https://learn.microsoft.com/windows/wsl/filesystems)); issues e posts mostram 10–20× de lentidão em `/mnt` ([WSL #4197](https://github.com/microsoft/WSL/issues/4197), [#9555](https://github.com/microsoft/WSL/issues/9555), [guia DEV.to](https://dev.to/alvarito1983/the-wsl2-guide-i-wish-i-had-4-gotchas-that-will-eat-your-afternoon-5aal) — números de relatos, não benchmark controlado).
2. **Docker Desktop:** consome RAM no lado Windows e perde integração com WSL; devs sugerem instalar o Docker Engine direto no WSL2 ([r/webdev](https://www.reddit.com/r/webdev/comments/1rkjjr3/), R). O Docker Desktop exige WSL2 ou Hyper-V habilitados ([fórum Docker](https://forums.docker.com/t/docker-desktop-vm-fails-to-start-hyper-v-hypervisor-not-running-despite-all-prerequisites/150088), [Microsoft Q&A](https://learn.microsoft.com/en-us/answers/a/12584331)) — **qualquer tweak que desligue Hyper-V/Virtual Machine Platform quebra o fluxo** (confirmado pela lógica das mensagens de erro; **teste direto com debloat não encontrado [não verificado]**).
3. **Defender e builds lentas:** a Microsoft lança o **Dev Drive** (volume ReFS) + **modo de desempenho do Defender** com "até 30% melhor tempo de build" — **número do fornecedor** ([blog Windows](https://blogs.windows.com/windowsdeveloper/2023/06/01/dev-drive-performance-security-and-control-for-developers/)). O modo só funciona em Dev Drive e usa verificação assíncrona (menos proteção) ([docs Defender](https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-endpoint-antivirus-performance-mode)); a Microsoft diz que o modo é **melhor que exclusões de pasta**, que "bloqueiam a verificação por completo" (mesma fonte). Dev Drive **não pode converter volume existente** ([docs](https://learn.microsoft.com/en-us/windows/dev-drive)). Um relato isolado diz que exclusões não ajudaram em build Node em WSL ([DEV.to](https://dev.to/kleeut/why-is-wsl2-so-slow-4n3i), anedota).
4. **Conflito com otimizadores:** WSL falhando no Atlas ([#1615](https://github.com/Atlas-OS/Atlas/issues/1615)), PATH sobrescrito ([#1076](https://github.com/Atlas-OS/Atlas/issues/1076)), VMs ([#1327](https://github.com/Atlas-OS/Atlas/issues/1327), [#818](https://github.com/Atlas-OS/Atlas/issues/818)).
5. **Quem vem do Linux/Mac:** quer Windows "sem conta Microsoft obrigatória, sem telemetria/Copilot" ([r/Windows11](https://www.reddit.com/r/Windows11/comments/1up2u83/), R) — o que o Win11Debloat/WinUtil/Winhance já entregam; o DEV pode combinar isso com a **configuração de dev**.

### 4.4 Implicações práticas para a edição DEV (inferências da Lulu — validar com Cid/Rikku/Beatrix)
- **Não mexer** em Hyper-V, Virtual Machine Platform, WSL, serviços de rede/SMB, Defender (exceto configurar **Dev Drive + modo de desempenho**).
- **Reusar** o `winget configure` da Microsoft como base do manifesto de ferramentas (MIT) e documentar o que o BigZ acrescenta (shell, privacidade, UI).
- **Guiar o usuário** para colocar repositórios no Dev Drive ou no sistema de arquivos do WSL (mensagem/ checklist na Toolbox).
- **Teste obrigatório de dev:** `wsl --install`, `docker run hello-world`, build de um projeto .NET/Node/Python em Dev Drive.

---

## 5. O que gamers aceitam como prova de desempenho

### 5.1 Ferramentas e métricas (padrão da comunidade)
- **Captura:** [PresentMon](https://github.com/GameTechDev/PresentMon) (Intel, MIT) coleta CPU/GPU/display frame durations em DirectX/Vulkan/OpenGL e gera CSV; [CapFrameX](https://github.com/CXWorld/CapFrameX) é a interface de análise sobre ele (gráficos, comparação, overlay) — v1.9.2, atualizado em 2026-11-21. NVIDIA FrameView e MSI Afterburner/RTSS também aparecem em guias ([Wccftech — como fazer benchmark com CapFrameX](https://wccftech.com/how-to-properly-benchmark-your-pc-games-using-capframex/)).
- **Métricas:** média de FPS **+ 1% e 0,1% lows** + gráfico de frametime. A Gamers Nexus lembra que os lows são médias dos piores frames e "ainda podem esconder problemas"; usa o gráfico de frametime para inspecionar ([GN, 2025](https://gamersnexus.net/gpus-gn-extras-cpus/problem-gpu-benchmarks-reality-vs-numbers-animation-error-methodology-white)). A GN também propõe "animation error" como métrica nova (**ainda não padrão**).
- **Variância:** múltiplas passadas, desvio-padrão dos lows, repetir se inconsistente ([GN "Bench Theory", 2018](https://gamersnexus.net/guides/3240-bench-theory-reliability-standard-deviation-game-benchmarks)) — **sem limite numérico de aceitação publicado que eu tenha achado**.
- **Boas práticas citadas:** aquecer o jogo e descartar a primeira passada; mesma cena/ações; desativar Reflex/Anti-Lag que atuam como limitador de FPS (Wccftech); capturar 30–60 s (regra prática de guia não autoritativo).
- **Documentação mínima de um guia "otimizado"** segundo discussão em r/OptimizedGaming: dispositivo/OS exato, TDP/perfil, resolução/upscaler/limite de FPS, **versão do driver**, rota/cena de teste, 1% lows, consistência de frametime, consumo ([r/OptimizedGaming](https://www.reddit.com/r/OptimizedGaming/comments/1w1haik/), R). Também: manter evidência verificável (capturas hospedadas de forma durável).

### 5.2 Evidência existente sobre ganho de "OS otimizado"
| Teste | Resultado | Fonte | Qualidade |
|---|---|---|---|
| CS2, Dust II, CapFrameX, 3 passadas, Stock W11 vs FSOS-X vs Atlas | Atlas **teve o maior 1% low (≈321 vs ≈275 FPS, +16,7%)** mas **a menor média**; processos: stock 147, Atlas 96 | [post no X](https://x.com/ThourCS2/status/2081016131889070318) | Criador individual; hardware/versões completos **não verificados** |
| Rainbow Six Siege, benchmark integrado | Atlas e stock **praticamente idênticos** (≈444 FPS; lows 403 vs 401,5) | [TechTeamGB](https://techteamgb.co.uk/2024/01/12/custom-windows-os-claims-lower-latency-and-more-performance-atlas-os/) | Mídia especializada; teste de 2024 |
| Uso geral/gaming | Sem ganho significativo de jogo; menor uso de CPU/RAM em repouso | [XDA](https://www.xda-developers.com/tried-kinder-windows-experience-atlasos-how-should-be/) | Review |
| Fortnite | Média parecida, **0,1% lows e frame pacing melhores** | [MakeUseOf](https://www.makeuseof.com/windows-11-mod-recommend-to-every-gamer/) | Review subjetivo |
| Alegação do próprio Atlas | "FPS de 217 para 365" — considerada irreal por revisores | [resumo da busca](https://gamingpcguru.com/atlasos-review-safe/) | **Não verificado** |
| Reddit (CPU antigo vs moderno) | Ganho em Ryzen 2600X; "mesmo FPS" em 7900X (comentários de YouTube) | [vídeo](https://www.youtube.com/watch?v=mXSTtlOYogA) (só comentários lidos) | Anedota |

**Conclusão (julgamento da Lulu):** em CPU/GPU modernos o ganho de média é pequeno; o que mais aparece é **melhoria (ou piora) nos 1% lows e menos processos em repouso**, e depende de hardware e jogo. A comunidade é cética e pede metodologia ([r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/comments/1qf3xj9/): "ganho de ~2 FPS não compensa risco").

### 5.3 O que importa mais que "debloat" para FPS
- **VBS/HVCI (segurança por virtualização):** Tom's Hardware mediu ~10% de ganho médio e até 15% nos 1% lows ao **desligar o VBS** numa RTX 4090; em CPU 11ª geração, ~5% ([Tom's Hardware](https://www.tomshardware.com/news/windows-vbs-harms-performance-rtx-4090)); TechSpot viu 1% lows caírem 29% em um jogo em CPU antiga ([TechSpot](https://www.techspot.com/review/2358-intel-alder-lake-windows-11-benchmark/)); PCWorld não viu queda drástica em 2021 ([PCWorld](https://www.pcworld.com/article/541137/tested-does-windows-11-nuke-gaming-performance.html)). **Testes de 2021–2023; não aplicar a builds atuais sem retestar.** Relevante: o **perfil Full Performance deve tratar VBS como decisão explícita do usuário** (segurança vs desempenho), não escondida.
- **Windows 11 vs 10:** reviews recentes mostram diferença de poucos % no máximo, com Windows 11 25H2 à frente em alguns ([TechRadar](https://www.techradar.com/computing/windows/windows-11-25h2-edges-ahead-of-windows-10-in-gaming-performance-testing-proves-newer-os-is-faster-but-theres-an-elephant-sized-bsod-in-the-room), [Tom's Hardware](https://www.tomshardware.com/news/graphics-performance-win10-vs-win11), [TechSpot](https://www.techspot.com/article/3081-windows-11-vs-windows-10-gaming/)). O resumo do Hardware Unboxed (≈5%, até ≈10%) vem de [fórum](https://neogaf.com/threads/hardware-unboxed-windows-11-25h2-vs-windows-10.1692585/) — **não verificado no vídeo original**.
- **Agendamento de threads e 1% lows:** discussão em [r/OptimizedGaming](https://www.reddit.com/r/OptimizedGaming/comments/1wmqikd/) (98 pontos, 40 comentários, R) afirma que afinidade por processo ≠ colocação por thread, e que isso afeta frametime; o autor é desenvolvedor de uma ferramenta própria (CoreX) — **conflito de interesse; não verificado**.

### 5.4 Metodologia sugerida para o BigZ OS (proposta da Lulu)
1. **VM não serve para FPS.** Medir em hardware real; registrar CPU, GPU, RAM/XMP, driver, build do Windows, plano de energia, VBS/HVCI, HAGS, Game Mode.
2. **Comparar 3 estados:** Windows stock recém-instalado, Windows stock + Win11Debloat (baseline "barato") e cada edição BigZ.
3. **Captura com PresentMon/CapFrameX**, ≥3 passadas por cenário (+ aquecimento), cena fixa; publicar CSV bruto e script de análise.
4. **Reportar:** média, 1% e 0,1% lows, desvio-padrão, frametime, uso de RAM/processos em repouso, tempo de boot.
5. **Publicar também onde NÃO há ganho.** Em comunidade cética, honestidade vira credibilidade.
6. Aviso explícito sobre trocas de segurança (VBS, mitigações de CPU): a comunidade do Atlas aconselha manter mitigações em CPUs modernas ([r/AtlasOS](https://www.reddit.com/r/AtlasOS/comments/1quk2ux/), R).

---

## 6. Implicações para o posicionamento (resumo para o plano consolidado)
- **Transparência sobre o que muda** é pedida explicitamente (WinUtil [#2718](https://github.com/ChrisTitusTech/winutil/discussions/2718)) e inexistente nos concorrentes: manter como pilar.
- **Reversão por tweak** (O&O faz; Atlas não) e **teste em build** (NTLite/ReviOS/Atlas sofrem) são diferenciais viáveis.
- **DEV:** integrar o Windows Developer Config, não competir com ele; diferenciar por privacidade/UI/Dev Drive/guard-rails.
- **Full Performance:** publicar benchmarks reprodutíveis; tornar VBS/mitigações escolhas explícitas; modo "gamer com Xbox/Store" e "purista".
- **Anti-padrões a evitar (com fonte):** pedir exclusão de `C:` no Defender ([Talon](https://github.com/ravendevteam/talon)); binários sem origem ([tiny11 #47](https://github.com/ntdevlabs/tiny11builder/issues/47)); desativar Update/Defender por padrão ([Ghost Spectre](https://candid.technology/ghost-spectre-windows-11/)); repositório sem licença ([tiny11](https://github.com/ntdevlabs/tiny11builder)).
- **Risco de dependência:** AME Wizard/Atlas dependem de poucos mantenedores ([#1252](https://github.com/orgs/Atlas-OS/discussions/1252)); preferir motor próprio e documentação aberta (decisão do Cid).

## 7. O que continua sem confirmação
- ElevenForum, My Digital Life e TenForums (verificação anti-bot): **não lidos**.
- Conteúdo das respostas nas Discussions do Atlas (só títulos); causa de várias issues do §3 (marcadas "não confirmada").
- O&O ShutUp10++ (FAQ completo e preço Premium), ReviOS FAQ (404 na leitura direta), licença do Winhance, **qual é a publicação "oficial" do Tiny11 no archive.org**.
- Resultado do Stack Overflow 2025 na fonte oficial; vídeo do Hardware Unboxed (só resumo de terceiros).
- Reddit: amostra pequena e traduzida; nenhuma thread de dev "pedindo Windows pronto para dev" localizada.
- Limite de API do GitHub foi atingido ao final da coleta; alguns títulos de issue (Winhance, ReviOS) foram lidos antes disso, **sem corpo/comentários**.
