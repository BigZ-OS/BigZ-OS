# BigZ OS · Status da Toolbox F1

A Toolbox v0.1 abre em modo de simulação. A implementação segue o [plano consolidado](../docs/03-plano-consolidado.md), a [arquitetura](../docs/01-arquitetura-v0.md) e a [ADR-004](../docs/decisoes/ADR-004-contrato-json-de-tweaks-e-apps.md). O protótipo permite escolher edição, marcar itens, inspecionar o plano e simular a reversão do último plano.

## Entregas

| Arquivo | Conteúdo |
|---|---|
| [catalog/apps.json](catalog/apps.json) | 57 apps com IDs WinGet verificados. 35 têm origem e escopo de instalação declarados no manifesto x64 ou neutro. Os 22 restantes usam a página oficial no plano e conservam o ID e o manifesto como evidência. |
| [shared/tweaks/](../shared/tweaks/) | Dez ajustes online, de baixo risco e reversíveis. São preferências de Explorer, barra de tarefas e transparência da conta atual. Cada objeto declara o efeito, a fonte e como restaurar o estado anterior. |
| [catalog/profiles.json](catalog/profiles.json) | Seleções iniciais da F1. DEV marca Git, VS Code e Windows Terminal. As demais começam sem apps avulsos marcados. Nenhum ajuste de Registro é marcado de saída. |
| [Start-BigZToolbox.ps1](Start-BigZToolbox.ps1) e [Toolbox.xaml](Toolbox.xaml) | Protótipo PowerShell 5.1/WPF com seletor de edição, navegação, listas com risco, “Ver plano” e “Desfazer”. A interface usa o mesmo planejador da CLI. |
| [Módulo de plano](modules/BigZ.Toolbox.Plan.ps1) | Resolve seleções, dependências e conflitos, gera a prévia e chama o motor da Engenharia em modo declarativo. |
| [Presets do Design](../design/presets-shell-toolbox.json) | Fonte lida pela Toolbox. Os presets aparecem na seção de personalização com dependências para os apps verificados. |

Itens sem manifesto verificado ficam fora do catálogo. O ExplorerPatcher ficou fora da F1 pela decisão sobre alterações em binários do Windows. A política de procedência vale para a versão efetivamente escolhida de cada pacote. A referência versionada no catálogo documenta a inspeção e o protótipo não executa instaladores. [Catálogo pesquisado](01-catalogo-v0.md) · [Política de origem no WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/install)

Os presets seguem a combinação da Yuna. A DEV sugere Open-Shell, Nilesoft Shell e TranslucentTB. Balanced sugere Nilesoft Shell e TranslucentTB. Full Performance sugere Open-Shell. Cada sugestão pode ser desmarcada. A opção nativa sólida da Full Performance entra no plano sem criar dependência do TranslucentTB. Variantes de tema e arquivos de configuração aparecem como detalhes declarativos. A simulação sinaliza os arquivos de configuração ainda ausentes. [Especificação de Design](../design/02-presets-shell-catalogo.md)

## Simulação local

A partir da raiz do projeto, no Windows PowerShell 5.1:

```powershell
powershell.exe -NoProfile -STA -File .\toolbox\Start-BigZToolbox.ps1
.\toolbox\Start-BigZToolbox.ps1 -Plan -Edition dev
.\toolbox\Start-BigZToolbox.ps1 -Plan -Edition dev -Id 'explorer.show-file-extensions'
powershell.exe -NoProfile -STA -File .\toolbox\Start-BigZToolbox.ps1 -CheckUi
```

“Ver plano” mostra apps, dependências e o valor proposto de cada ajuste. “Desfazer” apresenta a ordem inversa em simulação. Para ajustes, o planejador usa `Get-BigZTweakPlan -Phase online -DeclarationOnly`. O retorno vem sem leitura do Registro. Se o módulo ou essa interface estiverem indisponíveis, a UI identifica a prévia local e exibe o aviso quando houver falha de carregamento. Erros declarativos do motor permanecem visíveis.

## Verificação e limites

- Os dois scripts passaram pelo analisador sintático do PowerShell 5.1. O teste WPF carregou o XAML em STA, mediu o layout e acionou as rotas dos botões com a janela sem exibição.
- A CLI conferiu as três seleções iniciais, dependência e deduplicação de apps, plano vazio e rejeição de item fora da edição. O motor do Cid conferiu os dez ajustes declarativos.
- A prévia não valida efeitos visuais, regras de atualização, autenticação dos instaladores ou reversão em máquina virtual. A integração de instalação, aplicação, diário e reversão real fica para a etapa de execução do MVP.
- Nenhum pacote foi instalado, nenhum ajuste foi aplicado e nada foi publicado.
