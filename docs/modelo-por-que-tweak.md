# Modelo de documentação "por que" — um por tweak

> Alinhado ao contrato JSON de tweaks do ADR-004 (`docs/01-arquitetura-v0.md` §3, `schemaVersion: 1`). **Cid/Rikku:** se o contrato mudar, atualizem a tabela de campos. Cada tweak do catálogo precisa de **uma página** com este formato, em `docs/tweaks/<id>.md`, onde `<id>` = campo `id` do JSON (ex.: `explorer.show-file-extensions`).
> Regra: a página é **requisito de merge** do tweak (CI deve falhar se o `id` não tiver doc — proposta ao Cloud). Sem afirmação sem fonte; sem promessa de desempenho sem benchmark.

## Campos do JSON que a doc deve refletir
Ao preencher a página, **copie** estes valores do `catalog/tweaks.json` (não invente nem divirja):
`id` · `description` · `risk` (`low|medium|high`) · `editions` · `phase` (`offline|online`) · `scope` (`currentUser|machine…`) · `requires` (`builds`, `architectures`, `admin`) · `dependsOn` · `conflictsWith` · `action` · `verify` · `rollback` · `restart`.
Nível de política: `low` → 🟢, `medium` → 🟡, `high`/bloqueado → 🔴 (ADR-005).

---

## Modelo (copiar daqui para baixo)

```markdown
---
id: <id do tweak, igual ao JSON>
schemaVersion: 1
risk: low | medium | high        # igual ao JSON
politica: 🟢 | 🟡                 # 🔴 não existe no catálogo
editions: [dev, balanced, full-performance]
phase: online | offline
scope: currentUser | machine
requiresAdmin: true | false
restart: none | logoff | reboot
revisado-por: [@nome1, @nome2]    # 2 revisores
testado-em: [Windows 11 25H2 build XXXXX, VM Hyper-V]
ultima-verificacao: AAAA-MM-DD
---

# <Título em linguagem simples>

## O que faz
Uma ou duas frases, sem jargão. O que muda, onde (chave de registro, serviço, app, configuração).

## Por que existe
O problema real que isso resolve para quem. Seja específico (ex.: "mostra a extensão para você distinguir `foto.jpg` de `foto.jpg.exe`").

## Quem se beneficia / quem não deve aplicar
- Beneficia: …
- Evite se: …

## O que pode dar errado (risco)
- Efeitos colaterais conhecidos, programas afetados, interação com atualizações do Windows.
- Impacto em segurança: **nenhum | descrito** (se diminuir proteção, explique; itens que reduzem proteção da base **não entram**).
- Impacto em desempenho/privacidade: **só se medido**; cite a medição. Sem medição, escreva "não medido".

## Como o BigZ aplica (do JSON)
| Campo | Valor |
|---|---|
| Ação | `registry.setValue` — `HKCU\...\Advanced\HideFileExt = 0 (DWord)` |
| Dependências | — |
| Conflitos | — |
| Pré-requisitos | build(s), arquitetura, admin |
| Reinício | nenhum |

## Como verificar
O que o BigZ checa (`verify`) e como **você** confere manualmente (comando ou caminho de tela).

## Como reverter
- Via BigZ: `rollback` (ex.: restaurar o snapshot salvo antes de aplicar).
- **Limites:** o que a reversão **não** consegue desfazer (ex.: dados de app removido; remoção Appx *offline* só reconstruindo a mídia). Se não houver limite, escreva "nenhum conhecido".
- Manualmente (sem o BigZ): passos exatos.

## Fontes
Links oficiais (Microsoft Learn, documentação do projeto de origem). Tudo que não foi confirmado: **"não verificado"**.

## Origem e licença
Original do BigZ | Inspirado em <projeto> (<licença>) | Código copiado de <projeto> (<licença>, <commit>) → registrado em `THIRD-PARTY-NOTICES.md`.

## Histórico
| Data | Mudança | Autor |
|---|---|---|
```

---

## Exemplo preenchido (ilustrativo — baseado no exemplo do contrato; não verificado na matriz de testes)

```markdown
---
id: explorer.show-file-extensions
schemaVersion: 1
risk: low
politica: 🟢
editions: [dev, balanced]
phase: online
scope: currentUser
requiresAdmin: false
restart: none
revisado-por: [PENDENTE, PENDENTE]
testado-em: [PENDENTE]
ultima-verificacao: PENDENTE
---

# Mostrar extensões de arquivo no Explorer

## O que faz
Faz o Explorer exibir a extensão dos arquivos conhecidos (`.txt`, `.exe`, `.jpg`…), alterando a preferência `HideFileExt` do usuário atual.

## Por que existe
Por padrão o Explorer esconde extensões conhecidas. Ver a extensão ajuda a notar arquivos disfarçados (como `fatura.pdf.exe`) e a trabalhar com arquivos de código/config.

## Quem se beneficia / quem não deve aplicar
- Beneficia: desenvolvedores e quem baixa arquivos com frequência.
- Evite se: você prefere nomes curtos e já sabe a extensão pelo ícone.

## O que pode dar errado (risco)
- Ao renomear um arquivo, é possível apagar sem querer a extensão. O Windows pergunta antes de alterar a extensão.
- Segurança: nenhum impacto negativo; melhora a visibilidade.
- Desempenho: não medido / irrelevante.

## Como o BigZ aplica (do JSON)
| Campo | Valor |
|---|---|
| Ação | `registry.setValue` `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` `HideFileExt` = 0 (DWord) |
| Pré-requisitos | build 26200, x64, sem admin |
| Reinício | nenhum |

## Como verificar
O BigZ confere se o valor é 0. Manual: Explorer → Exibir → Mostrar → "Extensões de nomes de arquivos".

## Como reverter
Via BigZ: restaurar o snapshot do valor anterior. Manual: desmarcar a opção acima. Limites: nenhum conhecido.

## Fontes
Referência da preferência do Explorer citada em `docs/01-arquitetura-v0.md` §3. Demais: não verificado.

## Origem e licença
Original do BigZ (conceito comum; sem código copiado).
```
