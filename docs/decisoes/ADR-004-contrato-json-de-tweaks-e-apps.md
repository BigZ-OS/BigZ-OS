# ADR-004 — Contrato JSON único para tweaks e apps

- **Status:** Aceita · **Data:** 2026-11-21 · **Donos:** Cid + Rikku · **Revisora:** Beatrix

## Contexto
Builder, toolbox (CLI/GUI), catálogo de apps e testes precisam falar a mesma língua. As referências mostram falhas típicas: a reversão usa um "valor padrão" do catálogo em vez do estado real do usuário (WinUtil), e modos silenciosos pulam proteções (Win11Debloat). Um contrato único e validado evita essas classes de erro.

## Decisão
Cada item do catálogo (tweak ou app) é um objeto JSON com **`schemaVersion`** e **ID estável**, e declara no mínimo:

| Campo | Obrigatório | Função |
|---|---|---|
| `id`, `description` | sim | Identidade e texto para o usuário |
| `phase` | sim | `offline` (imagem) · `online` (sistema em uso) · `firstUse` |
| `scope` | sim | `image` (fase `offline`) · `machine` · `currentUser` · `defaultUser` |
| `editions` | sim | Chaves canônicas: `dev` · `balanced` · `full-performance` |
| `risk` | sim | Impacto funcional, como no exemplo do Cid: `low` · `medium` (`high` é rejeitado na v0) |
| `securityImpact` | sim | `none` · `reducesProtection`. Junto com `risk`, define a classe 🟢/🟡/🔴 da ADR-005 |
| `requires`, `dependsOn`, `conflictsWith` | sim (podem ser vazios) | Builds, arquitetura, admin, dependências |
| `action` | sim | Só **tipos conhecidos** (ex.: `registry.setValue`, `appx.deprovision`, `winget.install`) |
| `verify` | sim | Como provar que foi aplicado |
| `rollback` | sim | Normalmente `restoreSnapshot` (estado real capturado antes) |
| `restart` | sim | `none` · `logoff` · `reboot` |
| `source` | sim | Link da documentação (Microsoft Learn de preferência) |

Regras do validador:
- `securityImpact` e `source` são obrigatórios. Itens `securityImpact: reducesProtection` ou `risk: high` são **bloqueados já no plano** (dry-run), não só na execução (ADR-005, fase v0).
- Para o planejador offline, o tipo é `appx.deprovision` com `scope: image`. Nesta rodada só existe o planejamento; o executor de remoção virá depois, com revisão.
- **Rejeita** campos desconhecidos, comandos livres, URLs executáveis e importação de código externo.
- Rejeita qualquer alvo da **lista de componentes protegidos** (ADR-005), em qualquer modo, inclusive no silencioso.
- O snapshot do estado anterior é salvo **antes** da primeira mutação. No undo, detecta se o valor mudou por fora e registra o conflito.
- Perfis (ADR-002) referenciam itens por `id`; perfil e catálogo são validados entre si.

## Consequências
- ✅ Um só lugar para auditar o que muda; os PRs revisam dados, não código.
- ✅ A GUI mostra risco, fonte e reversão sem lógica extra.
- ⚠️ Toda ação nova exige um tipo novo no executor, com revisão (2 aprovações, ver SECURITY.md).
- O esquema formal fica em `shared/schemas/` (Cid). Exemplo em [01-arquitetura-v0.md](../01-arquitetura-v0.md), seção 3.

## Fontes
- Arquitetura v0, seção 3 (contrato e execução): [01-arquitetura-v0.md](../01-arquitetura-v0.md)
- Catálogo v0 (Rikku): [../../toolbox/01-catalogo-v0.md](../../toolbox/01-catalogo-v0.md)
- Reversão por `OriginalValue`/`UndoScript` no WinUtil: <https://github.com/ChrisTitusTech/winutil/blob/70c23c80641d7370532af2f619b2842658600842/functions/private/Invoke-WinUtilTweaks.ps1>
- Proteção da Store/Terminal no Win11Debloat: <https://github.com/Raphire/Win11Debloat/blob/3d8feefbbc672d55af4b84c8681a1996538e04e2/Scripts/Helpers/Confirm-UnsafeAppRemoval.ps1>
