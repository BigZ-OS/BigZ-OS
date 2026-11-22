# BigZ OS — Catálogo de Presets de Shell para a Toolbox (v0)

> **Documento de Interface Design ↔ Toolbox (Yuna & Rikku)**  
> **Status:** Especificação de Presets Opcionais e Reversíveis  
> **Data:** Novembro de 2026  
> **Conformidade:** ADR-004 (Contrato de Tweaks) e Decisão de Shell Opcional (docs/03-plano-consolidado.md)

---

## 1. Diretriz de Arquitetura

Conforme alinhado na Rodada 2 com Auron e Cid:
1. **O shell padrão do Windows 11 permanece intacto por padrão em todas as edições.**
2. Todas as customizações visuais de shell (Open-Shell, Nilesoft Shell e TranslucentTB) são **presets opcionais da Toolbox**, categorizados com risco verde 🟢 (auditáveis, isolados e 100% reversíveis).
3. Nenhuma ferramenta que realize patch direto em binários ou DLLs do Windows (como ExplorerPatcher ou patchers de UXTheme) é incluída no catálogo padrão.
4. Cada preset possui:
   - Identificador único (`id`);
   - Pré-seleção sugerida por edição (DEV, Balanced, Full Performance);
   - Arquivo de configuração declarativo;
   - Script de verificação de estado (`verify`);
   - Procedimento explícito e limpo de reversão (`revert`).

---

## 2. Presets por Ferramenta

### 2.1 Open-Shell Menu (Menu Iniciar Alternativo)
* **Pacote Winget:** `Open-Shell.Open-Shell-Menu`
* **Licença:** MIT (Open Source)
* **Processo:** `ClassicStartMenu.exe`
* **Como reverte:** Encerra o processo `ClassicStartMenu.exe`, remove a entrada de inicialização do registro (`HKCU\Software\Microsoft\Windows\CurrentVersion\Run`) e, se desinstalado, remove a pasta de configuração. O menu padrão do Windows 11 reassume instantaneamente.

#### Presets:
1. **`shell-openshell-dev`**
   * *Nome Amigável:* Open-Shell DEV Dark
   * *Edição Padrão:* **DEV** (pré-selecionado)
   * *O que configura:* Layout de duas colunas compacto em modo escuro; atalhos fixados no painel direito para `C:\DEV`, Windows Terminal (Admin), WSL e VS Code; pesquisa local rápida ativada; itens inúteis de telemetria ocultos.
   * *Arquivo de Configuração:* `assets/presets/openshell/dev-dark.xml`
2. **`shell-openshell-balanced`**
   * *Nome Amigável:* Open-Shell Clean Fluent
   * *Edição Padrão:* **Balanced** (opcional, desmarcado por padrão — Balanced usa o menu nativo higienizado)
   * *O que configura:* Visual clássico com bordas suaves e fontes modernas do sistema, organizado em pastas limpas.
   * *Arquivo de Configuração:* `assets/presets/openshell/balanced.xml`
3. **`shell-openshell-perf`**
   * *Nome Amigável:* Open-Shell Minimal Gamer
   * *Edição Padrão:* **Full Performance** (pré-selecionado)
   * *O que configura:* Menu ultra-enxuto de coluna única; todas as animações de abertura desativadas; zero cache de miniaturas; abertura instantânea via tecla Win.
   * *Arquivo de Configuração:* `assets/presets/openshell/perf-minimal.xml`

---

### 2.2 Nilesoft Shell (Menu de Contexto do Botão Direito)
* **Pacote Winget:** `Nilesoft.Shell`
* **Licença:** MIT (Open Source)
* **Mecanismo:** Shell Extension nativa declarativa configurada via script `.nss`
* **Como reverte:** Desregistra a extensão de contexto (`shell.exe -u`), restaurando o menu de contexto padrão do Windows sem afetar arquivos de sistema.

#### Presets:
1. **`shell-nilesoft-dev`**
   * *Nome Amigável:* Nilesoft Dev Context Menu
   * *Edição Padrão:* **DEV** (pré-selecionado)
   * *O que configura:* Insere no topo do menu de contexto de pastas e arquivos: "Abrir no Windows Terminal", "Abrir com VS Code", "Git Bash Here", "Copiar Caminho Absoluto"; suprime menus redundantes de aplicativos da Store.
   * *Arquivo de Configuração:* `assets/presets/nilesoft/dev-shell.nss`
2. **`shell-nilesoft-balanced`**
   * *Nome Amigável:* Nilesoft Fluent Clean
   * *Edição Padrão:* **Balanced** (pré-selecionado)
   * *O que configura:* Substitui o menu do Windows 11 (que exige "Mostrar mais opções") por um menu único com cantos arredondados, ícones vetorizados nítidos e apenas ações úteis.
   * *Arquivo de Configuração:* `assets/presets/nilesoft/balanced-shell.nss`
3. **`shell-nilesoft-minimal`**
   * *Nome Amigável:* Nilesoft Minimal Core
   * *Edição Padrão:* **Full Performance** (opcional, desmarcado por padrão — Full Performance usa o menu clássico nativo via chave de registro `InprocServer32`)
   * *O que configura:* Menu reduzido apenas com copiar, recortar, colar, renomear e propriedades.
   * *Arquivo de Configuração:* `assets/presets/nilesoft/perf-shell.nss`

---

### 2.3 TranslucentTB (Barra de Tarefas com Efeitos Visuais)
* **Pacote Winget:** `CharlesMilette.TranslucentTB` (verificado no catálogo oficial)
* **Licença:** GPL-3.0 (Open Source)
* **Processo:** `TranslucentTB.exe`
* **Como reverte:** Finaliza o processo `TranslucentTB.exe` e remove do Startup. A barra de tarefas retorna imediatamente à cor sólida ou padrão do Windows.

#### Presets:
1. **`shell-translucent-acrylic`**
   * *Nome Amigável:* TranslucentTB Dark Acrylic
   * *Edição Padrão:* **DEV** (pré-selecionado)
   * *O que configura:* Acrílico escuro com opacidade sutil (85% opaco / 15% desfoque), garantindo alto contraste com janelas de código e terminais.
   * *Configuração:* JSON de configuração local (`config.json` em `%APPDATA%\TranslucentTB`).
2. **`shell-translucent-fluent`**
   * *Nome Amigável:* TranslucentTB Dynamic Fluent
   * *Edição Padrão:* **Balanced** (pré-selecionado)
   * *O que configura:* Modo dinâmico: 100% transparente ("Clear") quando na Área de Trabalho e "Acrílico" quando qualquer janela estiver maximizada.
   * *Configuração:* JSON dinâmico de estados.
3. **`shell-translucent-disabled`**
   * *Nome Amigável:* Barra Sólida Nativa (TranslucentTB Desativado)
   * *Edição Padrão:* **Full Performance** (pré-selecionado)
   * *O que configura:* Garante que o app não seja executado, mantendo a barra de tarefas em cor escura sólida nativa para não onerar o Desktop Window Manager (DWM).

---

## 3. Matriz de Pré-Seleção por Edição na Toolbox

| Preset ID | Ferramenta | Edição DEV | Edição Balanced | Edição Full Performance | Categoria de Risco |
|---|---|:---:|:---:|:---:|:---:|
| `shell-openshell-dev` | Open-Shell | ☑ **Marcado** | ☐ Desmarcado | ☐ Desmarcado | 🟢 Seguro |
| `shell-openshell-balanced` | Open-Shell | ☐ Desmarcado | ☐ Desmarcado | ☐ Desmarcado | 🟢 Seguro |
| `shell-openshell-perf` | Open-Shell | ☐ Desmarcado | ☐ Desmarcado | ☑ **Marcado** | 🟢 Seguro |
| `shell-nilesoft-dev` | Nilesoft Shell | ☑ **Marcado** | ☐ Desmarcado | ☐ Desmarcado | 🟢 Seguro |
| `shell-nilesoft-balanced` | Nilesoft Shell | ☐ Desmarcado | ☑ **Marcado** | ☐ Desmarcado | 🟢 Seguro |
| `shell-nilesoft-minimal` | Nilesoft Shell | ☐ Desmarcado | ☐ Desmarcado | ☐ Desmarcado | 🟢 Seguro |
| `shell-translucent-acrylic` | TranslucentTB | ☑ **Marcado** | ☐ Desmarcado | ☐ Desmarcado | 🟢 Seguro |
| `shell-translucent-fluent` | TranslucentTB | ☐ Desmarcado | ☑ **Marcado** | ☐ Desmarcado | 🟢 Seguro |
| `shell-translucent-disabled` | Nativo / Sólido | ☐ Desmarcado | ☐ Desmarcado | ☑ **Marcado** | 🟢 Seguro |

---

## 4. Contrato JSON para a Rikku (`catalog/tweaks.json`)

Modelo do contrato em conformidade com a ADR-004:

```json
{
  "id": "shell-nilesoft-dev",
  "category": "shell",
  "title": "Menu de Contexto Dev (Nilesoft Shell)",
  "description": "Adiciona atalhos rápidos para Windows Terminal, VS Code e Git no menu de contexto.",
  "risk": "green",
  "scope": "user",
  "editionDefaults": {
    "dev": true,
    "balanced": false,
    "full_performance": false
  },
  "package": "Nilesoft.Shell",
  "configFile": "assets/presets/nilesoft/dev-shell.nss",
  "apply": {
    "command": "winget install -e --id Nilesoft.Shell --accept-source-agreements --accept-package-agreements; Copy-Item -Path $PresetConfig -Destination $NilesoftConfig -Force; & 'C:\\Program Files\\Nilesoft Shell\\shell.exe' -i"
  },
  "revert": {
    "command": "& 'C:\\Program Files\\Nilesoft Shell\\shell.exe' -u"
  },
  "verify": {
    "command": "Test-Path 'C:\\Program Files\\Nilesoft Shell\\shell.dll'"
  }
}
```
