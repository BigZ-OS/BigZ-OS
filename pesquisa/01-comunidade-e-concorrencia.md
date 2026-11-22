# 01 — Comunidade e Concorrência (Pesquisa & Inteligência)

> Autora: Lulu (Pesquisa & Inteligência) · Data da coleta: 2026-11-21 · Para: Auron (Diretoria)
> Regra: toda afirmação tem link. O que não foi confirmado em fonte primária está marcado **[não verificado]**.
> Nenhuma conta foi criada e nada foi postado: só leitura de páginas públicas e da API pública do GitHub.

## 0. Resumo executivo

1. O terreno é dominado por **três famílias**: (a) *playbooks/ISOs modificadas* (Atlas, ReviOS, Ghost Spectre, Tiny11), (b) *toolboxes/scripts pós-instalação* (WinUtil, Win11Debloat, Sophia, Winhance, Optimizer, privacy.sexy, O&O ShutUp10++), (c) *editor de imagem pago* (NTLite).
2. **O modelo legal do BigZ OS já é o praticado pelo Atlas**: o Atlas declara que não distribui ISO modificada porque "viola os termos da Microsoft" e "não há como verificar que ISOs de terceiros não são maliciosas" ([Atlas FAQ — ISO files](https://docs.atlasos.net/faq/install-faq/atlas-iso-files/)). O Ghost Spectre é o único grande que distribui ISO pronta (ver §2 e ressalvas).
3. **A maior dor recorrente** nos modificados é *"quebrou algo e não sei por quê"* (Microsoft Store/Xbox, Windows Update, drivers, Explorer) e **a incerteza de confiança** (o que foi removido? tem malware? dá para voltar?). Isso aparece tanto em issues do GitHub quanto no Reddit (§3).
4. A comunidade geral (r/Windows11, r/pcmasterrace) é **cética com ISOs/otimizadores agressivos** e recomenda "instalação limpa + ferramenta open source auditável (WinUtil/Win11Debloat) + nada de ISO modificada". O BigZ OS precisa vencer essa objeção com transparência e reversibilidade.
5. Maior oportunidade: **builder transparente com "plano de mudanças" legível, perfil por edição, reversão real, e testes automatizados por build do Windows** — nenhum concorrente combina as quatro coisas (§5).

---

## 1. Ficha dos concorrentes e referências

Legenda de confiança da fonte: **P** = fonte primária (site/repo/docs oficial); **S** = secundária (imprensa/fóruns); **R** = relato de usuário (anedota).

### 1.1 Playbooks e ISOs modificadas

#### Atlas OS (AtlasOS)
- **O que faz / como:** "modificação transparente e leve do Windows" para desempenho, privacidade e usabilidade ([README](https://github.com/Atlas-OS/Atlas), P). É um **playbook** aplicado pelo **AME Wizard** sobre um Windows oficial; não há ISO do Atlas ([FAQ](https://docs.atlasos.net/faq/install-faq/atlas-iso-files/), P). Inclui uma pasta/Toolbox de configuração pós-instalação ([docs](https://docs.atlasos.net/), P).
- **Modelo:** grátis, open source (playbook GPL-3.0; docs CC-BY-SA-4.0) — [repo](https://github.com/Atlas-OS/Atlas), [docs](https://docs.atlasos.net/). ~22 mil estrelas (API do GitHub, consultada em 2026-11-21).
- **Pontos fortes:** transparência (código aberto), Defender/Windows Update/UAC/Core Isolation suportados nas versões novas, configuração de segurança alternável ([FAQ segurança](https://docs.atlasos.net/faq/general-faq/atlas-and-security/), P). Comunidade grande (Discord, Reddit).
- **Críticas recorrentes:**
  - Quebra de **Microsoft Store/Xbox/Gaming Services** (erro 0x80073CF9): issue com 139 comentários ([#1556](https://github.com/Atlas-OS/Atlas/issues/1556)), outra mais recente aberta ([#1763](https://github.com/Atlas-OS/Atlas/issues/1763), [#1675](https://github.com/Atlas-OS/Atlas/issues/1675)); relatos em [r/AtlasOS](https://www.reddit.com/r/AtlasOS/comments/1rdsyyg/) e [r/AtlasOS](https://www.reddit.com/r/AtlasOS/comments/1s2lb4g/) (R; textos traduzidos automaticamente pelo navegador).
  - **Instalador de chipset AMD** travando ([#1618](https://github.com/Atlas-OS/Atlas/issues/1618)); mantenedor nega relação ("não instalamos drivers") — causa **não resolvida em nossa leitura**.
  - **Upgrade de versão do Windows não suportado**; só reinstalação limpa ([FAQ](https://docs.atlasos.net/faq/general-faq/upgrading-windows-version/), P).
  - **Reverter é "reinstalar"**; o Atlas desativa o "Redefinir este PC" ([FAQ](https://docs.atlasos.net/faq/install-faq/reverting-atlas/), P).
  - Recursos **removidos permanentemente** (ex.: Smart App Control) ([FAQ](https://docs.atlasos.net/faq/install-faq/removed-features/), P).
  - Problemas de ativação/Windows Update reportados em [r/AtlasOS](https://www.reddit.com/r/AtlasOS/comments/1qifndn/) (R).
  - Toolbox com falha: Copilot continua ativo após desativar pelo Toolbox ([#1757](https://github.com/Atlas-OS/Atlas/issues/1757), aberta).
  - Suporte lento a novas builds: pedidos para 26H2 ([#1743](https://github.com/Atlas-OS/Atlas/issues/1743), a issue mais votada, 21 reações; [#1739](https://github.com/Atlas-OS/Atlas/issues/1739)).
- **Polêmicas de segurança/confiança:** versões antigas (<0.3) removiam Defender/Update e a própria equipe as chama de inseguras ([FAQ](https://docs.atlasos.net/faq/general-faq/atlas-and-security/), P). A **GUI do AME Wizard é fechada**, mas o backend (TrustedUninstaller) é MIT ([FAQ](https://docs.atlasos.net/faq/general-faq/atlas-and-security/), P). Existe crítica de terceiros de que partes do AME são fechadas por "motivos monetários e de segurança" ([post de Chris Titus](https://christitus.com/ame-wizard-the-future-of-debloat/) — apareceu na busca, **conteúdo não lido na íntegra [não verificado]**). Pedido histórico: "manter Defender" ([#704](https://github.com/Atlas-OS/Atlas/issues/704), 15 reações). Um debate sobre o Atlas no Windows Central: [Should you debloat Windows 11?](https://www.windowscentral.com/microsoft/windows-11/should-you-debloat-windows-11-the-custom-iso-scene-is-bigger-than-you-think) (S).

#### AME Wizard / Ameliorated (infra do Atlas e ReviOS)
- **O que é:** ferramenta que aplica "Playbooks" (YAML) para modificar o Windows em execução ou injetar em ISO; "Atlas", "ReviOS", "Privacy+" e "AME 10" são playbooks verificados ([ameliorated.io](https://ameliorated.io/), P). O site descreve o AME Beta como app C#/.NET e diz que "a maior parte do software é MIT" — implica que **nem tudo é aberto** (**[não verificado]** o que exatamente é fechado).
- **Modelo:** grátis. **Ponto de atenção:** dependência de um terceiro como motor de instalação — risco de continuidade/confiança para qualquer playbook.

#### ReviOS (Revision)
- **O que faz:** playbook "conservador" via AME Wizard + "Revision Tool"; promete desempenho, privacidade, remoção de bloatware, "100% open source" e "500K+ downloads" ([revi.cc](https://revi.cc/), P — números são autodeclarados).
- **Modelo:** grátis, doações. **Críticas:** em [r/OptimizedGaming](https://www.reddit.com/r/OptimizedGaming/comments/1r14g7b/), usuários dizem que o ReviOS "praticamente não mostra ganho de desempenho" e que o Windows 11 puro é igual ou melhor (R). Pesquisa específica de controvérsias de segurança do ReviOS **não retornou fonte relevante [não verificado]**.

#### Ghost Spectre
- **O que faz:** ISOs Windows 10/11 já modificadas ("Superlite", "Lite", "Pro", LTSC IoT), com "Ghost Toolbox" vendida/distribuída no Gumroad ([página do Ghost Toolbox](https://ghostspectre.gumroad.com/l/GhostToolbox), P — só diz "updated may 2023"; preço/licença **[não verificado]**). Subreddit pequeno ([r/GhostSpectre](https://www.reddit.com/r/GhostSpectre/), ~1 mil membros, P do Reddit).
- **Como:** **distribui ISO pronta** (modelo que o BigZ OS **não** pode seguir — Carta, regra 1). Segundo imprensa, a Superlite remove Defender/Segurança do Windows, notificações de UAC e requisito de TPM, e "pausa atualizações até 2077" ([Candid Technology, 2023](https://candid.technology/ghost-spectre-windows-11/), S).
- **Críticas recorrentes:** falta de verificação/atualizações de segurança, risco de licença, "pode ter malware" ([Candid](https://candid.technology/ghost-spectre-windows-11/), S). Em [ElevenForum](https://www.elevenforum.com/t/ghost-spectre.48754/page-2) há relatos de conflitos de driver, erros de `sfc /scannow` e um usuário afirmando que o Malwarebytes marcou 8 arquivos (R, **anedótico, não verificado**; a página bloqueou nossa leitura direta, usamos o trecho de busca).
- **Reddit:** "é seguro para uso diário?" — respostas mistas: um usuário diz 3 anos sem problema mas já viu Malwarebytes remover arquivos de sistema; outro alerta sobre risco de banimento por anticheat ([r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/comments/1x4ojav/), R). Outro comentário: "qualquer cópia customizada do Windows tem problemas… você não sabe o que colocam nisso."
- **Polêmica:** artigos tipo "Ghost Spectre reduz 78% de malware" citando "CyberShield Labs" parecem **SEO/promocionais sem fonte independente** ([resultado de busca](https://views.washingtonian.com/vie/ghost-spectre-windows-11-the-cyber-sleuth-powering-next-gen-device-security)) — tratar como **não confiável**.

#### Tiny11 / tiny11builder (NTDEV)
- **O que faz:** gera uma ISO menor a partir da ISO oficial do usuário. A versão atual é um **app nativo** (Tiny11Builder.exe) com modos *Tiny11* (mantém Update/Defender/recuperação), *Custom* (receitas) e *Core* ("só para VMs de teste: remove update/recuperação e desativa Defender") ([README](https://github.com/ntdevlabs/tiny11builder), P). O repositório também mantém scripts `tiny11maker.ps1` e `tiny11Coremaker.ps1`.
- **Modelo:** grátis; ~22 mil estrelas; **o repositório não declara licença** (campo vazio na API do GitHub, consulta em 2026-11-21) — ponto de atenção de confiança/reuso.
- **Pontos fortes:** suporte a 25H2 e ARM64 ([Tom's Hardware](https://www.tomshardware.com/software/operating-systems/custom-windows-11-builder-axes-microsofts-ai-features-whack-a-moling-copilot-outlook-and-teams-new-tiny11-builder-release-should-be-windows-11-25h2-ready), S), remoção de Copilot, ISO oficial do usuário.
- **Críticas recorrentes:** erros de script ao sair novas builds ([#310](https://github.com/ntdevlabs/tiny11builder/issues/310), [#484](https://github.com/ntdevlabs/tiny11builder/issues/484), [#263](https://github.com/ntdevlabs/tiny11builder/issues/263)); pedido de **suporte Linux** ([#208](https://github.com/ntdevlabs/tiny11builder/issues/208), 16 reações); pedido de remover Copilot/Recall ([#200](https://github.com/ntdevlabs/tiny11builder/issues/200)); instruções confusas ([#549](https://github.com/ntdevlabs/tiny11builder/issues/549)); falha em VirtualBox ([#442](https://github.com/ntdevlabs/tiny11builder/issues/442)); Core não é atualizável ([README](https://github.com/ntdevlabs/tiny11builder), P).
- **Polêmica de confiança:** em 2023 um usuário apontou que o `oscdimg.exe` do repo **não era o original da Microsoft**; o autor disse que veio do MSMG Toolkit e depois **substituiu pelo do ADK** ([#47](https://github.com/ntdevlabs/tiny11builder/issues/47)). Lição: **nunca embutir binários de terceiros sem origem verificável**.
- **Reddit:** conselho comum para Tiny10: "não, por segurança… use NTLite na sua própria ISO" ([r/Windows10](https://www.reddit.com/r/Windows10/comments/1xhwspw/), R, 71 pontos/54 comentários).

### 1.2 Toolboxes e scripts pós-instalação

#### Chris Titus Tech WinUtil
- **O que faz:** GUI em PowerShell: instalar apps, tweaks, configurações, atualizações e **MicroWin** (cria ISO enxuta). Executa com `irm … | iex`; fecha sem instalar nada ([FAQ](https://winutil.christitus.com/faq/), P). Windows 10 não é mais suportado ([FAQ](https://winutil.christitus.com/faq/), P).
- **Modelo:** grátis, MIT; ~66 mil estrelas ([repo](https://github.com/ChrisTitusTech/winutil)).
- **Pontos fortes:** catálogo de apps, comunidade enorme, "o único em que confio" segundo comentário em [r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/comments/1te3qg5/) (R).
- **Críticas recorrentes:** ajustes de serviços que quebram coisas — Explorer travando após MicroWin por mexer em serviços ([#1250](https://github.com/ChrisTitusTech/winutil/issues/1250), corrigido pelo dono); **Windows Update quebrado** após MicroWin ([#3214](https://github.com/ChrisTitusTech/winutil/issues/3214), [#3651](https://github.com/ChrisTitusTech/winutil/issues/3651)); toggles "Customize Preference" quebrados ([#3189](https://github.com/ChrisTitusTech/winutil/issues/3189), [#3736](https://github.com/ChrisTitusTech/winutil/issues/3736)); presets que desativam IPv6 por padrão ([#3061](https://github.com/ChrisTitusTech/winutil/issues/3061), 18 reações); **bypass de TPM/Secure Boot do MicroWin deveria ser opcional** porque quebra anticheat tipo Vanguard ([#2810](https://github.com/ChrisTitusTech/winutil/issues/2810)); instalação do Chocolatey sem consentimento ([#1118](https://github.com/ChrisTitusTech/winutil/issues/1118)).
- **Confiança:** execução via `irm | iex` gera alertas de antivírus ([#1742](https://github.com/ChrisTitusTech/winutil/issues/1742)). O próprio FAQ pede restore point e "entender os tweaks".

#### Win11Debloat (Raphire)
- **O que faz:** script PowerShell que remove apps pré-instalados, desliga telemetria/anúncios/IA (Copilot, Recall), restaura menu de contexto clássico; modo Sysprep/Audit, CLI, exportar/importar configurações ([README](https://github.com/Raphire/Win11Debloat), P).
- **Modelo:** grátis, MIT, ~63 mil estrelas, doação Ko-fi.
- **Pontos fortes:** simples, reversível na maior parte, muito recomendado no Reddit ([r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/comments/1qf3xj9/), R).
- **Críticas:** busca do Menu Iniciar quebrada após rodar ([#361](https://github.com/Raphire/Win11Debloat/issues/361)); impossibilidade de logar na conta Microsoft/Xbox ([#537](https://github.com/Raphire/Win11Debloat/issues/537), sem causa confirmada); Windows Hello/PIN no Enterprise ([#401](https://github.com/Raphire/Win11Debloat/issues/401)); pedidos de GUI ([#122](https://github.com/Raphire/Win11Debloat/issues/122)). O README avisa "use por sua conta e risco".

#### Winhance (memstechtips)
- App C# para debloat/otimização/customização; ~15 mil estrelas; licença marcada como `NOASSERTION` na API (**licença a verificar**) ([repo](https://github.com/memstechtips/Winhance), P). Citado no Reddit como alternativa ao WinUtil ([r/AtlasOS](https://www.reddit.com/r/AtlasOS/comments/1s2lb4g/), R).

#### Sophia Script (farag2)
- Módulo PowerShell com 150+ funções para Windows 10/11 (privacidade, UI, UWP, etc.) ([Windows Central](https://www.windowscentral.com/microsoft/windows-11/how-to-fine-tune-your-pc-with-the-sophia-script-for-windows-11), S); MIT, ~10 mil estrelas, 0 issues abertas, commit 2026-11-20 ([repo](https://github.com/farag2/Sophia-Script-for-Windows)). Há GUI separada (SophiApp) ([Guiding Tech](https://www.guidingtech.com/what-is-sophia-script-and-how-can-it-help-streamline-windows-11/), S). Crítica: curva de aprendizado (script via parâmetros).

#### privacy.sexy
- Gera scripts de privacidade (Windows/macOS/Linux) a partir de um catálogo; app web e desktop; **cada ação é visível**; reverter é um recurso anunciado ([README](https://github.com/undergroundwires/privacy.sexy), P). AGPL-3.0; ~6 mil estrelas; **251 issues abertas e último push em 2026-02-13** (API do GitHub) → sinal de manutenção reduzida. Crítica: poucas explicações para iniciantes ([gHacks](https://www.ghacks.net/?p=200975), S).

#### O&O ShutUp10++
- Antispy gratuito (freeware, fechado) para Win 10/11 ([O&O](https://www.oo-software.com/en/shutup10), P). Pontos fortes: marca estabelecida, perfis recomendados (**[não verificado]** nesta pesquisa — não lemos a página de recursos). Limite: só privacidade, **código fechado**.

#### Optimizer (hellzerg)
- Utilitário de privacidade/segurança/tweaks com 24 idiomas, desativa serviços, telemetria, Copilot, **"parar atualizações automáticas"**, editor de hosts, etc. ([README](https://github.com/hellzerg/optimizer), P). GPL-3.0; ~18 mil estrelas; 88 issues abertas. Críticas nas issues: "não abre" ([#383](https://github.com/hellzerg/optimizer/issues/383), [#430](https://github.com/hellzerg/optimizer/issues/430)), lentidão no boot ([#197](https://github.com/hellzerg/optimizer/issues/197)), "apagou pastas sem permissão" ([#63](https://github.com/hellzerg/optimizer/issues/63)). Binário `.exe` — o BigZ OS não deve repetir esse modelo opaco.

#### Talon (Raven Dev Team)
- "Debloat em 2 cliques" para Windows 11; **integra motores de terceiros** (WinUtil, Win11Debloat) ([BetaNews](https://betanews.com/2025/02/14/no-more-bloat-talon-completely-fixes-microsoft-windows-11-in-just-two-clicks), S). BSD-3-Clause, ~2 mil estrelas, último push 2026-09-26 ([repo](https://github.com/ravendevteam/talon)). Aviso da imprensa: antivírus tende a sinalizar a ferramenta ([BetaNews](https://betanews.com/2025/02/14/no-more-bloat-talon-completely-fixes-microsoft-windows-11-in-just-two-clicks), S).

### 1.3 Editores de imagem

#### NTLite
- **O que faz:** edita ISO/WIM/ESD ou o Windows em execução: remove componentes, integra updates/drivers, automatiza instalação, salva presets; também baixa ISO oficial dentro do app ([features](https://www.ntlite.com/features/), [download](https://www.ntlite.com/download/), P).
- **Modelo:** **freemium pago**: grátis para uso pessoal com recursos limitados; licenças perpétuas **Home €40, Professional €90, Business €250** (+IVA) com 1 ano de novidades ([preços](https://www.ntlite.com/pricing/), P). Remoção profunda e várias funções são "premium".
- **Pontos fortes:** o mais poderoso e maduro; recomendado em fóruns como alternativa a ISOs prontas ([r/Windows10](https://www.reddit.com/r/Windows10/comments/1xhwspw/), R). **Fraqueza:** fechado, pago, curva técnica alta.

### 1.4 Outras referências
- **Unattend Generator (schneegans.de):** gera `autounattend.xml` para 10/11 incl. 24H2/25H2/26H2, grátis, com doações; comentário no Reddit: "basta usar o unattend-generator… não precisa ISO customizada" ([site](https://schneegans.de/windows/unattend-generator/), P; [r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/comments/1qf3xj9/), R). **Concorrente indireto forte e potencial componente.**
- **LTSC/IoT Enterprise e edição Education** citados como alternativas "limpas" por usuários ([r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/comments/1te3qg5/), [r/buildapc](https://www.reddit.com/r/buildapc/comments/1qwb2k4/), R). Atenção: licenciamento — **[não verificado]**; encaminhar à Beatrix.
- **MSMG Toolkit:** citado pelo autor do Tiny11 como origem do `oscdimg` ([#47](https://github.com/ntdevlabs/tiny11builder/issues/47)); não pesquisado em profundidade **[não verificado]**.

### 1.5 Tabela comparativa

| Projeto | Entrega | Modelo | Licença/abertura | Distribui ISO? | Reversível? | Principal crítica | Fonte-chave |
|---|---|---|---|---|---|---|---|
| **Atlas OS** | Playbook (AME Wizard) + Toolbox | Grátis | GPL-3.0; GUI do AME fechada, backend MIT | Não | Só reinstalando | Store/Xbox/Update quebram; upgrade não suportado | [FAQ](https://docs.atlasos.net/faq/install-faq/reverting-atlas/) |
| **ReviOS** | Playbook (AME) + Revision Tool | Grátis/doação | "100% open source" (autodeclarado) | Não (injeção em ISO oficial) | **[não verificado]** | Ganho de desempenho questionado | [revi.cc](https://revi.cc/) |
| **Ghost Spectre** | **ISO pronta** + Ghost Toolbox | Grátis/Gumroad (**[não verificado]**) | Fechado | **Sim** | Não | Confiança, sem updates de segurança, anticheat | [Candid](https://candid.technology/ghost-spectre-windows-11/) |
| **Tiny11 Builder** | App/scripts que geram ISO | Grátis | **Sem licença declarada** | Não | Não (cria nova ISO) | Quebra com novas builds; Core não atualiza | [README](https://github.com/ntdevlabs/tiny11builder) |
| **WinUtil** | Script GUI + MicroWin | Grátis | MIT | Não | Parcial (tweaks "undo") | Tweaks de serviço/Update quebram | [FAQ](https://winutil.christitus.com/faq/) |
| **Win11Debloat** | Script PowerShell | Grátis (Ko-fi) | MIT | Não | Maior parte | Busca/Conta MS quebram em alguns casos | [README](https://github.com/Raphire/Win11Debloat) |
| **Winhance** | App C# | Grátis | `NOASSERTION` | Não | **[não verificado]** | **[não verificado]** | [repo](https://github.com/memstechtips/Winhance) |
| **Sophia Script** | Módulo PowerShell | Grátis | MIT | Não | Funções de reversão | Curva de aprendizado | [repo](https://github.com/farag2/Sophia-Script-for-Windows) |
| **privacy.sexy** | Gerador de scripts | Grátis | AGPL-3.0 | Não | Sim (anunciado) | Pouca explicação; manutenção lenta | [README](https://github.com/undergroundwires/privacy.sexy) |
| **O&O ShutUp10++** | App | Freeware | **Fechado** | Não | Sim (perfis) **[não verificado]** | Só privacidade | [O&O](https://www.oo-software.com/en/shutup10) |
| **Optimizer** | App .exe | Grátis | GPL-3.0 | Não | Parcial | Não abre/lento; "apagou pastas" | [repo](https://github.com/hellzerg/optimizer) |
| **Talon** | App (agrega motores) | Grátis | BSD-3 | Não | **[não verificado]** | Antivírus sinaliza | [BetaNews](https://betanews.com/2025/02/14/no-more-bloat-talon-completely-fixes-microsoft-windows-11-in-just-two-clicks) |
| **NTLite** | Editor de imagem | **Pago** (€40–250) / free limitado | Fechado | Não | Reedição de imagem | Preço; curva técnica | [Preços](https://www.ntlite.com/pricing/) |

Estrelas e atividade (API pública do GitHub, 2026-11-21): WinUtil ~66,5 mil · Win11Debloat ~63,5 mil · Tiny11 ~22,4 mil · Atlas ~22,2 mil · Optimizer ~18,3 mil · Winhance ~15 mil · Sophia ~10 mil · privacy.sexy ~6,2 mil · Talon ~2 mil.

---

## 2. Vozes da comunidade (síntese)

**Metodologia e limites**
- GitHub: issues mais comentadas e mais votadas via API pública (Atlas, WinUtil, Win11Debloat, tiny11builder, Optimizer).
- Reddit: leitura de páginas públicas no navegador, sem login (r/AtlasOS, r/pcmasterrace, r/Windows11, r/buildapc, r/OptimizedGaming, r/Windows10, r/sysadmin). **O navegador traduziu os textos para português automaticamente; as citações abaixo são paráfrases da tradução** — conferir o original antes de citar literalmente. A API/JSON do Reddit devolveu 403 e a busca web não indexa reddit.com; amostra **pequena e não estatística**.
- Não consegui ler: ElevenForum (bloqueio Cloudflare), My Digital Life, fórum do NTLite, TenForums. **[lacuna — próxima rodada]**.

**O que os usuários de Windows padrão reclamam**
- Exigência de conta Microsoft/internet na instalação ("tive que usar um truque") — [r/Windows11](https://www.reddit.com/r/Windows11/comments/1up2u83/) (115 pontos, R).
- Telemetria, Copilot, atualizações forçadas: "sempre 'Telemetry, Copilot, Updates'" — mesmo thread acima. Fatos externos: o presidente do Windows admitiu "muito trabalho a fazer" após o backlash da IA ([Windows Central](https://www.windowscentral.com/microsoft/windows-11/windows-president-addresses-current-state-of-windows-11-after-ai-backlash-we-know-we-have-a-lot-of-work-to-do), S) e a Microsoft publicou "Our commitment to Windows quality" em 2026-03-20, prometendo reduzir pontos de entrada do Copilot ([resumo no Yahoo/Tech](https://tech.yahoo.com/ai/copilot/articles/less-copilot-more-reliability-microsoft-214944736.html), S; **texto original da Microsoft não verificado**).
- Interface inconsistente (Configurações vs Painel de Controle; GUI quebrada em cima de ferramentas que funcionam): [r/sysadmin](https://www.reddit.com/r/sysadmin/comments/1pfx0mp/) (1.441 pontos, 376 comentários, R).
- Usuários que "só querem jogar em paz" voltam do Linux ao Windows, mas querem controle de privacidade ([r/Windows11](https://www.reddit.com/r/Windows11/comments/1xg1g0s/), 305 pontos, R).

**O que os usuários pedem das ferramentas**
- "Instalação limpa + ferramenta confiável + sem ISO de terceiros" é a recomendação dominante ([r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/comments/1te3qg5/), [r/Windows11](https://www.reddit.com/r/Windows11/comments/1xmwl0h/), R).
- Manter Defender/Update/Store/Xbox funcionando (Atlas [#704](https://github.com/Atlas-OS/Atlas/issues/704), [r/AtlasOS](https://www.reddit.com/r/AtlasOS/comments/1s2lb4g/)).
- Suporte rápido a builds novas (Atlas 26H2 [#1743](https://github.com/Atlas-OS/Atlas/issues/1743); Tiny11 25H2 [#462](https://github.com/ntdevlabs/tiny11builder/issues/462)).
- Remover Copilot/Recall ([tiny11 #200](https://github.com/ntdevlabs/tiny11builder/issues/200); [Win11Debloat README](https://github.com/Raphire/Win11Debloat)).
- Builder que rode em **Linux** ([tiny11 #208](https://github.com/ntdevlabs/tiny11builder/issues/208)).
- GUI ([Win11Debloat #122](https://github.com/Raphire/Win11Debloat/issues/122)) e opções **granulares/toggleáveis** ([WinUtil #2810](https://github.com/ChrisTitusTech/winutil/issues/2810)).
- Evidência de desempenho reprodutível: pedido por "evidências mínimas" em guias ([r/OptimizedGaming](https://www.reddit.com/r/OptimizedGaming/comments/1w1haik/), R) e ceticismo sobre FPS: "só 2 FPS" ([r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/comments/1qf3xj9/), 46 pontos/133 comentários, R).

**O que os usuários temem**
- Malware em ISO/ferramentas: ver §1.1 Ghost Spectre; casos reais de ISOs falsas distribuindo infostealers (não Ghost Spectre) — [BleepingComputer](https://www.bleepingcomputer.com/news/security/unofficial-windows-11-upgrade-installs-info-stealing-malware/amp/), [Windows Central — "Government Edition" falsa](https://www.windowscentral.com/software-apps/windows-11/leaked-windows-11-government-edition-that-has-no-telemetry-tracking-or-bloatware-is-actually-fake), [Tom's Hardware — Enterprise G](https://www.tomshardware.com/software/operating-systems/stripped-down-windows-11-enterprise-g-iso-investigated-claims-to-be-made-for-the-chinese-government-associated-organizations) (S).
- "Quebrar" o sistema sem saber como voltar (Atlas "reinstale"; Win11Debloat #537).
- Banimento por anticheat com TPM/Secure Boot/ISO modificada ([WinUtil #2810](https://github.com/ChrisTitusTech/winutil/issues/2810); [r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/comments/1x4ojav/), R).
- Perder o Windows Update/atualização de segurança (Atlas [#1556](https://github.com/Atlas-OS/Atlas/issues/1556) e WinUtil [#3214](https://github.com/ChrisTitusTech/winutil/issues/3214)).

---

## 3. Top 15 dores e pedidos (com fonte)

Ordem por **recorrência × gravidade** observada nas fontes (julgamento da Lulu, não métrica estatística).

| # | Dor / pedido | Onde aparece | Fontes |
|---|---|---|---|
| 1 | **Medo de ISO/ferramenta modificada com malware ou backdoor** | Ghost Spectre, Tiny11, ISOs falsas | [Candid](https://candid.technology/ghost-spectre-windows-11/), [r/Windows10](https://www.reddit.com/r/Windows10/comments/1xhwspw/), [tiny11 #47](https://github.com/ntdevlabs/tiny11builder/issues/47), [BleepingComputer](https://www.bleepingcomputer.com/news/security/unofficial-windows-11-upgrade-installs-info-stealing-malware/amp/) |
| 2 | **Microsoft Store / Xbox / Gaming Services quebram** após otimização | Atlas | [#1556](https://github.com/Atlas-OS/Atlas/issues/1556), [#1675](https://github.com/Atlas-OS/Atlas/issues/1675), [#1763](https://github.com/Atlas-OS/Atlas/issues/1763), [r/AtlasOS](https://www.reddit.com/r/AtlasOS/comments/1rdsyyg/) |
| 3 | **Windows Update quebra/some** | WinUtil MicroWin, Tiny11 Core, Ghost Spectre | [#3214](https://github.com/ChrisTitusTech/winutil/issues/3214), [#3651](https://github.com/ChrisTitusTech/winutil/issues/3651), [tiny11 README](https://github.com/ntdevlabs/tiny11builder), [Positioniseverything via busca](https://www.positioniseverything.net/what-is-ghost-spectre-for-windows-11-is-it-safe/) |
| 4 | **Não saber o que foi removido/alterado** (falta de "plano de mudanças") | todos | [Atlas removed features](https://docs.atlasos.net/faq/install-faq/removed-features/) ("manual tweaking… not tested"), [gHacks sobre privacy.sexy](https://www.ghacks.net/?p=200975) |
| 5 | **Reverter só reinstalando** (sem "undo" real) | Atlas | [Atlas — Reverting](https://docs.atlasos.net/faq/install-faq/reverting-atlas/) |
| 6 | **Manter Defender/Segurança/UAC ativos por padrão** | Atlas, Ghost Spectre | [Atlas #704](https://github.com/Atlas-OS/Atlas/issues/704), [r/AtlasOS segurança](https://www.reddit.com/r/AtlasOS/comments/1qqlc7x/) |
| 7 | **Atraso em suportar builds novas (25H2/26H2)** e scripts que quebram a cada release | Atlas, Tiny11, WinUtil | [Atlas #1743](https://github.com/Atlas-OS/Atlas/issues/1743), [tiny11 #462](https://github.com/ntdevlabs/tiny11builder/issues/462), [#484](https://github.com/ntdevlabs/tiny11builder/issues/484) |
| 8 | **Upgrade de versão do Windows não suportado/quebra tweaks** | Atlas, WinUtil (feature updates resetam tweaks) | [Atlas FAQ](https://docs.atlasos.net/faq/general-faq/upgrading-windows-version/), [WinUtil FAQ](https://winutil.christitus.com/faq/) |
| 9 | **Quebras colaterais** (Busca do Menu Iniciar, login MS, Windows Hello, drivers) | Win11Debloat, Atlas | [#361](https://github.com/Raphire/Win11Debloat/issues/361), [#537](https://github.com/Raphire/Win11Debloat/issues/537), [#401](https://github.com/Raphire/Win11Debloat/issues/401), [Atlas #1618](https://github.com/Atlas-OS/Atlas/issues/1618) |
| 10 | **Bypass de TPM/Secure Boot afetando anticheat** | WinUtil MicroWin, Ghost Spectre | [#2810](https://github.com/ChrisTitusTech/winutil/issues/2810), [r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/comments/1x4ojav/) |
| 11 | **Ganhos de desempenho exagerados/sem prova** ("2 FPS") | Atlas, ReviOS, Ghost Spectre | [r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/comments/1qf3xj9/), [r/OptimizedGaming](https://www.reddit.com/r/OptimizedGaming/comments/1r14g7b/), [r/OptimizedGaming evidências](https://www.reddit.com/r/OptimizedGaming/comments/1w1haik/) |
| 12 | **Binários opacos / origem duvidosa / antivírus sinaliza / `irm \| iex`** | Tiny11 (oscdimg), Optimizer, Talon, WinUtil | [tiny11 #47](https://github.com/ntdevlabs/tiny11builder/issues/47), [WinUtil #1742](https://github.com/ChrisTitusTech/winutil/issues/1742), [BetaNews/Talon](https://betanews.com/2025/02/14/no-more-bloat-talon-completely-fixes-microsoft-windows-11-in-just-two-clicks) |
| 13 | **Remover Copilot/Recall/IA e telemetria de forma confiável** | Win11Debloat, Tiny11, Atlas | [tiny11 #200](https://github.com/ntdevlabs/tiny11builder/issues/200), [Atlas #1757](https://github.com/Atlas-OS/Atlas/issues/1757), [Windows Central](https://www.windowscentral.com/microsoft/windows-11/windows-president-addresses-current-state-of-windows-11-after-ai-backlash-we-know-we-have-a-lot-of-work-to-do) |
| 14 | **Instalação difícil/confusa e suporte pouco amigável** (scratch disk, instruções, erros) | Tiny11, Atlas | [tiny11 #549](https://github.com/ntdevlabs/tiny11builder/issues/549), [#339](https://github.com/ntdevlabs/tiny11builder/issues/339), [r/AtlasOS](https://www.reddit.com/r/AtlasOS/comments/1u6pcm6/) |
| 15 | **Conta Microsoft/internet obrigatória no OOBE, anúncios e UI inconsistente** (Windows padrão) | Windows 11 | [r/Windows11](https://www.reddit.com/r/Windows11/comments/1up2u83/), [r/sysadmin](https://www.reddit.com/r/sysadmin/comments/1pfx0mp/) |

Pedidos extras com evidência menor: suporte Linux para o builder ([tiny11 #208](https://github.com/ntdevlabs/tiny11builder/issues/208)); presets de IPv6 não desativado por padrão ([WinUtil #3061](https://github.com/ChrisTitusTech/winutil/issues/3061)); update de playbook dentro da Toolbox ([Atlas #1702](https://github.com/Atlas-OS/Atlas/issues/1702)).

---

## 4. Lacunas por edição

**DEV**
- Nenhum concorrente entrega um "Windows pronto para dev": o ecossistema atual é *debloat* (remover), não *provisionar* (WSL2, Git, winget, toolchains). WinUtil tem catálogo de apps, mas não é perfil de dev integrado ([FAQ](https://winutil.christitus.com/faq/)).
- Atlas tem issues de WSL ([#1615](https://github.com/Atlas-OS/Atlas/issues/1615)) e de PATH sobrescrito ([#1076](https://github.com/Atlas-OS/Atlas/issues/1076)) — sinal de que dev e "otimização agressiva" conflitam.
- *Inferência da Lulu* (não é fato de fonte): perfil DEV deve **não mexer** em serviços/virtualização (Hyper-V, WSL), manter Defender com exclusões de pastas de projeto e entregar um "manifest" de ferramentas (winget).

**Balanced**
- O público "quer menos lixo e zero quebra" e prefere ferramentas auditáveis (WinUtil/Win11Debloat) a ISOs ([r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/comments/1te3qg5/)). Win11Debloat é o padrão de fato, mas **sem perfil nomeado, teste por build nem reversão formal** ([README](https://github.com/Raphire/Win11Debloat)).
- Oportunidade: perfil "seguro por padrão" (Update/Defender/Store/Xbox intocados), com **telemetria/anúncios/Copilot desligáveis** e personalização visual (menu Iniciar, barra, Explorer) — pedidos de custom themes no Atlas ([#345](https://github.com/Atlas-OS/Atlas/issues/345)).

**Full Performance**
- Mercado de gamers está saturado de promessas (Ghost Spectre, ReviOS, Atlas) e **cético por falta de evidência**: ganho "~2 FPS" ([r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/comments/1qf3xj9/)); "ReviOS praticamente não mostra ganhos" ([r/OptimizedGaming](https://www.reddit.com/r/OptimizedGaming/comments/1r14g7b/)).
- Riscos reais que precisam de guarda-corpos: Store/Xbox/Game Pass quebrando (Minecraft Bedrock, Rocket League/Fortnite via anticheat) — [r/AtlasOS](https://www.reddit.com/r/AtlasOS/comments/1s2lb4g/), [r/pcmasterrace](https://www.reddit.com/r/pcmasterrace/comments/1x4ojav/).
- Oportunidade: **benchmark reprodutível publicado** (método, hardware, 1% lows, tempo de quadro) para cada tweak — alinhado ao pedido de "evidências mínimas" ([r/OptimizedGaming](https://www.reddit.com/r/OptimizedGaming/comments/1w1haik/)). E modo "Gamer com Store/Xbox" vs "Gamer purista".

**O que gera confiança num projeto gratuito (síntese das fontes)**
- Código 100% aberto e auditável + sem binários opacos ([Carta](../docs/00-CARTA-DO-PROJETO.md); contraexemplos: tiny11 #47, Optimizer .exe).
- Admitir limites honestamente: o Atlas ganhou credibilidade ao dizer "o Windows sem modificação sempre será o mais confiável" e ao documentar o que removeu ([FAQ](https://docs.atlasos.net/faq/general-faq/atlas-and-security/)).
- Licença clara (Tiny11 sem licença declarada e Winhance `NOASSERTION` são fraquezas) — [tiny11 repo](https://github.com/ntdevlabs/tiny11builder), [Winhance](https://github.com/memstechtips/Winhance).
- Issues respondidas por mantenedores (Atlas e WinUtil respondem; veja mantenedor em [#1250](https://github.com/ChrisTitusTech/winutil/issues/1250), [#1556](https://github.com/Atlas-OS/Atlas/issues/1556)).
- Pedido de "evidências" nos guias de desempenho (r/OptimizedGaming).

---

## 5. Top 10 oportunidades priorizadas para o BigZ OS

Prioridade = impacto na confiança/adoção ÷ esforço estimado (julgamento da Lulu; Cid e Beatrix devem validar viabilidade).

| # | Oportunidade | Por que (dor ↔ evidência) | Edição | Esforço (estim.) |
|---|---|---|---|---|
| 1 | **"Plano de mudanças" legível antes de aplicar (dry-run)**: lista de tudo que será alterado/removido, com risco e link para explicação. Comparar com `WhatIf` do Win11Debloat ([release](https://github.com/Raphire/Win11Debloat/releases)) | Dor #4 e #12; privacy.sexy já mostra o valor da visibilidade ([README](https://github.com/undergroundwires/privacy.sexy)) | Todas | Médio |
| 2 | **Reversão real por tweak** (snapshot/registro de estado antes + botão "desfazer"), não "reinstale" | Dor #5; Atlas só reverte reinstalando ([FAQ](https://docs.atlasos.net/faq/install-faq/reverting-atlas/)) | Todas | Alto |
| 3 | **Segurança ligada por padrão** (Update, Defender, UAC, SmartScreen, Store e Xbox intactos em DEV/Balanced; Full Performance com avisos claros) | Dor #2, #3, #6; [Atlas #704](https://github.com/Atlas-OS/Atlas/issues/704) | DEV, Balanced | Baixo |
| 4 | **Zero binário opaco + builds assinadas/checksums + SBOM; origem de cada ferramenta documentada** (usar ferramentas oficiais: DISM/oscdimg do ADK) | Dor #1, #12; [tiny11 #47](https://github.com/ntdevlabs/tiny11builder/issues/47) | Todas | Baixo-Médio |
| 5 | **CI com teste em VM por build do Windows (24H2/25H2/26H2)** e matriz publicada de compatibilidade; falhar o release se Update/Store/Xbox quebrarem | Dor #3, #7, #9; Atlas e Tiny11 tardam em builds novas ([#1743](https://github.com/Atlas-OS/Atlas/issues/1743), [#462](https://github.com/ntdevlabs/tiny11builder/issues/462)) | Todas | Alto (Cloud+Beatrix) |
| 6 | **Perfil DEV "pronto para trabalhar"**: WSL2, Git, winget manifest, terminal, Defender exclusions de pastas de projeto, sem mexer em serviços que dev usa | Lacuna DEV (nenhum concorrente direto); [Atlas #1615](https://github.com/Atlas-OS/Atlas/issues/1615) | DEV | Médio |
| 7 | **Perfil Full Performance com benchmarks reprodutíveis e "gamer-safe"** (anticheat-friendly: não burlar TPM/Secure Boot por padrão; modo com/sem Xbox) | Dor #10 e #11; [WinUtil #2810](https://github.com/ChrisTitusTech/winutil/issues/2810), [r/OptimizedGaming](https://www.reddit.com/r/OptimizedGaming/comments/1w1haik/) | Full Perf | Médio |
| 8 | **Toolbox híbrida: GUI + CLI/preset exportável + modo "atualização segura" que reaplica tweaks após feature update** | Dor #8; WinUtil avisa que feature updates resetam tweaks ([FAQ](https://winutil.christitus.com/faq/)); pedidos de GUI e presets | Todas | Médio |
| 9 | **Documentação "por que" de cada tweak + página de segurança honesta** (inclui "o Windows padrão continua sendo o mais confiável" e riscos por edição) | Dor #4; modelo do Atlas ([FAQ segurança](https://docs.atlasos.net/faq/general-faq/atlas-and-security/)) | Todas | Baixo (Tellah) |
| 10 | **Builder multiplataforma (Windows + Linux) e entrada simples**: baixa a ISO oficial da Microsoft com checksum (como o NTLite e o Atlas) e guia assistido | Dor #14; [tiny11 #208](https://github.com/ntdevlabs/tiny11builder/issues/208), [NTLite Image Composer](https://www.ntlite.com/features/) | Todas | Médio-Alto |

**Riscos que a pesquisa sugere vigiar (para Beatrix/Auron)**
- Redistribuição: nenhum concorrente sério distribui ISO modificada além do Ghost Spectre; mesmo o Atlas cita as regras de redistribuição da Microsoft ([FAQ](https://docs.atlasos.net/faq/install-faq/atlas-iso-files/)). **Parecer jurídico formal não foi feito — só a Beatrix/assessoria pode confirmar.**
- Incluir/automatizar **ativação** (MAS, ativadores): apareceu no Reddit como solução para problema de ativação do Atlas ([r/AtlasOS](https://www.reddit.com/r/AtlasOS/comments/1qifndn/)) — a Carta proíbe; a documentação do BigZ OS não deve sugerir isso.
- Dependência de terceiros (AME Wizard) vs. motor próprio: decisão para o Cid; ver impacto de confiança.
- **Licença final** (Tellah): Tiny11 sem licença e Winhance `NOASSERTION` mostram o custo da ambiguidade.

---

## 6. Lacunas desta pesquisa (o que NÃO foi confirmado)
- Fóruns: ElevenForum (parcial, via trecho de busca), My Digital Life, fórum do NTLite, TenForums — **não lidos** (bloqueio/ausência de resultado).
- Reddit: amostra pequena; textos traduzidos automaticamente; não conferidos r/Tiny11 (subreddit existe, ~20 mil membros) nem GitHub Discussions.
- O&O ShutUp10++, Winhance, ReviOS e Talon: **não analisados em profundidade** (sem críticas verificáveis).
- Preço/licença do Ghost Toolbox e qualquer verificação de malware em builds do Ghost Spectre: **não verificado**.
- Detalhes técnicos de como o AME Wizard decide o que é "aberto/fechado": **não verificado**.
- Estrelas/issues são números de 2026-11-21 (API do GitHub) e mudam.

## 7. Próximos passos sugeridos (se o Auron aprovar)
1. Rodada 2: fóruns restantes + GitHub Discussions do Atlas/WinUtil + análise do código do Atlas Toolbox e do WinUtil (tweaks) para catálogo da Rikku.
2. Lista dos tweaks mais citados como "quebradores" (serviços, Store/Xbox, Update) para a Beatrix montar a suíte de testes.
3. Pesquisa de licenciamento de edições (LTSC/IoT/Education) com a Beatrix antes de qualquer menção em docs.
