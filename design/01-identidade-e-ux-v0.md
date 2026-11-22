# BigZ OS — Identidade Visual, Shell & UX (v0)

> **Documento de Entrega — Setor de Design & UX (Yuna)**  
> **Status:** Aprovado na Rodada 1 / Revisado para a Rodada 2  
> **Data:** Novembro de 2026  
> **Destinatário:** Auron (Diretoria do Projeto BigZ OS)  
> **Conformidade Legal & Técnica:** ADR-001 a ADR-009 (`docs/03-plano-consolidado.md`). Código aberto, seguro, sem binários opacos e 100% reversível.

---

## 1. Pesquisa Técnica: Como Projetos Atuais Personalizam o Shell

Para viabilizar a visão do BigZ OS — um ambiente refinado, moderno e com alto nível de personalização, mantendo a estabilidade e a segurança intactas —, foi conduzida uma análise comparativa dos principais projetos e ferramentas de modding de shell para Windows 11 (especialmente as versões 23H2 e 24H2).

### 1.1 Panorama das Ferramentas Analisadas

#### A. Windhawk (Ramen Software)
* **Repositório / Fonte:** [github.com/ramensoftware/windhawk](https://github.com/ramensoftware/windhawk) | [windhawk.net](https://windhawk.net)
* **Licença:** Código do motor parcialmente aberto / Mods comunitários são 100% open source ([github.com/ramensoftware/windhawk-mods](https://github.com/ramensoftware/windhawk-mods)).
* **Mecanismo:** Motor de injeção dinâmica em tempo real com compilação local de C++. Injeta em memória sem modificar arquivos originais do sistema em disco.
* **Consumo de Recursos:** Leve (~15 MB a 30 MB de RAM base; CPU ~0% em repouso).
* **Comportamento em Updates (23H2/24H2):** A atualização 24H2 alterou a arquitetura do `explorer.exe`. Mods desatualizados causaram instabilidade inicial, solucionada com novas variantes da comunidade. Possui modo de segurança automático (desativa o mod caso o explorer falhe na inicialização).
* **Decisão para BigZ OS:** **Opcional modular na Toolbox**. Disponível para usuários avançados que desejam tweaks específicos, com reversão em 1 clique.

#### B. ExplorerPatcher (Valinet)
* **Repositório / Fonte:** [github.com/valinet/ExplorerPatcher](https://github.com/valinet/ExplorerPatcher)
* **Licença:** GNU General Public License v2.0 (GPLv2).
* **Mecanismo:** Hooking em baixo nível e reativação de bibliotecas herdadas do Windows 10.
* **Comportamento em Updates (23H2/24H2):** **Alto risco de quebra**. A Microsoft implementou travas de compatibilidade (*safeguard holds*) que impediram a atualização direta para a 24H2 com o software instalado. Atualizações cumulativas frequentes geram tela preta até que novos patches sejam lançados.
* **Decisão para BigZ OS:** **Não recomendado como padrão**. Desacoplado do sistema para evitar falhas pós-atualização do sistema operacional.

#### C. Open-Shell (Fork Comunitário do Classic Shell)
* **Repositório / Fonte:** [github.com/Open-Shell/Open-Shell-Menu](https://github.com/Open-Shell/Open-Shell-Menu)
* **Licença:** MIT License (100% livre e permissiva).
* **Mecanismo:** Processo isolado em segundo plano (`ClassicStartMenu.exe`) que sobrepõe um menu clássico sem injetar código invasivo no kernel do explorer.
* **Consumo de Recursos:** Ultra-leve (~8 MB a 20 MB de RAM; 0% CPU).
* **Comportamento em Updates (23H2/24H2):** **Muito estável**. Não depende de estruturas de memória voláteis do explorer moderno.
* **Decisão para BigZ OS:** **Preset visual opcional da Toolbox** (pré-selecionado na edição DEV e Full Performance; reversível a qualquer momento).

#### D. StartAllBack
* **Fonte:** [startallback.com](https://www.startallback.com)
* **Licença:** **Proprietária / Paga** (Shareware comercial fechado, US$ 4,99).
* **Decisão para BigZ OS:** **Rejeitado**. O BigZ OS tem compromisso inegociável com gratuidade, transparência e código aberto auditável.

#### E. TranslucentTB
* **Repositório / Fonte:** [github.com/TranslucentTB/TranslucentTB](https://github.com/TranslucentTB/TranslucentTB)
* **Licença:** GNU General Public License v3.0 (GPLv3).
* **Mecanismo:** Aplicação de usuário que consome APIs oficiais de composição de janela (`SetWindowCompositionAttribute`) para gerar efeitos translúcidos e acrílicos na barra de tarefas.
* **Consumo de Recursos:** Imperceptível (~10 MB a 15 MB de RAM; 0% CPU).
* **Comportamento em Updates (23H2/24H2):** Estável. Em caso de mudanças de API pela Microsoft, a barra simplesmente reverte para o estado opaco sem travar o sistema.
* **Decisão para BigZ OS:** **Preset visual opcional da Toolbox** (pré-selecionado na edição Balanced e DEV).

#### F. Rainmeter
* **Repositório / Fonte:** [github.com/rainmeter/rainmeter](https://github.com/rainmeter/rainmeter)
* **Licença:** GNU General Public License v2.0 (GPLv2).
* **Consumo de Recursos:** 30 MB a 70 MB de RAM base. Skins com animações em alta frequência podem consumir ciclos desnecessários de CPU/GPU.
* **Decisão para BigZ OS:** **Não incluso na inicialização padrão**. Ofertado apenas como catálogo de extras opcionais.

#### G. Nilesoft Shell
* **Repositório / Fonte:** [github.com/mrfdev/shell](https://github.com/mrfdev/shell) | [nilesoft.org](https://nilesoft.org)
* **Licença:** MIT License.
* **Mecanismo:** Extensão de shell nativa declarativa em C++ via script `shell.nss`.
* **Consumo de Recursos:** Mínimo (< 5 MB de RAM; 0% CPU).
* **Comportamento em Updates (23H2/24H2):** Altamente estável, compatível nativamente com o menu moderno do Windows 11.
* **Decisão para BigZ OS:** **Preset visual opcional da Toolbox** (com perfil de atalhos DEV e perfil limpo Balanced).

---

### 1.2 Tabela Comparativa de Ferramentas de Shell

| Ferramenta | Licença | Modelo de Execução | RAM / CPU | Estabilidade Win11 (24H2) | Risco de Crash | Papel no BigZ OS |
|---|---|---|---|---|---|---|
| **Nilesoft Shell** | MIT | Shell Extension nativa | ~4 MB / 0% | ★★★★★ (Excelente) | Mínimo | **Preset Opcional Toolbox** (DEV/Balanced) |
| **Open-Shell** | MIT | Processo isolado | ~15 MB / 0% | ★★★★★ (Excelente) | Mínimo | **Preset Opcional Toolbox** (DEV/Full Perf) |
| **TranslucentTB** | GPLv3 | API de composição | ~12 MB / 0% | ★★★★☆ (Muito boa) | Nulo | **Preset Opcional Toolbox** (Balanced/DEV) |
| **Windhawk** | GPLv3 / FOSS | Injeção em memória | ~20 MB / 0% | ★★★☆☆ (Requer mods 24H2) | Baixo | **Opcional Avançado na Toolbox** |
| **ExplorerPatcher** | GPLv2 | Hooking legado em DLLs | ~15 MB / 0% | ★★☆☆☆ (Bloqueado pela MS) | Alto | **Desaconselhado (risco de update)** |
| **Rainmeter** | GPLv2 | Widgets de Desktop | ~50 MB / 1-4% | ★★★★★ (Excelente) | Nulo | **Desativado (Catálogo Extra)** |
| **StartAllBack** | Proprietário | Código fechado | ~12 MB / 0% | ★★★★☆ (Boa) | Baixo | **Rejeitado (pago/fechado)** |

---

## 2. Proposta de Experiência do Shell por Edição

> **Decisão Consolidada (ADR-003 / docs/03-plano-consolidado.md):**  
> A instalação-base do BigZ OS mantém o **shell nativo do sistema operacional intacto e íntegro**.  
> Todas as personalizações visuais abaixo operam como **presets opcionais gerenciados pela Toolbox**, pré-selecionados de acordo com a edição e com reversão garantida em 1 clique.

```
                    ┌──────────────────────────────────────────────┐
                    │                 BIGZ OS CORE                 │
                    │        (Base Segura • Open Source)           │
                    │         Shell Oficial Não Modificado         │
                    └──────────────────────┬───────────────────────┘
                                           │
         ┌─────────────────────────────────┼────────────────────────────────┐
         ▼                                 ▼                                ▼
 ┌───────────────┐                 ┌───────────────┐                ┌───────────────┐
 │   BIGZ DEV    │                 │ BIGZ BALANCED │                │ BIGZ FULL PERF│
 ├───────────────┤                 ├───────────────┤                ├───────────────┤
 │ Produtividade │                 │ Equilíbrio    │                │ Desempenho    │
 │ Terminal First│                 │ Fluidez       │                │ Foco em Jogos │
 │ Alta Densidade│                 │ Estabilidade  │                │ Game Bar ON   │
 └───────────────┘                 └───────────────┘                └───────────────┘
```

---

### 2.1 Edição DEV — Foco e Produtividade para Desenvolvedores

* **Público:** Desenvolvedores de software, administradores de sistemas, estudantes e entusiastas de código.
* **Objetivo:** Acesso rápido ao terminal, ergonomia para múltiplas janelas e redução de distrações.

#### Especificação de Experiência:
1. **Taskbar:**
   * *Alinhamento:* À esquerda (previsibilidade motora ao gerenciar muitas instâncias de janelas).
   * *Rótulos:* Configurados para exibir títulos das janelas quando houver espaço.
   * *Preset Opcional na Toolbox:* `shell-translucent-acrylic` (acrílico escuro com opacidade sutil de 85%, garantindo alto contraste com código).
   * *Fixados Padrão:* Windows Terminal, VS Code, Navegador Web, Explorador de Arquivos, BigZ Toolbox.
2. **Menu Iniciar:**
   * *Base:* Menu padrão com anúncios e recomendações promocionais desativados via chaves de registro documentadas.
   * *Preset Opcional na Toolbox:* `shell-openshell-dev` (Open-Shell Dark com atalhos diretos para `C:\DEV`, Windows Terminal Administrador e WSL).
3. **Explorador de Arquivos (Explorer):**
   * Abre direto em **"Este Computador"**.
   * Modo compacto ativado (menor espaçamento de itens).
   * Extensões de arquivo e arquivos ocultos visíveis por padrão.
4. **Menu de Contexto:**
   * *Preset Opcional na Toolbox:* `shell-nilesoft-dev` (insere no topo do botão direito: "Abrir no Windows Terminal", "Abrir com VS Code", "Git Bash Here" e "Copiar Caminho").
5. **Tema e Cores:**
   * Dark Mode nativo com paleta *Matrix Green* (`#10B981`) e *Dev Cyan* (`#06B6D4`).
6. **Papel de Parede:**
   * Fundo escuro com grid cibernético geométrico e logo BigZ DEV minimalista (formato estático PNG otimizado).
7. **Esquema de Som:**
   * Alertas suaves e discretos para evitar fadiga durante sessões de desenvolvimento.

---

### 2.2 Edição Balanced — Estética, Conforto e Estabilidade

* **Público:** Usuários em geral, criadores de conteúdo e profissionais que valorizam um ambiente moderno e estável.
* **Objetivo:** O melhor do design Fluent limpo, sem telemetria agressiva ou bloatware.

#### Especificação de Experiência:
1. **Taskbar:**
   * *Alinhamento:* Centralizada.
   * *Preset Opcional na Toolbox:* `shell-translucent-fluent` (transparência dinâmica: translúcido na Área de Trabalho e acrílico desfocado ao maximizar janelas).
2. **Menu Iniciar:**
   * Menu padrão do sistema higienizado, sem sugestões de compras ou feeds de notícias de terceiros.
3. **Explorador de Arquivos:**
   * Visual moderno com abas ativas e navegação fluida em pastas pessoais e Este Computador.
4. **Menu de Contexto:**
   * *Preset Opcional na Toolbox:* `shell-nilesoft-balanced` (menu contextual em nível único, com cantos arredondados e sem a necessidade de clicar em "Mostrar mais opções").
5. **Tema e Cores:**
   * Dark Mode com paleta *Sapphire Harmony* (`#3B82F6`) e *Soft Violet* (`#8B5CF6`).
6. **Papel de Parede:**
   * Gradientes elegantes em azul e violeta com o emblema harmônico BigZ Balanced.
7. **Esquema de Som:**
   * Esquema sonoro acústico e suave para notificações.

---

### 2.3 Edição Full Performance — Máximo Desempenho e Foco em Jogos

* **Público:** Gamers competitivos e sistemas com hardware de entrada.
* **Objetivo:** Otimização orientada a desempenho com estabilidade comprovada.

#### Especificação de Experiência:
1. **Compatibilidade e Componentes Preservados:**
   * **A Xbox Game Bar é mantida ativa por padrão** (essencial para compatibilidade com Xbox App, gamepads e recursos de sincronização de jogos).
   * DirectPlay, subsistemas gráficos e agendador de GPU preservados.
2. **Taskbar:**
   * *Alinhamento:* À esquerda.
   * *Efeitos:* Efeitos de transparência desativados por padrão (barra sólida escura `#050505` para minimizar processamento do DWM).
   * *Preset Opcional:* `shell-translucent-disabled`.
3. **Menu Iniciar:**
   * *Preset Opcional na Toolbox:* `shell-openshell-perf` (menu enxuto de alta responsividade para acesso rápido a jogos e utilitários).
4. **Explorador de Arquivos:**
   * Otimizado com miniaturas funcionais e indexação leve.
5. **Menu de Contexto:**
   * Menu clássico nativo acionado via ajuste simples de registro, garantindo agilidade.
6. **Tema e Cores:**
   * Tema escuro de alto contraste com paleta *Flame Orange* (`#F97316`) e *Crimson* (`#EF4444`). Animações de janelas ajustadas para desempenho.
7. **Papel de Parede:**
   * Fundo texturizado escuro em fibra de carbono com logo BigZ Performance.
8. **Esquema de Som:**
   * Esquema de som padrão mantido ou ajustável para silencioso pelo usuário na Toolbox (sem promessas de latência sem benchmark medido).

---

## 3. Identidade da Marca BigZ OS

### 3.1 Conceito da Marca
* **Nome:** **BigZ OS**
* **Proposta de Valor:** *"O seu sistema, com a sua identidade: livre, transparente e do seu jeito."*
* **Personalidade:** Transparente, auditável, acessível e focada na comunidade.
* **Restrições Legais e de Marca (Conforme ADR-006 / Beatrix):**
  * O nome do projeto, repositório ou domínios não utilizam a marca "Windows".
  * Referências à plataforma são estritamente descritivas: *"ferramentas para Windows 11"*.
  * Todos os logotipos foram desenhados do zero, utilizando uma insígnia geométrica própria em formato de 'Z' estilizado.
  * **É terminantemente proibido o uso da grade de 4 quadrados ou qualquer elemento alusivo ao logo do Windows.**

---

### 3.2 Paletas de Cor

```
+-----------------------------------------------------------------------------------------+
|                                BIGZ OS PALETTES OVERVIEW                                |
+-----------------------+-----------------------+-----------------------+-----------------+
| COR-MÃE (CORE)        | DEV EDITION           | BALANCED EDITION      | FULL PERF       |
+-----------------------+-----------------------+-----------------------+-----------------+
| Cyber Violet #7C3AED  | Matrix Green #10B981  | Sapphire Blue #3B82F6 | Flame #F97316   |
| Electric Blue #2563EB | Dev Cyan #06B6D4      | Soft Violet #8B5CF6   | Crimson #EF4444 |
| Deep Space #0F172A    | Obsidian #0B0F19      | Slate Gray #1E293B    | Carbon #050505  |
+-----------------------+-----------------------+-----------------------+-----------------+
```

1. **Cor-Mãe (Identidade do Projeto, Site e Marca):**
   * *Violeta Cósmico:* `#7C3AED`
   * *Azul Elétrico:* `#2563EB`
   * *Ciano Radiante:* `#06B6D4`
   * *Fundo Deep Space:* `#0F172A`
   * *Texto:* `#F8FAFC` (Contraste superior a 12:1 - WCAG AAA).
2. **Edição DEV:**
   * *Matrix Green:* `#10B981`
   * *Dev Cyan:* `#06B6D4`
   * *Fundo Obsidian:* `#0B0F19`
3. **Edição Balanced:**
   * *Azul Safira:* `#3B82F6`
   * *Soft Violet:* `#8B5CF6`
   * *Menta:* `#14B8A6`
   * *Fundo Slate:* `#0F172A`
4. **Edição Full Performance:**
   * *Laranja Flame:* `#F97316`
   * *Vermelho Crimson:* `#EF4444`
   * *Preto Carbono:* `#050505`

---

### 3.3 Tipografia Livre (Licença SIL Open Font License 1.1)

1. **Interface, Botões e Conteúdo:** **Inter** (por Rasmus Andersson).
2. **Código, Terminal e Métricas:** **JetBrains Mono** (por JetBrains) ou **Fira Code**.
3. **Logotipo e Destaques:** **Plus Jakarta Sans** (por Tokotype).

Todas as fontes possuem licença livre permissiva e não utilizam tipografias proprietárias da Microsoft (como Segoe UI).

---

### 3.4 Arquivos Vetoriais SVG Gerados

Todos os arquivos estão disponíveis na pasta `design/logo/` e foram inspecionados para garantir 100% de originalidade geométrica:
* [logo-mother.svg](file:///C:/DEV/PROJETOS_MDEV/BigZ%20OS/design/logo/logo-mother.svg): Logotipo principal com o 'Z' estilizado em lâminas angulares e degradê violeta-azul-ciano.
* [logo-dev.svg](file:///C:/DEV/PROJETOS_MDEV/BigZ%20OS/design/logo/logo-dev.svg): Emblema DEV com prompt de terminal `>_` integrado e linhas de grid.
* [logo-balanced.svg](file:///C:/DEV/PROJETOS_MDEV/BigZ%20OS/design/logo/logo-balanced.svg): Emblema Balanced com traços suaves e equilíbrio simétrico.
* [logo-perf.svg](file:///C:/DEV/PROJETOS_MDEV/BigZ%20OS/design/logo/logo-perf.svg): Emblema Full Performance com vértices agressivos e acentos de velocidade em chama.
* [logo-horizontal.svg](file:///C:/DEV/PROJETOS_MDEV/BigZ%20OS/design/logo/logo-horizontal.svg): Aplicação horizontal para cabeçalhos e documentação.
* [favicon.svg](file:///C:/DEV/PROJETOS_MDEV/BigZ%20OS/design/logo/favicon.svg): Ícone compacto para a barra de títulos e web.

---

## 4. Wireframe e Mockup da Toolbox

* **Arquivo Visual SVG Standalone:** [toolbox-wireframe.svg](file:///C:/DEV/PROJETOS_MDEV/BigZ%20OS/design/toolbox-wireframe.svg)
* **Especificação Técnica de Presets:** [02-presets-shell-catalogo.md](file:///C:/DEV/PROJETOS_MDEV/BigZ%20OS/design/02-presets-shell-catalogo.md)
* **Catálogo JSON de Presets:** [presets-shell-toolbox.json](file:///C:/DEV/PROJETOS_MDEV/BigZ%20OS/design/presets-shell-toolbox.json)
* **Estrutura de Tela:**
  * Sidebar com navegação categórica (Início, Shell & UX, Apps, Dev Hub, Tweaks, Segurança);
  * Cards de seleção de perfil com predefinições recomendadas;
  * Controles de 1-clique para aplicar/reverter presets de shell;
  * Botão de **Rollback / Restaurar Padrão** visível em todas as telas;
  * Rodapé com aviso legal de marca e link para o GitHub do projeto.

---

## 5. Mockup da Landing Page (Site do Projeto)

Foi desenvolvido um mockup estático em HTML5/CSS3 moderno e responsivo, armazenado em:  
**[index.html (design/site/)](file:///C:/DEV/PROJETOS_MDEV/BigZ%20OS/design/site/index.html)**

O site apresenta:
* Identidade visual e paleta Cor-Mãe;
* Os pilares de transparência, legalidade e gratuidade;
* As 3 edições explicadas com seus focos;
* Destaque para o funcionamento da Toolbox com modo dry-run e reversão;
* O rodapé legal de marca obrigatório.

---

## 6. Aviso Legal de Marca Registrada

> **Aviso de Isenção de Responsabilidade:**  
> O BigZ OS é um projeto independente de código aberto desenvolvido pela comunidade. O BigZ OS não é afiliado, associado, autorizado, endossado ou de qualquer forma oficialmente conectado à Microsoft Corporation. Windows, Windows 11 e o logotipo do Windows são marcas registradas da Microsoft Corporation. Quaisquer outras marcas registradas mencionadas pertencem aos seus respectivos proprietários.
