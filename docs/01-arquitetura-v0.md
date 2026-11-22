# BigZ OS — Arquitetura v0

**Proposta para revisão.** O BigZ OS distribui código, perfis e documentação próprios. O usuário fornece a ISO oficial do Windows e gera a mídia modificada localmente. DEV, Balanced e Full Performance são perfis do BigZ OS e mantêm a edição e o licenciamento do Windows selecionado na ISO. O estudo foi feito por leitura estática. Compatibilidade dos perfis e ganhos de desempenho ainda não verificados em laboratório. [Carta do projeto](00-CARTA-DO-PROJETO.md) · [Download oficial do Windows 11][iso]

## 1. Referências e decisões de reaproveitamento

### tiny11builder

- O `tiny11maker.ps1` recebe a unidade da ISO montada, copia a mídia, seleciona um índice e exporta ESD para WIM quando necessário. Monta a imagem, enumera os Appx provisionados e remove os identificados pela lista do script. Carrega hives offline (arquivos de registro), incluindo `SOFTWARE`, `SYSTEM` e `Users\Default\NTUSER.DAT`, descarrega as hives e finaliza a mídia com `oscdimg`. O checkout também contém uma implementação .NET com interface WinUI, plano de build, inventário e retomada por checkpoint. [PowerShell original][tiny-ps] · [Motor .NET][tiny-engine] · [Registro offline][tiny-reg] · [Notas de uso][tiny-usage]
- O script regular apaga Edge/WebView e usa `ResetBase`, que impede desinstalar atualizações já instaladas. O Core remove pacotes de sistema, descarta parte do WinSxS e perde Windows Update e recuperação, além de desativar Defender. Para o BigZ OS, vale implementar de forma independente a inspeção por índice, a montagem em área temporária, o inventário e a separação entre plano e execução. A intervenção em componentes protegidos fica fora da v0. O checkout consultado declara ausência de licença autônoma e ausência de uma nova licença para o código upstream. Solicitar permissão antes de incorporar código, XML ou listas copiadas. [Script regular][tiny-ps] · [Script Core][tiny-core] · [WinSxS e ResetBase][winsxs] · [Aviso de licença][tiny-license] · [GitHub sobre repositórios sem licença][no-license]

### Atlas OS + AME Wizard

- O pacote `.apbx` contém o playbook. Em Atlas, `playbook.conf` é XML com versão, builds aceitas, requisitos e opções. `Configuration/custom.yml` encadeia ações YAML e chama scripts por opção e fase, com contexto de execução e tratamento de retorno. No código público do AME Wizard Core, em C#, o parser associa tags YAML a classes de registro, serviços, Appx, pacotes de sistema e execução de comandos. O CLI valida requisitos e possui caminhos que executam como TrustedInstaller. A interface gráfica do AME Wizard não foi auditada. No snapshot de Atlas consultado, Atlas Manager é o fluxo recomendado pelo projeto e AME Wizard é a alternativa. [README Atlas][atlas-readme] · [Manifesto Atlas][atlas-conf] · [Playbook Atlas][atlas-yaml] · [Parser AME][ame-parser] · [CLI AME][ame-cli]
- Atlas oferece escolhas para Defender e Windows Update. O código de Defender prevê casos em que a restauração falha quando ele já está ausente. O toggle de Update altera políticas e tarefas, e o da Store oferece remoção para todos os usuários com restauração para a conta atual. São exemplos de por que requisitos por build, contexto do usuário e escopo de reversão precisam fazer parte do contrato. Reimplementar essas ideias com operações próprias e limitadas. O playbook Atlas traz GPLv3, com obrigações de licença e de código-fonte correspondente na distribuição de derivados. O núcleo público do AME Wizard usa MIT, com preservação dos avisos, e serve de referência para o parser. A licença do núcleo cobre o código ali publicado. [Defender Atlas][atlas-defender] · [Windows Update Atlas][atlas-update] · [Store Atlas][atlas-store] · [GPLv3 Atlas][atlas-license] · [MIT AME Core][ame-license]

### Chris Titus WinUtil

- O build empacota scripts PowerShell, interface WPF/XAML e catálogos JSON. `applications.json` e o instalador integram WinGet. `tweaks.json` descreve, entre outras ações, valores de registro, serviços e scripts. O executor reverte por `OriginalValue`, `OriginalType` ou `UndoScript`. Um valor de catálogo pode divergir do estado anterior do usuário. O perfil que desliga atualizações desativa BITS, `wuauserv` e `UsoSvc`, com efeito sobre o fluxo de atualização; o próprio projeto tem um fluxo separado de retorno ao padrão. Aproveitar a separação entre catálogo, interface e módulos. Registrar o estado real antes da escrita e preservar avisos MIT em qualquer trecho incorporado. [Build][win-build] · [XAML][win-xaml] · [Catálogo de apps][win-apps] · [Instalador WinGet][win-winget] · [Catálogo de tweaks][win-tweaks] · [Executor][win-engine] · [Desativação de Update][win-disable] · [Retorno ao padrão][win-update-default] · [Licença MIT][win-license]

### Win11Debloat

- O PowerShell oferece modo gráfico e parâmetros de linha de comando, importa/exporta configuração e distingue remoção Appx por usuário, para todos os usuários e desprovisionamento. Também usa WinGet para alguns apps e prevê diferenças entre contexto elevado e sessão do usuário. Há backup de registro e ponto de restauração configuráveis. A remoção da Store e do Terminal tem aviso que o modo silencioso pula. O BigZ OS pode reaproveitar o desenho de escopos e a prévia de mudanças, com proteção de componentes aplicada também no modo automatizado. Reuso de código ou dados licenciados requer os avisos MIT. [Script de entrada][debloat-script] · [Recursos][debloat-entry] · [Remoção de apps][debloat-remove] · [Aplicação e restauração][debloat-apply] · [Proteção da Store e do Terminal][debloat-guard] · [Licença MIT][debloat-license]

### Sophia Script

- `Sophia.ps1` é um preset editável que chama funções do módulo `Sophia.psm1`. Há variantes por versão do Windows e do PowerShell, verificações de serviços e componentes, funções que oferecem estados opostos e ponto de restauração. A rotina Appx exclui frameworks e pacotes de sistema da seleção em um de seus caminhos e inclui Store e App Installer na lista de exclusão. O preset oferece opções para Defender e SmartScreen. Restaurar o padrão do preset pode sobrescrever escolhas anteriores, e a inicialização inclui mutações enquanto verifica dependências. Para o BigZ OS, aproveitar o padrão de funções pequenas, separar inspeção de escrita e validar recursos por build. Preservar avisos MIT para material efetivamente reutilizado. [Preset][sophia-preset] · [Verificações iniciais][sophia-init] · [Módulo][sophia-module] · [Licença MIT][sophia-license]

A implementação inicial pode ser toda original. Qualquer incorporação futura registra arquivo, commit, autor, licença e avisos em `THIRD-PARTY-NOTICES.md`, inclusive para dados e recursos de terceiros. A licença do BigZ OS fica como decisão da área de Comunidade. A carta pede atribuição e contribuição de volta no uso comercial. A redação precisa ser definida antes de redistribuir trabalho derivado, porque a GPLv3 veda restrições adicionais ao exercício dos direitos que concede. [Carta do projeto](00-CARTA-DO-PROJETO.md) · [Texto da GPLv3][atlas-license]

## 2. Builder local e toolbox

### Builder

**Contrato proposto**

`Build-BigZIso.ps1 -IsoPath … -Profile … -ImageIndex … -OutputPath …`. Começar com Windows 11 25H2 x64, Home e Pro, em UEFI. A 26H2 entra após validar toda a matriz. O perfil BigZ é independente do índice da mídia. A saída é uma ISO inicializável com um índice, mais SHA-256 e manifesto JSON locais. O modo `-Plan` apenas inspeciona e resolve o plano. Caso precise montar imagem para inventário, usa montagem de leitura e descarta o estado temporário. [Versões do Windows 11][windows-releases] · [Compatibilidade do DISM][dism-platforms] · [Origem da ISO][iso]

1. **Inspecionar.** Abrir a ISO somente para leitura. Conferir SHA-256 quando houver referência oficial para aquela mídia e registrar o hash calculado em todos os builds. Um hash sem referência registra identidade. Validar espaço, privilégios da fase de build, versão/assinatura das ferramentas e caminhos locais de trabalho e saída. Enumerar `install.wim` ou `install.esd` por índice, edição, arquitetura, idioma e build. Recusar mídia ambígua ou combinações fora da matriz. Usar DISM compatível e `oscdimg` do ADK oficial instalado pelo usuário, com identidade da ferramenta registrada no manifesto. [Download e hashes][iso] · [ADK][adk] · [DISM][dism-image]
2. **Planejar.** Resolver um perfil JSON versionado com `schemaVersion`, `id`, `base`, `offlineTweaks`, `firstUseDefaults` e `optionalTweaks`. Validar IDs, fases, pré-requisitos, conflitos, dependências e lista de componentes protegidos. Resolver identidades no inventário da imagem e mostrar alvo e efeito de cada ação antes do build. Ausência esperada gera registro de operação dispensada. Falha de um requisito obrigatório bloqueia a geração. A mídia fornece os pacotes de origem e o build funciona sem download.
3. **Preparar e editar.** Copiar a estrutura do instalador a uma área exclusiva em NTFS. Exportar o índice selecionado de ESD ou WIM para um WIM de trabalho e montar o novo índice 1. Limitar a primeira versão a remoção Appx por identidade verificada via DISM. Admitir edição de registro offline apenas para valores tipados e revisados, sob a hive explícita da imagem. Preferir `unattend.xml` para configurações que o Setup suporta. Quando uma hive precisar ser montada, usar nome exclusivo do job, fechar handles e descarregá-la antes de desmontar a imagem. A conta padrão de novos usuários usa `Users\Default\NTUSER.DAT`. [Opções Appx do DISM][dism-appx] · [Gerenciamento de imagem][dism-image]
4. **Verificar e fechar.** Registrar inventário antes/depois e códigos de saída. Manter `boot.wim` e a estrutura de boot da mídia. Após as verificações, gravar e desmontar o WIM, manter um único `sources/install.wim` e validar seu índice. Versionar o manifesto com hash da ISO original, perfil e catálogo, índice de origem, identidade do Windows, versão do BigZ e das ferramentas, mudanças e avisos. Gerar a ISO com `oscdimg` em UDF e entrada de boot UEFI da mídia. Conferir estrutura, arquivo de resposta e SHA-256 antes de mover a saída temporária para o nome final. Bloquear sobrescrita e builds concorrentes para o mesmo destino. [DISM][dism-image] · [Oscdimg][oscdimg]
5. **Recuperar.** Antes do commit do WIM, falha ou cancelamento descartam a montagem do próprio job. Após gravar o WIM, eventual falha da ISO preserva a mídia original e impede a entrega de uma saída parcial. Se o Windows mantiver uma montagem ativa após interrupção, usar o registro do job para identificar e recuperar apenas aquela montagem. Refazer da ISO original é a reversão padrão de um build concluído. Um app desprovisionado pode ser reinstalado de fonte oficial quando disponível, com revalidação por conta. [DISM Appx][dism-appx] · [Montagem, descarte e recuperação no DISM][dism-image]

### Arquivo de resposta

Gerar `autounattend.xml` na raiz da mídia a partir de um template `unattend.xml` próprio. Usar `windowsPE` para o idioma escolhido e a referência ao índice exportado. Em `specialize`, aplicar configurações de máquina suportadas pelo Setup e, se necessário, chamar um único script local e idempotente para registrar a versão e o perfil da toolbox. Deixar seleção de disco, ativação, conta e OOBE (configuração inicial do Windows) em seus fluxos interativos. Usar somente arquivos BigZ verificados numa pasta protegida para qualquer etapa elevada. Validar XML e validar o arquivo contra o WIM alvo no Windows SIM do ADK, além de instalar em VM. A toolbox cuida das ações por usuário após o login. O Setup pode iniciar comandos `FirstLogonCommands` em paralelo e a disponibilidade do WinGet depende do registro do App Installer na sessão. [Passes do Setup][setup-passes] · [Localização do arquivo de resposta][setup-automation] · [Windows SIM][wsim] · [FirstLogonCommands][first-logon] · [WinGet][winget]

### Toolbox

| Stack | Vantagens | Custos |
| --- | --- | --- |
| **Windows PowerShell 5.1 x64 + WPF/XAML** | Reutiliza cmdlets Windows e permite entregar CLI e UI a partir do mesmo módulo. WPF atende a um produto só para Windows. | Executar UI em STA e tarefas longas em segundo plano. Tipagem e empacotamento pedem disciplina e testes sobre o 5.1. |
| **C#/.NET + WinUI 3** | Tipagem, testes de UI e controles atuais do Windows. Boa opção para evoluir a interface. | Acrescenta Windows App SDK, estratégia de entrega do runtime e integração com um executor elevado. |
| **Tauri 2** | Frontend web e permissões específicas para chamadas ao backend. | Acrescenta Rust, cadeia frontend e WebView2 no Windows. Ainda precisa de integração nativa com UAC e PowerShell. |

[WPF][wpf] · [Empacotamento do Windows App SDK][winui] · [Pré-requisitos Tauri][tauri] · [Permissões Tauri][tauri-permissions]

**A v0 usa Windows PowerShell 5.1 x64 + WPF.** A UI roda sem elevação e mostra inventário, plano, pré-requisitos, risco e histórico. A CLI usa o mesmo motor. As ações de máquina passam por um processo curto elevado via UAC, com módulo assinado instalado em pasta gravável apenas por administradores. O processo elevado resolve IDs na sua própria cópia confiável do catálogo, revalida alvos e dependências e executa apenas operações tipadas. Operações por usuário usam o contexto da conta solicitante, inclusive quando a credencial administrativa pertence a outra conta. Um pacote da toolbox contém código e dados BigZ, com assinatura Authenticode e SHA-256 na distribuição.

Instalação de aplicativos é uma ação explícita após login. WinGet usa ID exato, origem declarada e escopo, com verificação de disponibilidade na sessão. A interface informa os termos exigidos antes de instalar, distingue reinício de falha e registra a versão resultante. A toolbox pode ser usada no Windows oficial dentro da matriz suportada. Quando houver uma instalação BigZ, lê o perfil local para mostrar seus padrões sem depender de serviços externos. [WinGet e registro pós-login][winget] · [Comando de instalação][winget-install]

## 3. Contrato comum de tweaks

O catálogo JSON usa identificadores estáveis e versão de esquema. A ação encapsula somente os parâmetros aceitos por um executor conhecido. Cada item declara fase, escopo, edições elegíveis, pré-condições, dependências, conflitos, risco, impacto na proteção, fonte, verificação e reversão. Perfil e catálogo são independentes, com validação cruzada. Exemplo proposto, condicionado à validação na matriz. [Referência para a preferência do Explorer][win-tweaks]

```json
{
  "schemaVersion": 1,
  "id": "explorer.show-file-extensions",
  "description": "Mostrar extensões de arquivo conhecidas no Explorer",
  "risk": "low",
  "securityImpact": "none",
  "source": "https://learn.microsoft.com/en-us/windows/advanced-settings",
  "editions": ["dev", "balanced"],
  "phase": "online",
  "scope": "currentUser",
  "requires": {"builds": [26200], "architectures": ["x64"], "admin": false},
  "dependsOn": [],
  "conflictsWith": [],
  "action": {
    "type": "registry.setValue",
    "key": "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
    "name": "HideFileExt",
    "valueType": "DWord",
    "value": 0
  },
  "verify": {"type": "registry.matchesAction"},
  "rollback": {"type": "restoreSnapshot"},
  "restart": "none"
}
```

- **Fases.** `offline` atua apenas na imagem e `online` exige contexto explícito de usuário, máquina ou primeiro uso. Alvos e operações pertencem a uma lista permitida. O primeiro marco cobre registro e Appx offline. O catálogo pode ganhar tipos próprios para WinGet, recursos opcionais e energia conforme cada função passar nas verificações do perfil. Campos desconhecidos, comandos livres, URLs executáveis e importação de código externo são rejeitados.
- **Risco.** `low` para preferências reversíveis, `medium` quando há efeito funcional ou reinício e `high` quando a recuperação depende de mídia original ou reinstalação. A v0 libera padrões de risco baixo e desprovisionamento pontual revisado, com aviso e recuperação declarados; ações de risco alto ficam bloqueadas. Operações com `securityImpact: reducesProtection` ficam indisponíveis em qualquer modo, conforme a [ADR-005](decisoes/ADR-005-politica-de-risco-de-tweaks.md).
- **Execução.** inspecionar, salvar o estado anterior, aplicar, verificar e registrar. O `dry-run` termina no plano. Antes de alterar registro, capturar existência, tipo e valor, além do SID para operações por usuário. Persistir o estado e o progresso antes da primeira mutação. Uma segunda aplicação preserva o snapshot inicial daquele ciclo e valida idempotência. No undo, restaurar em ordem inversa e detectar se o valor atual divergiu do que o BigZ escreveu. Divergência externa gera um conflito registrado. Para Appx offline, a reversão exata é reconstruir a mídia. A interface mostra os limites de reinstalação e de restauração de dados do app.
- **Auditoria.** guardar resultado por ID, sequência, erro, versão do catálogo, estado anterior e posterior e status de reinício. Travar a execução simultânea no mesmo alvo e proteger o diário contra escrita por outra conta. Permitir retomada somente quando a verificação de estado confirmar a etapa anterior. A reversão parcial preserva o diário e informa os itens que ainda exigem ação.

## 4. O que muda por edição

**Base comum.** Preservar Windows Update e seus serviços/tarefas, Defender, SmartScreen, UAC, firewall, integridade de memória (VBS/HVCI conforme o Windows e o hardware), TPM e Secure Boot, BitLocker/Criptografia do Dispositivo, WinRE, WinSxS, Store, App Installer, frameworks Appx, WebView2, drivers e pilha de rede. Preservar Xbox/Gaming Services, acessibilidade, idioma, áudio e controles. Respeitar políticas gerenciadas existentes. Isso mantém os caminhos de manutenção, recuperação e instalação necessários à própria toolbox. [Windows Update e ciclo de manutenção][windows-releases] · [Tamper Protection][tamper] · [WinSxS][winsxs] · [Dependência do App Installer][winget]

| Área | DEV | Balanced | Full Performance |
| --- | --- | --- | --- |
| **Imagem / Appx** | Usar a mesma remoção mínima do Balanced. Preservar Terminal e componentes de desenvolvimento. | Lista mínima. Microsoft News é candidato inicial quando presente como pacote independente. Preservar utilitários de uso geral. | Aplicar a mesma lista mínima e ampliá-la apenas com apps independentes que passem nos testes. Candidatos iniciais para a diferença de perfil incluem Clipchamp e Solitaire, quando presentes e dispensáveis no alvo. |
| **Shell** | A seleção inicial da toolbox inclui extensões visíveis e sugere atalhos de trabalho por interfaces suportadas. O usuário revisa o plano antes de aplicar. | Shell e efeitos do Windows por padrão. Personalização fica disponível na toolbox. | Oferecer animações/transparência reduzidas e desativação reversível da captura em segundo plano, sempre com opção de restaurar. Preservar a Game Bar e sua integração. |
| **Sistema e energia** | WSL 2, Virtual Machine Platform, Hyper-V e Sandbox sob demanda conforme edição Windows e hardware. Oferecer ferramentas selecionáveis pelo WinGet. | Recursos opcionais e energia seguem os padrões da mídia e os controles do Windows. | Plano de energia padrão. Opção de desempenho em alimentação AC via toolbox, condicionada a medições de consumo, temperatura e tempo de quadro. Distinguir desktop e notebook. |
| **Toolbox** | Catálogo DEV em primeiro plano, com apps, shell, recursos opcionais e ajustes comuns. | Catálogo completo com perfis explícitos para apps e preferências. | Catálogo restrito a desempenho, diagnóstico e reversão. |

Os exemplos de Appx são candidatos encontrados nas referências. O inventário da ISO e a matriz de testes definem a lista final por build. Fora da v0 ficam alterações de agendador, temporizadores, mitigação de CPU, serviços em massa e alterações de segurança experimentais. [Exemplos de Appx][debloat-apps] · [WSL 2 e Virtual Machine Platform][wsl] · [Captura e Game Bar][debloat-entry]

## 5. Layout proposto

```text
builder/
  Build-BigZIso.ps1
  modules/                     # mídia, DISM, registro offline e ISO
  templates/unattend.xml
  _refs/                       # cópias locais de leitura, fora do versionamento
toolbox/
  Start-BigZToolbox.ps1
  ui/                          # XAML, recursos e textos
  modules/                     # WinGet e execução em sessão do usuário
shared/
  schemas/                     # perfis e tweaks
  profiles/                    # base, dev, balanced, full-performance
  tweaks/                      # catálogo de mudanças revisadas
  modules/                     # plano, políticas, execução e diário
tests/
  unit/                        # Pester com ferramentas simuladas
  integration/                 # fixtures próprias
  hyperv/                      # orquestração do laboratório
docs/
  decisoes/                    # registros de decisões técnicas
infra/
  ci/                          # apoio aos workflows
.github/workflows/             # CI quando houver repositório autorizado
THIRD-PARTY-NOTICES.md
```

A raiz ignora cópias em `builder/_refs`, áreas de build e arquivos ISO, WIM, ESD, SWM, VHD(X) e catálogos do Windows SIM. A CI também examina os arquivos de entrega. A árvore de referência pode conter binários upstream e permanece somente local. [Carta do projeto](00-CARTA-DO-PROJETO.md)

## 6. Hyper-V, CI e critérios de aceite

| Faixa | Execução proposta | Critério |
| --- | --- | --- |
| **CI em pull requests** | Runner Windows hospedado, sem credenciais de release. Validar esquemas, dependências e conflitos, arquivos XML, análise estática e Pester. Usar DISM/WinGet simulados ou fixtures criadas pelo projeto. | Bloquear regressões no plano ou na lista de proteção. Exercitar ESD/WIM, índice inválido, caminhos com espaços, variações de idioma no retorno das ferramentas, cancelamento, falha no commit, recuperação, concorrência e reexecução. |
| **Laboratório por meta de release** | Hyper-V geração 2, template Microsoft Windows para Secure Boot, vTPM, disco virtual novo e sem disco físico conectado à VM. Um controle usa ISO oficial, três VMs usam os perfis BigZ. Repetir para Home e Pro, com ao menos pt-BR/en-US e entradas WIM/ESD oficiais quando disponíveis. Snapshots separam instalação limpa, pós-update e aplicação/reversão de tweaks. | Instalação e OOBE completos, primeiro login padrão e como administrador, estado de serviços e apps, boot repetido e recuperação. Se a referência oficial equivalente não passar, resolver o ambiente antes de atribuir o problema ao BigZ. |
| **Teste de manutenção** | Com rede de laboratório, instalar cumulativa aplicável a uma mídia anterior, reiniciar e confirmar build/KB. Atualizar assinaturas e conferir proteção em tempo real do Defender. Abrir a Store, instalar/atualizar um app de teste e checar a operação correspondente por WinGet. Verificar `DISM /Online /Cleanup-Image /ScanHealth` e boot em WinRE. | Update, Defender, Store, App Installer e WinRE passam em cada perfil. Testar instalação em versão mais recente e upgrade de recurso suportado antes de anunciar suporte ao upgrade. |
| **Teste específico de edição** | Testar WSL 2 no DEV, usando virtualização aninhada onde disponível. Validar fluxo básico e personalização no Balanced. No Full Performance, testar Xbox/Gaming Services, controle e captura quando oferecida. Em hardware real, comparar ISO oficial e perfil com mesma build, drivers, energia e jogo. | Redução de componentes sem quebra funcional. Registrar várias execuções, tamanho da instalação, RAM em repouso, boot e tempos de quadro p50/p99. Publicar alegações de ganho somente com resultado reproduzível. |

[Hyper-V geração 2][hyperv] · [Checkpoints][checkpoints] · [Virtualização aninhada][nested] · [WPR/WPA][wpt] · [Runners GitHub][runners] · [PSScriptAnalyzer][psscriptanalyzer] · [Pester][pester]

Orquestrar verificações no convidado via PowerShell Direct após a OOBE, com credenciais efêmeras do laboratório. Usar atualização encontrada e aplicada como evidência de Windows Update. Quando já estiver atualizado, repetir com uma mídia anterior para verificar a instalação efetiva. Medir idempotência, troca de perfil suportada, reversão após reinício e conflitos com política externa. Guardar somente resultados sanitizados, hashes e relatórios de inventário reduzidos. ISOs de entrada/saída e discos de VM permanecem locais, fora de releases, artefatos e backup do projeto. Caso o laboratório seja automatizado, executar apenas revisões aprovadas, em host isolado e com runner privado separado das PRs públicas. [PowerShell Direct][powershell-direct] · [Segurança do GitHub Actions][gh-secure]

**Ordem de implementação.** Primeiro, fechar CLI de inspeção e build Balanced com o menor conjunto de alterações e validar boot e manutenção. Depois, fechar a toolbox e a trilha de reversão. Por fim, liberar os perfis DEV e Full Performance, cada um condicionado aos testes de edição e de base comum.

[tiny-ps]: https://github.com/ntdevlabs/tiny11builder/blob/38f7ab6b1f177098c026a19b73ec84bca9c4b874/tiny11maker.ps1
[tiny-core]: https://github.com/ntdevlabs/tiny11builder/blob/38f7ab6b1f177098c026a19b73ec84bca9c4b874/tiny11Coremaker.ps1
[tiny-engine]: https://github.com/ntdevlabs/tiny11builder/blob/38f7ab6b1f177098c026a19b73ec84bca9c4b874/src/Tiny11Builder.Core/BuildEngine.cs
[tiny-reg]: https://github.com/ntdevlabs/tiny11builder/blob/38f7ab6b1f177098c026a19b73ec84bca9c4b874/src/Tiny11Builder.Core/OfflineRegistry.cs
[tiny-usage]: https://github.com/ntdevlabs/tiny11builder/blob/38f7ab6b1f177098c026a19b73ec84bca9c4b874/docs/usage.md
[tiny-license]: https://github.com/ntdevlabs/tiny11builder/blob/38f7ab6b1f177098c026a19b73ec84bca9c4b874/NOTICE.md
[atlas-readme]: https://github.com/Atlas-OS/Atlas/blob/c6afe6c84409b918c59d3da8d93184e21ce3fa49/README.md
[atlas-conf]: https://github.com/Atlas-OS/Atlas/blob/c6afe6c84409b918c59d3da8d93184e21ce3fa49/playbook/playbook.conf
[atlas-yaml]: https://github.com/Atlas-OS/Atlas/blob/c6afe6c84409b918c59d3da8d93184e21ce3fa49/playbook/Configuration/custom.yml
[atlas-defender]: https://github.com/Atlas-OS/Atlas/blob/c6afe6c84409b918c59d3da8d93184e21ce3fa49/playbook/Executables/AtlasModules/Scripts/Install/Tasks/Set-AtlasDefenderChoice.ps1
[atlas-update]: https://github.com/Atlas-OS/Atlas/blob/c6afe6c84409b918c59d3da8d93184e21ce3fa49/playbook/Executables/AtlasModules/Toggles/Advanced/ToggleWindowsUpdates.ps1
[atlas-store]: https://github.com/Atlas-OS/Atlas/blob/c6afe6c84409b918c59d3da8d93184e21ce3fa49/playbook/Executables/AtlasModules/Toggles/Advanced/MicrosoftStore.psd1
[atlas-license]: https://github.com/Atlas-OS/Atlas/blob/c6afe6c84409b918c59d3da8d93184e21ce3fa49/playbook/Executables/AtlasModules/LICENSE
[ame-parser]: https://github.com/Ameliorated-LLC/trusted-uninstaller-cli/blob/f325e9d950e6b37003a46c786fd1b6c20f3180dd/TrustedUninstaller.Shared/Parser/PlaybookParser.cs
[ame-cli]: https://github.com/Ameliorated-LLC/trusted-uninstaller-cli/blob/f325e9d950e6b37003a46c786fd1b6c20f3180dd/TrustedUninstaller.CLI/CLI.cs
[ame-license]: https://github.com/Ameliorated-LLC/trusted-uninstaller-cli/blob/f325e9d950e6b37003a46c786fd1b6c20f3180dd/LICENSE.md
[win-build]: https://github.com/ChrisTitusTech/winutil/blob/70c23c80641d7370532af2f619b2842658600842/Compile.ps1
[win-xaml]: https://github.com/ChrisTitusTech/winutil/blob/70c23c80641d7370532af2f619b2842658600842/xaml/inputXML.xaml
[win-apps]: https://github.com/ChrisTitusTech/winutil/blob/70c23c80641d7370532af2f619b2842658600842/config/applications.json
[win-winget]: https://github.com/ChrisTitusTech/winutil/blob/70c23c80641d7370532af2f619b2842658600842/functions/private/Install-WinUtilProgramWinget.ps1
[win-tweaks]: https://github.com/ChrisTitusTech/winutil/blob/70c23c80641d7370532af2f619b2842658600842/config/tweaks.json
[win-engine]: https://github.com/ChrisTitusTech/winutil/blob/70c23c80641d7370532af2f619b2842658600842/functions/private/Invoke-WinUtilTweaks.ps1
[win-disable]: https://github.com/ChrisTitusTech/winutil/blob/70c23c80641d7370532af2f619b2842658600842/functions/public/Invoke-WPFUpdatesdisable.ps1
[win-update-default]: https://github.com/ChrisTitusTech/winutil/blob/70c23c80641d7370532af2f619b2842658600842/functions/public/Invoke-WPFUpdatesdefault.ps1
[win-license]: https://github.com/ChrisTitusTech/winutil/blob/70c23c80641d7370532af2f619b2842658600842/LICENSE
[debloat-entry]: https://github.com/Raphire/Win11Debloat/blob/3d8feefbbc672d55af4b84c8681a1996538e04e2/README.md
[debloat-script]: https://github.com/Raphire/Win11Debloat/blob/3d8feefbbc672d55af4b84c8681a1996538e04e2/Win11Debloat.ps1
[debloat-remove]: https://github.com/Raphire/Win11Debloat/blob/3d8feefbbc672d55af4b84c8681a1996538e04e2/Scripts/AppRemoval/Remove-SelectedApps.ps1
[debloat-apply]: https://github.com/Raphire/Win11Debloat/blob/3d8feefbbc672d55af4b84c8681a1996538e04e2/Scripts/Features/Invoke-Changes.ps1
[debloat-guard]: https://github.com/Raphire/Win11Debloat/blob/3d8feefbbc672d55af4b84c8681a1996538e04e2/Scripts/Helpers/Confirm-UnsafeAppRemoval.ps1
[debloat-apps]: https://github.com/Raphire/Win11Debloat/blob/3d8feefbbc672d55af4b84c8681a1996538e04e2/Config/Apps.json
[debloat-license]: https://github.com/Raphire/Win11Debloat/blob/3d8feefbbc672d55af4b84c8681a1996538e04e2/LICENSE
[sophia-preset]: https://github.com/farag2/Sophia-Script-for-Windows/blob/2c43986f8b35da925954be9a2e72087aa5ed6b27/src/Sophia_Script_for_Windows_11/Sophia.ps1
[sophia-init]: https://github.com/farag2/Sophia-Script-for-Windows/blob/2c43986f8b35da925954be9a2e72087aa5ed6b27/src/Sophia_Script_for_Windows_11/Module/Private/InitialActions.ps1
[sophia-module]: https://github.com/farag2/Sophia-Script-for-Windows/blob/2c43986f8b35da925954be9a2e72087aa5ed6b27/src/Sophia_Script_for_Windows_11/Module/Sophia.psm1
[sophia-license]: https://github.com/farag2/Sophia-Script-for-Windows/blob/2c43986f8b35da925954be9a2e72087aa5ed6b27/LICENSE
[no-license]: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository
[iso]: https://www.microsoft.com/pt-br/software-download/windows11
[windows-releases]: https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information
[adk]: https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install/
[dism-platforms]: https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-supported-platforms?view=windows-11
[dism-image]: https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-image-management-command-line-options-s14?view=windows-11
[dism-appx]: https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-app-package--appx-or-appxbundle--servicing-command-line-options?view=windows-11
[oscdimg]: https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/oscdimg-command-line-options?view=windows-11
[winsxs]: https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/clean-up-the-winsxs-folder?view=windows-11
[setup-passes]: https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/how-configuration-passes-work?view=windows-11
[setup-automation]: https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-automation-overview
[wsim]: https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/wsim/validate-an-answer-file
[first-logon]: https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-firstlogoncommands
[winget]: https://learn.microsoft.com/en-us/windows/package-manager/winget/
[winget-install]: https://learn.microsoft.com/en-us/windows/package-manager/winget/install
[wpf]: https://learn.microsoft.com/en-us/dotnet/desktop/wpf/overview/
[winui]: https://learn.microsoft.com/en-us/windows/apps/windows-app-sdk/deploy-unpackaged-apps
[tauri]: https://v2.tauri.app/start/prerequisites/
[tauri-permissions]: https://v2.tauri.app/security/capabilities/
[tamper]: https://learn.microsoft.com/en-us/defender-endpoint/tamper-protection-overview
[wsl]: https://learn.microsoft.com/en-us/windows/wsl/install-manual
[hyperv]: https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/plan/should-i-create-a-generation-1-or-2-virtual-machine-in-hyper-v
[checkpoints]: https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/checkpoints
[nested]: https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/enable-nested-virtualization
[powershell-direct]: https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/powershell-direct
[wpt]: https://learn.microsoft.com/en-us/windows-hardware/test/wpt
[runners]: https://docs.github.com/en/actions/reference/runners/github-hosted-runners
[psscriptanalyzer]: https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/overview?view=ps-modules
[pester]: https://pester.dev/docs/quick-start
[gh-secure]: https://docs.github.com/en/actions/reference/security/secure-use
