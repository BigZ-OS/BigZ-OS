# ADR-003 — Toolbox v0 em Windows PowerShell 5.1 + WPF, com CLI e GUI no mesmo motor

- **Status:** Aceita · **Data:** 2026-11-21 · **Dono:** Cid · **Revisores:** Rikku, Yuna, Beatrix

## Contexto
A toolbox roda depois da instalação, no Windows oficial ou numa instalação BigZ. Ela precisa funcionar sem instalar runtimes extras, ser auditável em texto e oferecer CLI (automação/testes) e GUI (usuário final). Foram avaliados: PowerShell 5.1 + WPF, C#/.NET + WinUI 3 e Tauri 2.

## Decisão
- **Windows PowerShell 5.1 x64 + WPF/XAML** na v0. É o mesmo stack de referência do WinUtil e não exige runtime adicional.
- **Um único motor** (módulo) usado pela CLI e pela GUI: inspecionar → plano (dry-run) → aplicar → verificar → reverter.
- A **GUI roda sem elevação**. Ações de máquina passam por um processo curto elevado via **UAC**, que recarrega o catálogo da sua própria cópia confiável e executa só operações tipadas.
- O módulo é instalado numa pasta gravável apenas por administradores e assinado (Authenticode quando disponível; ver ADR-005 e a política de releases).
- Apps são instalados via **WinGet** com ID exato e origem declarada.
- **WinUI 3** será reavaliado depois da F1.

## Consequências
- ✅ Zero dependências extras; código legível, o que reduz falso positivo de antivírus.
- ✅ A CLI permite os testes automáticos em VM (ver `tests/vm/`).
- ⚠️ WPF exige thread STA e tarefas longas em segundo plano; PowerShell 5.1 pede disciplina de testes (Pester).
- ⚠️ Proibidos no motor: `Invoke-Expression` de strings montadas, `-EncodedCommand`, download e execução de código externo.

## Fontes
- Arquitetura v0 (Cid): [01-arquitetura-v0.md](../01-arquitetura-v0.md), seção 2 (Toolbox)
- WPF: <https://learn.microsoft.com/en-us/dotnet/desktop/wpf/overview/>
- Windows App SDK (custos de distribuição): <https://learn.microsoft.com/en-us/windows/apps/windows-app-sdk/deploy-unpackaged-apps>
- WinGet: <https://learn.microsoft.com/en-us/windows/package-manager/winget/>
- Referência de desenho (MIT): WinUtil <https://github.com/ChrisTitusTech/winutil>
