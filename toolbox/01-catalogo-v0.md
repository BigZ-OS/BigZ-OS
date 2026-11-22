# BigZ OS · Catálogo v0 da Toolbox

Consulta em 21/11/2026. Proposta de catálogo pós-instalação para o Windows oficial do usuário. Referência de escopo na [Carta do Projeto](../docs/00-CARTA-DO-PROJETO.md).

## Referências de produto

- **WinUtil.** `config/applications.json` usa um objeto indexado por chave de app. As 239 entradas da revisão inspecionada trazem `content`, `description`, `category`, `link` e `winget`. Quase todas trazem `choco` e `foss`. A compilação acrescenta `WPFInstall` às chaves. Para a BigZ, vale manter chaves estáveis e tratar categoria, licença, seleção e provedor como dados. [Aplicativos](https://github.com/ChrisTitusTech/winutil/blob/70c23c80641d7370532af2f619b2842658600842/config/applications.json) · [Especificação](https://github.com/ChrisTitusTech/winutil/blob/70c23c80641d7370532af2f619b2842658600842/SPEC.md)
- **WinUtil.** `config/tweaks.json` organiza entradas por chave com rótulo, descrição, categoria e painel. Conforme a ação, usa listas de Registro e serviços, valores de origem e scripts `InvokeScript`/`UndoScript`. `config/preset.json` referencia chaves nos conjuntos Standard, Minimal, Advanced e AppxDefault. Para a BigZ, a proposta é resolver ações em código versionado e guardar o valor real encontrado na máquina para reverter. [Tweaks](https://github.com/ChrisTitusTech/winutil/blob/70c23c80641d7370532af2f619b2842658600842/config/tweaks.json) · [Presets](https://github.com/ChrisTitusTech/winutil/blob/70c23c80641d7370532af2f619b2842658600842/config/preset.json)
- **Ghost Toolbox.** O histórico do projeto cita a Microsoft Store na toolbox. Demonstrações públicas documentam escolhas de navegadores, utilitários como 7-Zip e Rufus, componentes como Microsoft Store e Xbox, bibliotecas para jogos, limpeza, ajustes de desempenho e personalização do Explorer, widgets e ícones. As opções pertencem às builds demonstradas. Catálogo completo da versão atual, procedência dos arquivos e reversão por ação: não verificados. Para a BigZ, a referência é a experiência de escolher apps, recursos e ajustes a partir da mesma ferramenta. [Histórico do Ghost Spectre](https://ghostspectre.the-ninja.jp/1607.ENT.LTSB.html) · [Demonstração de menus da Superlite SE](https://www.youtube.com/watch?v=rJvsMLfkG0k) · [Demonstração de ajustes](https://www.youtube.com/watch?v=Y6jRl_bhzms)

## Aplicativos

O catálogo tem 62 entradas, com 57 IDs WinGet confirmados por correspondência exata de `PackageIdentifier` em `microsoft/winget-pkgs`. Cada ID leva à versão do manifesto inspecionado. “Não verificado” indica que a checagem não encontrou um manifesto correspondente. Para recursos nativos, a ação é abrir a tela do Windows. As classificações de licença descrevem o produto entregue e suas condições gerais. A documentação do fabricante rege o uso comercial e as assinaturas. [Repositório dos manifestos](https://github.com/microsoft/winget-pkgs) · [Comando de instalação do WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/install)

As edições e os padrões são propostas. DEV começa com Git, VS Code e Windows Terminal marcados para compor uma estação básica. Balanced e Full Performance começam com todos os apps desmarcados. Itens já instalados aparecem como detectados. Navegadores, antivírus, drivers e extensões do shell exigem escolha do usuário. A marcação inicial só compõe a seleção para revisão antes da instalação.

“WinGet candidato” indica um canal proposto, sujeito à conferência do publicador e da origem efetiva na versão selecionada. Verificar a URL e os redirecionamentos para o fabricante, repositório oficial ou CDN própria/autorizada, integridade pelo hash e assinatura do publicador quando disponível. Se o candidato falhar nessa checagem, oferecer a página oficial. A toolbox usa ID exato e a fonte `winget`, com instaladores dos fabricantes e sem redistribuição. Termos do fornecedor devem ser exibidos quando aplicável. Drivers exigem detecção de GPU, arquitetura e Windows e preferência pelo canal do fabricante do equipamento quando necessário. Segurança do Windows deve mostrar o provedor ativo e sinalizar conflito antes de instalar outro antivírus em tempo real. [Manifesto de instalação](https://learn.microsoft.com/en-us/windows/package-manager/package/manifest) · [Compatibilidade do Defender com outros antivírus](https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-antivirus-compatibility)

### Navegadores

| Aplicativo | ID WinGet | Licença ou acesso | Exibir em | Marcado por padrão em | Entrega e fonte |
|---|---|---|---|---|---|
| Chrome | [`Google.Chrome`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/g/Google/Chrome/158.0.8127.37) | Grátis | DEV, Balanced, Full Performance | Nenhuma | WinGet candidato [Fonte do produto](https://www.google.com/chrome/) |
| Firefox | [`Mozilla.Firefox`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/m/Mozilla/Firefox/160.0.1) | Open source | DEV, Balanced, Full Performance | Nenhuma | WinGet candidato [Fonte do produto](https://www.mozilla.org/firefox/) |
| Brave | [`Brave.Brave`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/b/Brave/Brave/158.1.100.58) | Open source | DEV, Balanced, Full Performance | Nenhuma | WinGet candidato [Fonte do produto](https://brave.com/download) |
| Microsoft Edge | [`Microsoft.Edge`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/m/Microsoft/Edge/156.0.4314.58) | Grátis | DEV, Balanced, Full Performance | Nenhuma | WinGet candidato · Preferir detectar a instalação do Windows. [Fonte do produto](https://www.microsoft.com/en-us/edge) |
| Vivaldi | [`Vivaldi.Vivaldi`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/v/Vivaldi/Vivaldi/8.3.4191.47) | Grátis | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://vivaldi.com/desktop/) |
| Opera | [`Opera.Opera`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/o/Opera/Opera/140.0.6074.36) | Grátis | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://www.opera.com/browsers/opera) |

### Antivírus e segurança

| Aplicativo | ID WinGet | Licença ou acesso | Exibir em | Marcado por padrão em | Entrega e fonte |
|---|---|---|---|---|---|
| Microsoft Defender Antivirus | não verificado | Incluso no Windows | DEV, Balanced, Full Performance | Nenhuma | Recurso do Windows · Mostrar o status e abrir Segurança do Windows. [Fonte do produto](https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-antivirus-windows) |
| Bitdefender Antivirus Free (via Bitdefender Agent) | [`Bitdefender.Bitdefender`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/b/Bitdefender/Bitdefender/26.0.1.233) | Grátis | DEV, Balanced | Nenhuma | Link oficial · O manifesto aponta para o instalador do agente. A seleção da edição Free é guiada pelo fabricante. [Fonte do produto](https://www.bitdefender.com/en-us/consumer/free-antivirus) |
| Malwarebytes | [`Malwarebytes.Malwarebytes`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/m/Malwarebytes/Malwarebytes/5.7.3.376) | Grátis para análise sob demanda / pago para proteção em tempo real | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://www.malwarebytes.com/mwb-download) |
| ESET NOD32 Antivirus | [`ESET.Nod32`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/e/ESET/Nod32/19.2.10.0) | Pago | DEV, Balanced | Nenhuma | WinGet candidato · A opção paga requer licença. [Fonte do produto](https://www.eset.com/us/home/antivirus/) |
| Windows Defender Firewall | não verificado | Incluso no Windows | DEV, Balanced, Full Performance | Nenhuma | Recurso do Windows · Mostrar o status e abrir configurações. [Fonte do produto](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/) |
| Bitwarden | [`Bitwarden.Bitwarden`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/b/Bitwarden/Bitwarden/2026.11.0) | Open source / planos pagos opcionais | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://bitwarden.com/) |

### Dev / IDEs e editores

| Aplicativo | ID WinGet | Licença ou acesso | Exibir em | Marcado por padrão em | Entrega e fonte |
|---|---|---|---|---|---|
| Visual Studio Code | [`Microsoft.VisualStudioCode`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/m/Microsoft/VisualStudioCode/1.146.0) | Grátis (binário Microsoft) | DEV, Balanced | DEV | WinGet candidato [Fonte do produto](https://code.visualstudio.com/) |
| Visual Studio Community | [`Microsoft.VisualStudio.Community`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/m/Microsoft/VisualStudio/Community/18.12.1) | Grátis conforme elegibilidade | DEV | Nenhuma | WinGet candidato [Fonte do produto](https://visualstudio.microsoft.com/vs/community/) |
| IntelliJ IDEA | [`JetBrains.IntelliJIDEA`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/j/JetBrains/IntelliJIDEA/2026.3) | Grátis no núcleo / pago para recursos Ultimate | DEV | Nenhuma | WinGet candidato [Fonte do produto](https://www.jetbrains.com/help/idea/intellij-idea-single-distribution.html) |
| Android Studio | [`Google.AndroidStudio`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/g/Google/AndroidStudio/2026.2.2.9) | Grátis | DEV | Nenhuma | WinGet candidato [Fonte do produto](https://developer.android.com/studio) |

### Dev / Runtimes e SDKs

| Aplicativo | ID WinGet | Licença ou acesso | Exibir em | Marcado por padrão em | Entrega e fonte |
|---|---|---|---|---|---|
| Node.js LTS | [`OpenJS.NodeJS.LTS`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/o/OpenJS/NodeJS/LTS/26.13.1) | Open source | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://nodejs.org/) |
| Python 3.14 | [`Python.Python.3.14`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/p/Python/Python/3/14/3.14.10) | Open source | DEV, Balanced | Nenhuma | WinGet candidato · Série selecionável conforme requisitos do projeto. [Fonte do produto](https://www.python.org/) |
| .NET SDK 10 | [`Microsoft.DotNet.SDK.10`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/m/Microsoft/DotNet/SDK/10/10.0.404) | Open source | DEV | Nenhuma | WinGet candidato [Fonte do produto](https://dotnet.microsoft.com) |
| Eclipse Temurin JDK 21 | [`EclipseAdoptium.Temurin.21.JDK`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/e/EclipseAdoptium/Temurin/21/JDK/21.0.13.102) | Open source | DEV | Nenhuma | WinGet candidato [Fonte do produto](https://adoptium.net/) |
| Microsoft Visual C++ Redistributable v14 x64 | [`Microsoft.VCRedist.2015+.x64`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/m/Microsoft/VCRedist/2015%2B/x64/14.52.37029.0) | Grátis | DEV, Balanced, Full Performance | Nenhuma | WinGet candidato · Oferecer por arquitetura e dependência detectada. x64 é a entrada verificada nesta linha. [Fonte do produto](https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist) |

### Dev / Git

| Aplicativo | ID WinGet | Licença ou acesso | Exibir em | Marcado por padrão em | Entrega e fonte |
|---|---|---|---|---|---|
| Git for Windows | [`Git.Git`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/g/Git/Git/2.56.1) | Open source | DEV, Balanced | DEV | WinGet candidato [Fonte do produto](https://gitforwindows.org/) |
| GitHub CLI | [`GitHub.cli`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/g/GitHub/cli/2.105.0) | Open source | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://cli.github.com/) |

### Dev / Docker e WSL

| Aplicativo | ID WinGet | Licença ou acesso | Exibir em | Marcado por padrão em | Entrega e fonte |
|---|---|---|---|---|---|
| Docker Desktop | [`Docker.DockerDesktop`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/d/Docker/DockerDesktop/4.100.0) | Grátis conforme elegibilidade / assinatura em outros casos | DEV | Nenhuma | WinGet candidato · Validar virtualização, requisitos do host e termos. [Fonte do produto](https://docs.docker.com/subscription-billing/desktop-license/) |
| WSL | [`Microsoft.WSL`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/m/Microsoft/WSL/3.0.5) | Open source | DEV | Nenhuma | WinGet candidato · Checar virtualização e recursos do Windows. A distribuição é uma escolha separada. [Fonte do produto](https://learn.microsoft.com/windows/wsl/) |
| Ubuntu 24.04 LTS para WSL | [`Canonical.Ubuntu.2404`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/c/Canonical/Ubuntu/2404/2404.0.5.0) | Open source / componentes com licenças variadas | DEV | Nenhuma | WinGet candidato · Exige WSL e inicialização da distribuição pelo usuário. [Fonte do produto](https://ubuntu.com/desktop/wsl) |

### Dev / Terminais

| Aplicativo | ID WinGet | Licença ou acesso | Exibir em | Marcado por padrão em | Entrega e fonte |
|---|---|---|---|---|---|
| Windows Terminal | [`Microsoft.WindowsTerminal`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/m/Microsoft/WindowsTerminal/1.25.3131.0) | Open source | DEV, Balanced | DEV | WinGet candidato · Detectar instalação existente. [Fonte do produto](https://docs.microsoft.com/windows/terminal) |
| PowerShell 7 | [`Microsoft.PowerShell`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/m/Microsoft/PowerShell/7.7.0.0) | Open source | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://microsoft.com/PowerShell) |
| WezTerm | [`wez.wezterm`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/w/wez/wezterm/20240203-110809-5046fc22) | Open source | DEV | Nenhuma | WinGet candidato [Fonte do produto](https://wezterm.org) |

### Dev / Bancos

| Aplicativo | ID WinGet | Licença ou acesso | Exibir em | Marcado por padrão em | Entrega e fonte |
|---|---|---|---|---|---|
| PostgreSQL 18 | [`PostgreSQL.PostgreSQL.18`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/p/PostgreSQL/PostgreSQL/18/18.7-2) | Open source | DEV | Nenhuma | WinGet candidato · Servidor local. Porta, senha e serviço requerem configuração. [Fonte do produto](https://www.postgresql.org/download/windows/) |
| SQLite CLI | [`SQLite.SQLite`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/s/SQLite/SQLite/3.54.1) | Domínio público | DEV | Nenhuma | WinGet candidato [Fonte do produto](https://sqlite.org/) |
| DBeaver Community | [`DBeaver.DBeaver.Community`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/d/DBeaver/DBeaver/Community/26.2.5) | Open source | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://dbeaver.io/download/) |
| DB Browser for SQLite | [`DBBrowserForSQLite.DBBrowserForSQLite`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/d/DBBrowserForSQLite/DBBrowserForSQLite/3.13.1) | Open source | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://sqlitebrowser.org/dl/) |

### Utilitários

| Aplicativo | ID WinGet | Licença ou acesso | Exibir em | Marcado por padrão em | Entrega e fonte |
|---|---|---|---|---|---|
| 7-Zip | [`7zip.7zip`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/7/7zip/7zip/26.06) | Open source, com restrições do unRAR | DEV, Balanced, Full Performance | Nenhuma | WinGet candidato [Fonte do produto](https://www.7-zip.org/license.txt) |
| Microsoft PowerToys | [`Microsoft.PowerToys`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/m/Microsoft/PowerToys/0.102.3101) | Open source | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://github.com/microsoft/PowerToys) |
| Everything | [`voidtools.Everything`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/v/voidtools/Everything/1.4.1.1032) | Grátis | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://www.voidtools.com/faq/) |
| Rufus | [`Rufus.Rufus`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/r/Rufus/Rufus/4.16) | Open source | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://rufus.ie/) |
| CrystalDiskInfo | [`CrystalDewWorld.CrystalDiskInfo`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/c/CrystalDewWorld/CrystalDiskInfo/9.9.5) | Open source | DEV, Balanced, Full Performance | Nenhuma | Link oficial · Canal WinGet usa hospedagem externa. Encaminhar à página do projeto. [Fonte do produto](https://crystalmark.info/en/software/crystaldiskinfo/) |
| HWiNFO | [`REALiX.HWiNFO`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/r/REALiX/HWiNFO/8.60) | Grátis para uso não comercial / pago para uso comercial | DEV, Balanced, Full Performance | Nenhuma | Link oficial · O fabricante lista o espelho do manifesto. O v0 encaminha à página do fabricante. [Fonte do produto](https://www.hwinfo.com/download/) |
| SumatraPDF | [`SumatraPDF.SumatraPDF`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/s/SumatraPDF/SumatraPDF/3.6.1) | Open source | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://github.com/sumatrapdfreader/sumatrapdf) |

### Mídia

| Aplicativo | ID WinGet | Licença ou acesso | Exibir em | Marcado por padrão em | Entrega e fonte |
|---|---|---|---|---|---|
| VLC | [`VideoLAN.VLC`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/v/VideoLAN/VLC/3.0.24) | Open source | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://www.videolan.org/vlc/) |
| OBS Studio | [`OBSProject.OBSStudio`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/o/OBSProject/OBSStudio/33.0.1) | Open source | DEV, Balanced, Full Performance | Nenhuma | WinGet candidato [Fonte do produto](https://obsproject.com/) |
| Audacity | [`Audacity.Audacity`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/a/Audacity/Audacity/4.0.2.263060742) | Open source | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://www.audacityteam.org/) |
| HandBrake | [`HandBrake.HandBrake`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/h/HandBrake/HandBrake/1.11.2) | Open source | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://handbrake.fr/) |
| GIMP | [`GIMP.GIMP.3`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/g/GIMP/GIMP/3/3.2.8.0) | Open source | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://www.gimp.org/downloads/) |

### Games / Launchers

| Aplicativo | ID WinGet | Licença ou acesso | Exibir em | Marcado por padrão em | Entrega e fonte |
|---|---|---|---|---|---|
| Steam | [`Valve.Steam`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/v/Valve/Steam/2.10.91.91) | Grátis, com jogos pagos | Balanced, Full Performance | Nenhuma | WinGet candidato [Fonte do produto](https://store.steampowered.com/about/) |
| Epic Games Launcher | [`EpicGames.EpicGamesLauncher`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/e/EpicGames/EpicGamesLauncher/1.3.210.0) | Grátis, com jogos pagos | Balanced, Full Performance | Nenhuma | WinGet candidato [Fonte do produto](https://epicgames.com/download) |
| GOG GALAXY | [`GOG.Galaxy`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/g/GOG/Galaxy/2.1.10.56) | Grátis, com jogos pagos | Balanced, Full Performance | Nenhuma | WinGet candidato [Fonte do produto](https://www.gog.com/galaxy) |
| Playnite | [`Playnite.Playnite`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/p/Playnite/Playnite/10.63) | Open source | Balanced, Full Performance | Nenhuma | WinGet candidato [Fonte do produto](https://playnite.link/) |

### Games / Drivers

| Aplicativo | ID WinGet | Licença ou acesso | Exibir em | Marcado por padrão em | Entrega e fonte |
|---|---|---|---|---|---|
| NVIDIA App | não verificado | Grátis | Balanced, Full Performance | Nenhuma | Link oficial · Página oficial. [Fonte do produto](https://www.nvidia.com/pt-br/software/nvidia-app/) · [Solicitação no winget-pkgs](https://github.com/microsoft/winget-pkgs/issues/348600) |
| Drivers gráficos NVIDIA | não verificado | Grátis | Balanced, Full Performance | Nenhuma | Link oficial · Página oficial por GPU. [Fonte do produto](https://www.nvidia.com/Download/index.aspx) |
| AMD Software Adrenalin Edition | não verificado | Grátis | Balanced, Full Performance | Nenhuma | Link oficial · Página oficial por GPU. [Fonte do produto](https://www.amd.com/en/support/download/drivers.html) |
| Intel Driver & Support Assistant | [`Intel.IntelDriverAndSupportAssistant`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/i/Intel/IntelDriverAndSupportAssistant/26.2.0.7) | Grátis | Balanced, Full Performance | Nenhuma | WinGet candidato · Ferramenta de detecção. Considerar drivers OEM. [Fonte do produto](https://www.intel.com/content/www/us/en/support/detect.html) |

### Games / Overlays

| Aplicativo | ID WinGet | Licença ou acesso | Exibir em | Marcado por padrão em | Entrega e fonte |
|---|---|---|---|---|---|
| MSI Afterburner | [`Guru3D.Afterburner`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/g/Guru3D/Afterburner/4.6.6) | Grátis | Balanced, Full Performance | Nenhuma | Link oficial · Manifesto usa ZIP em espelho de terceiros. A instalação automática fica fora do v0. [Fonte do produto](https://www.msi.com/Landing/afterburner/graphics-cards) |
| RivaTuner Statistics Server | [`Guru3D.RTSS`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/g/Guru3D/RTSS/7.3.7) | Grátis | Balanced, Full Performance | Nenhuma | Link oficial · Manifesto usa ZIP em espelho de terceiros. A instalação automática fica fora do v0. [Fonte do produto](https://www.guru3d.com/download/rtss-rivatuner-statistics-server-download/) |
| CapFrameX | [`CXWorld.CapFrameX`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/c/CXWorld/CapFrameX/1.9.2.4) | Open source | Balanced, Full Performance | Nenhuma | WinGet candidato [Fonte do produto](https://github.com/CXWorld/CapFrameX) |

### Personalização

| Aplicativo | ID WinGet | Licença ou acesso | Exibir em | Marcado por padrão em | Entrega e fonte |
|---|---|---|---|---|---|
| Windhawk | [`RamenSoftware.Windhawk`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/r/RamenSoftware/Windhawk/1.7.3) | Open source | DEV, Balanced | Nenhuma | Aguardando teste em VM · Mods separados e sujeitos a revisão de compatibilidade. [Fonte do produto](https://github.com/ramensoftware/windhawk/blob/main/LICENSE) |
| ExplorerPatcher | [`valinet.ExplorerPatcher`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/v/valinet/ExplorerPatcher/26100.9711.71.3) | Open source | DEV, Balanced | Nenhuma | Aguardando teste em VM · Validar build e atualização cumulativa em VM antes de liberar. [Fonte do produto](https://github.com/valinet/ExplorerPatcher) |
| Open-Shell | [`Open-Shell.Open-Shell-Menu`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/o/Open-Shell/Open-Shell-Menu/4.4.198) | Open source | DEV, Balanced | Nenhuma | Aguardando teste em VM · Testar combinações que alteram o menu Iniciar. [Fonte do produto](https://open-shell.github.io/Open-Shell-Menu/) |
| TranslucentTB | [`CharlesMilette.TranslucentTB`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/c/CharlesMilette/TranslucentTB/2026.2.0.0) | Open source | DEV, Balanced | Nenhuma | WinGet candidato [Fonte do produto](https://github.com/TranslucentTB/TranslucentTB) |
| Rainmeter | [`Rainmeter.Rainmeter`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/r/Rainmeter/Rainmeter/4.5.28.3936) | Open source | DEV, Balanced | Nenhuma | WinGet candidato · Skins de terceiros são escolhas separadas. [Fonte do produto](https://www.rainmeter.net/) |
| StartAllBack | [`StartIsBack.StartAllBack`](https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/s/StartIsBack/StartAllBack/3.9.28) | Pago, com avaliação | Balanced | Nenhuma | Link oficial · Validar compatibilidade com a build e outras extensões do shell. Canal WinGet usa hospedagem externa. Encaminhar à página do projeto. [Fonte do produto](https://www.startallback.com/) |

## Tweaks candidatos

Todos começam **desmarcados**. O risco abaixo considera o efeito e a recuperação na máquina. **Baixo** é localizado e fácil de restaurar. **Médio** pode afetar aplicativos, fluxo de trabalho ou bateria. **Alto** envolve armazenamento ou impacto mais amplo e fica em modo guia no v0. “Sim” indica que a configuração pode voltar ao estado anterior, respeitando os limites indicados. Nenhum ganho de desempenho foi medido.

| Grupo | Candidato | Edições | Risco | Reversível | Efeito e fonte |
|---|---|---|---|---|---|
| Privacidade | Desativar ID de publicidade | DEV, Balanced, Full Performance | Baixo | Parcial | O controle volta, mas reativá-lo redefine o identificador. [Microsoft](https://support.microsoft.com/en-us/windows/privacy/privacy-settings-for-recommendations-offers-in-windows-11) |
| Privacidade | Desativar ofertas personalizadas | DEV, Balanced | Baixo | Sim | Reduz recomendações personalizadas na conta local. [Microsoft](https://support.microsoft.com/en-us/windows/privacy/privacy-settings-for-recommendations-offers-in-windows-11) |
| Privacidade | Desativar envio de diagnóstico opcional | DEV, Balanced, Full Performance | Baixo | Sim | Restaura a preferência de envio. Dados já enviados não são recuperáveis pela toolbox. Respeitar políticas de organização. [Microsoft](https://support.microsoft.com/en-us/windows/privacy/diagnostics-feedback-and-privacy-in-windows) |
| Privacidade e rede | Desativar compartilhamento entre PCs na Otimização de Entrega | DEV, Balanced, Full Performance | Baixo | Sim | Windows Update e Store continuam usando os servidores da Microsoft. [Microsoft](https://support.microsoft.com/pt-br/windows/deployment/updates-lifecycle/delivery-optimization-in-windows) |
| Desempenho | Revisar inicialização por aplicativo | DEV, Balanced, Full Performance | Médio | Sim | Usuário escolhe cada app. Pode atrasar lembretes ou sincronização. [Microsoft](https://support.microsoft.com/en-us/windows/experience/startup-boot/configure-startup-applications-in-windows) |
| Desempenho | Reduzir efeitos visuais | Balanced, Full Performance | Baixo | Sim | Guardar a seleção anterior de cada efeito alterado e preservar a escolha de acessibilidade. [Microsoft](https://support.microsoft.com/en-gb/windows/experience/performance-optimization/tips-to-improve-pc-performance-in-windows) |
| Desempenho | Modo de energia “Melhor desempenho” | Full Performance | Médio | Sim | Oferecer quando disponível, com indicação de consumo, calor e autonomia. [Microsoft](https://support.microsoft.com/en-gb/windows/experience/performance-optimization/tips-to-improve-pc-performance-in-windows) |
| Gamer | Ativar Modo de Jogo | Balanced, Full Performance | Baixo | Sim | Mostrar o estado atual e só alterar se o usuário pedir. [Microsoft](https://support.microsoft.com/en-gb/accessibility/windows/understand-and-explore-windows-settings) |
| Gamer | Desativar gravação em segundo plano | Full Performance | Baixo | Sim | A opção de gravar o que acabou de acontecer fica indisponível enquanto desligada. [Microsoft](https://support.microsoft.com/en-gb/accessibility/windows/understand-and-explore-windows-settings) |
| Gamer | Preferência de GPU por jogo | Balanced, Full Performance | Médio | Sim | Aplicar a um jogo por vez em PCs com mais de uma GPU. Restaurar preferência ou remover a regra criada. [Microsoft](https://support.microsoft.com/en-au/windows/hardware/display-graphics/optimizations-for-windowed-games-in-windows-11) |
| Gamer | Otimizações para jogos em janela | Balanced, Full Performance | Médio | Sim | Testar por jogo compatível, com opção de voltar se houver problemas gráficos. [Microsoft](https://support.microsoft.com/en-au/windows/hardware/display-graphics/optimizations-for-windowed-games-in-windows-11) |
| Dev | Mostrar extensões de arquivo no Explorer | DEV, Balanced | Baixo | Sim | Preferência por usuário. [Microsoft](https://learn.microsoft.com/en-us/windows/advanced-settings) |
| Dev | Habilitar caminhos longos para apps compatíveis | DEV | Baixo | Sim | Reverter a configuração pode impedir apps antigos de abrir caminhos longos já criados. [Microsoft](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation) |
| Dev | Ativar Modo de Desenvolvedor | DEV | Médio | Sim | Opt-in para desenvolvimento Windows. Device Portal e descoberta de dispositivos são escolhas separadas. [Microsoft](https://learn.microsoft.com/en-us/windows/apps/get-started/developer-mode-features-and-debugging) |
| Dev | Habilitar recursos do WSL 2 | DEV | Médio | Parcial | Checar virtualização e reinicialização. Reverter apenas os recursos que a toolbox mudou, preservando distribuições e arquivos. Verificar dependências do Docker. [Microsoft](https://learn.microsoft.com/en-us/windows/wsl/install) · [Docker](https://docs.docker.com/desktop/setup/install/windows-install/) |
| Dev | Criar Dev Drive | DEV | Alto | Parcial | Guia para novo volume com espaço disponível. Remover o volume requer migrar os dados. [Microsoft](https://learn.microsoft.com/en-us/windows/dev-drive/) |

Defender, firewall, SmartScreen, Windows Update e checagens de integridade fazem parte da base de segurança das três edições. Remoções em massa de componentes, alterações genéricas de serviços e políticas de mitigação ficam fora dos candidatos do v0. Ajustes automatizados elegíveis devem passar por teste em VM por build antes de entrar em um perfil.

## Proposta de contrato JSON

Cid aprovou o contrato de apps e tweaks. O exemplo de tweak segue o contrato comum da arquitetura. A matriz inicial da arquitetura é Windows 11 25H2 x64, Home e Pro. [Arquitetura v0](../docs/01-arquitetura-v0.md#3-contrato-comum-de-tweaks)

Os IDs e as chaves de edição são estáveis. O perfil BigZ guarda a pré-seleção após login em `firstUseAppDefaults` para apps e `firstUseDefaults` para tweaks. `optionalTweaks` referencia os ajustes opcionais. A coluna de marcação da tabela propõe os IDs para `firstUseAppDefaults` em cada perfil. A toolbox valida referências de perfil, chaves únicas, dependências e ciclos, conflitos e versões de esquema antes de resolver o plano.

Caminhos alinhados com Engenharia incluem `toolbox/catalog/apps.json` para apps, `shared/tweaks/` para os objetos de tweak, `shared/profiles/` para perfis e `shared/schemas/` para os esquemas.

### Exemplo de aplicativo

O arquivo de apps usa um envelope com `schemaVersion` e `apps`. O item compartilha `id`, `editions`, `requires`, `dependsOn` e `conflictsWith` com os tweaks. A sugestão para o perfil DEV é incluir o ID `git` em `firstUseAppDefaults`.

```json
{
  "schemaVersion": 1,
  "apps": [
    {
      "schemaVersion": 1,
      "id": "git",
      "name": "Git for Windows",
      "category": "dev.git",
      "editions": [
        "dev",
        "balanced"
      ],
      "risk": "medium",
      "license": {
        "kind": "open-source",
        "name": "Open source",
        "url": "https://github.com/git-for-windows/build-extra/blob/HEAD/LICENSE.txt"
      },
      "delivery": {
        "provider": "winget",
        "source": "winget",
        "packageId": "Git.Git",
        "manifestUrl": "https://github.com/microsoft/winget-pkgs/tree/0a094c1dc5d5a3e795cbf935e8c75199f7be0d96/manifests/g/Git/Git/2.56.1",
        "officialUrl": "https://gitforwindows.org/",
        "scope": "user",
        "allowedInstallerUrls": [
          "https://github.com/git-for-windows/git/releases/download/v2.56.1.windows.1/"
        ]
      },
      "requires": {
        "builds": [
          26200
        ],
        "architectures": [
          "x64"
        ],
        "admin": false
      },
      "dependsOn": [],
      "conflictsWith": [],
      "description": "Git for Windows via WinGet.",
      "phase": "online",
      "scope": "currentUser",
      "securityImpact": "none",
      "action": {
        "type": "winget.install"
      },
      "verify": {
        "type": "winget.detectPackage"
      },
      "rollback": {
        "type": "winget.uninstallIfNew"
      },
      "restart": "none"
    }
  ]
}
```

- `license.kind` admite `open-source`, `freeware`, `paid`, `freemium`, `conditional`, `public-domain` e `bundled`. `name` descreve a licença ou os termos. `url` aponta para a fonte.
- `delivery.provider` admite `winget`, `official-link` e `windows-settings`. WinGet exige `source`, `packageId`, `manifestUrl`, `officialUrl`, `scope` e as origens permitidas. `scope` usa o escopo do instalador (`user` ou `machine`). O tipo `official-link` abre `officialUrl`. `windows-settings` resolve um destino conhecido pela toolbox.
- A checagem de origem compara esquema, host e caminho normalizados. Validar redirecionamentos contra a procedência permitida para o publicador, inclusive a CDN de assets do GitHub quando aplicável. Detectar instalação existente na sessão correta e verificar versão e resultado após a execução. Tratar reinício pendente separadamente da falha.

### Exemplo de tweak

Cada tweak usa o objeto versionado do contrato comum. A lista acima inclui ideias em modo guia. Só candidatos validados com executor compatível entram no catálogo executável.

```json
{
  "schemaVersion": 1,
  "id": "explorer.show-file-extensions",
  "description": "Mostrar extensões de arquivo conhecidas no Explorer",
  "risk": "low",
  "editions": [
    "dev",
    "balanced"
  ],
  "phase": "online",
  "scope": "currentUser",
  "requires": {
    "builds": [
      26200
    ],
    "architectures": [
      "x64"
    ],
    "admin": false
  },
  "dependsOn": [],
  "conflictsWith": [],
  "action": {
    "type": "registry.setValue",
    "key": "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
    "name": "HideFileExt",
    "valueType": "DWord",
    "value": 0
  },
  "verify": {
    "type": "registry.matchesAction"
  },
  "rollback": {
    "type": "restoreSnapshot"
  },
  "restart": "none",
  "securityImpact": "none",
  "source": "https://learn.microsoft.com/en-us/windows/advanced-settings"
}
```

- `phase` separa `offline` de `online`. A toolbox pós-login só executa ações `online`. Operações da conta solicitante usam `currentUser`. Ações de máquina passam pelo executor elevado, que resolve o ID na própria cópia do catálogo e verifica os parâmetros tipados.
- `risk` admite `low`, `medium` e `high`. `rollback` declara a estratégia de reversão. Os limites de recuperação aparecem na descrição ao usuário. O validador rejeita ações desconhecidas e comandos livres.
- Capturar tipo, valor, existência e contexto antes de escrever. Registrar o progresso por alvo e conservar a captura inicial ao reaplicar. Para reverter, comparar o estado atual com o que a toolbox escreveu. Registrar divergências e preservar alterações externas. Oferecer prévia sem mutação e indicar se `restart` requer reinício.

A validação desta entrega é documental. Execução de instaladores, compatibilidade por build e reversão em VM ficam para a implementação.
