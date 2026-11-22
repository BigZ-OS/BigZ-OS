# BigZ OS — Licença e Comunidade (Tarefa 1)

> Autora: Tellah (Documentação & Comunidade). Data: 2026-11-21. Status: **rascunho para decisão do Auron/criador**.
> **Aviso:** isto é análise técnica, **não é parecer jurídico**. Antes de publicar, recomenda-se revisão de um advogado (especialmente a cláusula de atribuição e marca).
> Nada foi publicado, nenhuma conta foi criada.

## 1. Resumo da recomendação

| Parte | Recomendação |
|---|---|
| **Código** (builder, toolbox, scripts) | **GPL-3.0-or-later** (com *aviso de atribuição* via GPLv3 §7 e arquivo `NOTICE`) |
| **Assets** (logo, wallpapers, ícones, temas, docs) | **CC BY-SA 4.0** |
| **Marca "BigZ OS" e logo** | Política de marca separada (`TRADEMARK.md`): forks podem existir, mas não usar o nome/logo como se fossem oficiais |
| **Código de conduta** | Contributor Covenant 2.1 (CC BY 4.0) |

Por quê, em uma frase: o criador quer *grátis + crédito + devolução de melhorias*. Nenhuma licença livre consegue **proibir ou cobrar** uso comercial (isso a tornaria "não livre" e incompatível com o código de terceiros que queremos reaproveitar). O que o **copyleft forte** (GPL) faz é: o uso comercial é permitido, mas **quem distribui uma versão modificada precisa manter o crédito e abrir o código-fonte das melhorias sob a mesma licença** — que é exatamente a "contribuição de volta".

## 2. O desejo do criador vs. o que as licenças permitem

| Desejo | Como atender | Limite |
|---|---|---|
| Grátis para todos | Qualquer licença livre | — |
| Reconhecimento / atribuição | Preservação de avisos de copyright (todas) + `NOTICE` + termos adicionais de atribuição razoável (GPLv3 §7) | Não dá para exigir "pagar" ou "pedir permissão" |
| Uso comercial → devolver à comunidade | Copyleft: quem distribui versão modificada deve liberar o código-fonte sob a mesma licença | Quem usa **internamente** ou **só executa** sem distribuir não é obrigado a devolver (GPL). Para serviços em rede, só a AGPL/EUPL fecham essa lacuna |
| Impedir revenda fechada | Copyleft impede *fechar* o código; **não impede** vender cópias (GPL permite cobrar pela distribuição) | Inevitável em qualquer licença livre |

Se o criador quiser **exigir pagamento ou proibir uso comercial** (ex.: CC BY-NC, PolyForm Noncommercial), isso é *source-available*, não open source: ficaria **incompatível** com copiar código GPL/MIT de terceiros e afastaria contribuidores. **Não recomendado** — decisão do criador, mas deve ser tomada ciente disso.

## 3. Comparação das licenças

Rótulos (permissões/condições/limitações) conforme choosealicense.com, lidos em 2026-11-21.

| Licença | Uso comercial | Atribuição | Devolução de melhorias | Pontos de atenção | Fonte |
|---|---|---|---|---|---|
| **GPL-3.0** | Permitido | Aviso de licença e copyright obrigatórios; indicar alterações | **Sim**: ao distribuir, abrir fonte sob a mesma licença (copyleft forte) | Não cobre uso via rede sem distribuição. Compatível com MIT (entrada). Cláusula de patente | [choosealicense](https://choosealicense.com/licenses/gpl-3.0/) · [gnu.org](https://www.gnu.org/licenses/gpl-3.0.html) |
| **AGPL-3.0** | Permitido | Idem GPL | **Sim**, e também quando oferecido **por rede** ("network use is distribution") | Mais forte; assusta empresas; só vale a pena se o projeto tiver backend/serviço web próprio | [choosealicense](https://choosealicense.com/licenses/agpl-3.0/) |
| **MPL-2.0** | Permitido | Aviso obrigatório | **Parcial**: copyleft **por arquivo**; pode ser combinado em produto fechado | Fraca demais para o desejo "devolver melhorias do produto todo" | [choosealicense](https://choosealicense.com/licenses/mpl-2.0/) |
| **EUPL-1.2** | Permitido | Aviso obrigatório | **Sim** (copyleft + rede), com lista de licenças compatíveis | Menos comum fora da UE; texto longo, ligação com direito europeu; menos familiar à comunidade Windows | [choosealicense](https://choosealicense.com/licenses/eupl-1.2/) · [opensource.org](https://opensource.org/license/eupl-1-2) |
| **MIT** (referência) | Permitido | Preservar aviso | **Não** (qualquer um pode fechar) | Não atende "contribuir de volta" | [choosealicense](https://choosealicense.com/licenses/mit/) |
| **CC BY-SA 4.0** (assets) | Permitido | **Atribuição obrigatória** | Compartilhamento pela mesma licença (obras derivadas) | **CC não recomenda para software** | [creativecommons.org](https://creativecommons.org/licenses/by-sa/4.0/) · [FAQ](https://creativecommons.org/faq/) |

### Por que GPL-3.0-or-later e não as outras
- **AGPL:** o BigZ OS é um conjunto de scripts aplicados localmente + site estático. A lacuna "uso por rede" quase não existe. AGPL só traria atrito. Reavaliar se um dia houver serviço web (ex.: loja de tweaks online, API).
- **MPL:** deixa empresas fecharem o produto final; fraca para o objetivo.
- **EUPL:** funcionalmente parecida com GPL, mas menos conhecida e sem vantagem aqui. (Compatibilidade com GPL existe, mas não precisamos de complexidade extra.)
- **GPL-3.0:** a mais conhecida, **mesma licença do Atlas** (ver §4), compatível com MIT, e há ecossistema inteiro de ferramentas/avisos.
- *"or-later"* permite migrar para GPL-4/AGPL no futuro sem pedir permissão a cada contribuidor — decisão do criador (alternativa: "only").

### Como cobrir "atribuição" de forma explícita
GPLv3 §7 permite **termos adicionais** como "preservação de avisos legais razoáveis ou atribuições de autor". Sugestão de texto para `NOTICE`/`LICENSE-NOTES`:
> "Obras derivadas e redistribuições devem manter, de forma visível (README e tela Sobre), a frase: *Baseado no BigZ OS — <URL do repositório>*."

⚠ Termos adicionais **não podem** restringir uso comercial nem exigir pagamento; apenas atribuição. Um advogado deve validar a redação.

## 4. Compatibilidade com código de terceiros (verificado nos clones locais em `builder/_refs`)

| Projeto | Licença encontrada | Evidência | Pode reaproveitar código em GPL-3.0? |
|---|---|---|---|
| **WinUtil** (ChrisTitusTech) | **MIT** (© 2022 CT Tech Group LLC) | `builder/_refs/winutil/LICENSE` | **Sim.** MIT → GPL é compatível ([gnu.org](https://www.gnu.org/licenses/license-list.html)). Manter o aviso MIT e o copyright original |
| **Win11Debloat** (Raphire) | **MIT** (© 2020 Raphire) | `builder/_refs/Win11Debloat/LICENSE` | **Sim**, mesma regra |
| **Sophia Script** (farag2) | **MIT** (© 2023 farag2) | `builder/_refs/Sophia-Script-for-Windows/LICENSE` | **Sim**, mesma regra. Obs.: tem política de assinatura de código própria (`CODE_SIGNING_POLICY.md`) — não afeta licença |
| **trusted-uninstaller-cli** (Ameliorated) | **MIT** (© Ameliorated LLC) | `builder/_refs/trusted-uninstaller-cli/LICENSE.md` | **Sim** |
| **Atlas** | **GPL-3.0** (pacote Atlas e Atlas Manager). **AME Wizard não é open source** | [README do Atlas](https://github.com/Atlas-OS/Atlas) e [LICENSE](https://github.com/Atlas-OS/Atlas/blob/main/LICENSE) (lido via web). O clone local está vazio ("No commits yet") | **Sim**, GPL-3.0 → GPL-3.0. Quem copiar do Atlas **precisa** manter GPL (outro motivo para escolher GPL). **Não** depender do AME Wizard (fechado) |
| **tiny11builder** (ntdevlabs) | **Sem arquivo de licença no checkout** | `tiny11builder/NOTICE.md`: "This upstream checkout contains no standalone license file… a public GitHub repository alone does not grant redistribution rights" | **NÃO copiar código.** Sem licença = todos os direitos reservados. Reimplementar a *ideia* do zero (DISM/unattend são conhecimento público) ou pedir permissão por escrito ao autor. *Não verifiquei o repositório online; apenas o checkout local* |

Regras práticas para o time:
1. Todo trecho copiado vai para `THIRD-PARTY-NOTICES.md` com origem, licença, copyright e commit.
2. Código sem licença = não copiar. Código MIT/GPL = copiar com aviso.
3. Verificar a licença de cada dependência (winget, módulos PowerShell, ferramentas de terceiros que o builder baixe) antes de incluir; **não redistribuir binários da Microsoft** (Carta, regra 1).
4. Se um dia houver código com licença **incompatível com GPLv3** (ex.: GPLv2-only, licenças com restrição de uso), não misturar.

## 5. Assets: CC BY-SA 4.0

- Serve para logo, wallpapers, ícones próprios, temas visuais, textos de documentação.
- CC BY-SA 4.0 é **compatível em uma direção com GPLv3** (conteúdo CC BY-SA 4.0 pode ser incorporado em obra GPLv3, mas não o contrário) — [gnu.org license-list](https://www.gnu.org/licenses/license-list.html).
- A **CC recomenda não usar** licenças CC para software ([CC FAQ](https://creativecommons.org/faq/)) — por isso código = GPL, assets = CC.
- **Cuidado (Yuna/design):** ícones, fontes e wallpapers de terceiros têm licenças próprias; só publicar como CC BY-SA os que forem **autorais**. Ícones/branding da Microsoft **não** podem entrar.
- **Marca** não é coberta por CC BY-SA nem pela GPL: criar `TRADEMARK.md` curto (nome e logo oficiais só para o projeto; forks devem renomear). Avaliar registro de marca depois (INPI) — fora do escopo.

## 6. Conformidade com a Carta
- Não distribuímos Windows/ISO nem binários Microsoft; **README deixa isso explícito** e não afirma afiliação à Microsoft. "Windows" é marca registrada da Microsoft; usar apenas de forma descritiva ("para Windows").
- Releases com checksums e código aberto, coerente com GPL (fonte sempre disponível).

## 7. Plataformas de apoio (taxas)

Taxas mudam; **conferir no dia da criação da conta**. Todas as fontes lidas em 2026-11-21.

| | Buy Me a Coffee | Ko-fi | GitHub Sponsors |
|---|---|---|---|
| Taxa da plataforma | **5%** por transação, sem mensalidade ([help BMC](https://help.buymeacoffee.com/en/articles/8105744), atualizado em 18/03/2026) | **0%** em doações únicas; 5% em assinaturas mensais, memberships, loja (plano grátis) — plano Gold (US$ 12/mês) zera ([help Ko-fi](https://help.ko-fi.com/hc/en-us/articles/360005506873-What-is-Ko-fi-Gold)). *Página de taxas oficial retornou 403 na leitura; valor via resumo de busca — **não verificado diretamente*** | **0%** para patrocínios de contas pessoais; organizações pagam até 6% ([docs GitHub](https://docs.github.com/en/sponsors/getting-started-with-github-sponsors/about-github-sponsors)) |
| Processamento | Stripe 2,9% + US$ 0,30; +0,5% saque; +1% internacional; +0,5% assinaturas | Taxas do processador (PayPal/Stripe) | Incluído nos casos acima |
| Disponibilidade no Brasil | **Não verificado** (checar países suportados antes) | **Não verificado** | **Não verificado** (GitHub Sponsors depende de região e de aprovação) |
| Encaixe com o desejo do criador | **É o escolhido na Carta** ("apenas Buy Me a Coffee") — marca conhecida, página simples | Alternativa com taxa menor em doação avulsa | Integra com o repositório (botão Sponsor), mas é menos "café" |

**Recomendação:** manter **Buy Me a Coffee** como único canal (decisão do criador), e **só** conferir disponibilidade/saque no Brasil antes de criar a conta. Cogitar Ko-fi como plano B se BMC não atender ao Brasil ou se a taxa incomodar. O botão `FUNDING.yml` do GitHub aceita `buy_me_a_coffee: <usuario>`, então o repositório mostra o botão sem usar o GitHub Sponsors. (Funcionalidade do `FUNDING.yml` conhecida por mim; **não reverifiquei** nesta sessão.)

Transparência: publicar no README que doação **não compra** suporte prioritário nem recursos; o projeto continua gratuito.

## 8. Pendências / decisões para o Auron e o criador
1. Aprovar **GPL-3.0-or-later** (código) + **CC BY-SA 4.0** (assets)? Aceita que o uso comercial **não pode ser proibido**, só condicionado a atribuição + abertura do código?
2. "or-later" ou "only"?
3. Criador quer a cláusula extra de atribuição (§7)? Se sim, pagar revisão jurídica.
4. Conferir Buy Me a Coffee no Brasil (conta/saque) — requer ação do criador.
5. Escolher e reservar o nome do repositório/organização (não criado).
6. Definir e-mail/canal de contato para o Código de Conduta (placeholder `[CONTATO]`).
7. tiny11builder: pedir permissão ao autor ou reimplementar do zero (Cid).
8. Outras ferramentas referenciadas por outros setores precisam passar pelo checklist do §4 (avisar Rikku/Cid).

## 9. Rascunhos nesta pasta
- `README.md` — pt-BR + seção em inglês
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md` — Contributor Covenant 2.1 (tradução pt-BR de trabalho; conferir com o texto oficial antes de publicar)
- `02-plano-de-comunidade.md` — canais (Discord/Discussions/Reddit), moderação, lançamento em fases, financiamento

Fontes principais: [choosealicense.com](https://choosealicense.com/) · [opensource.org licenses](https://opensource.org/licenses) · [gnu.org license list](https://www.gnu.org/licenses/license-list.html) · [Creative Commons FAQ](https://creativecommons.org/faq/) · [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

---
## Atualização (rodada 2, 2026-11-21)
Licenciamento **aprovado pelo usuário** (via Auron): GPL-3.0-or-later (código) + CC BY-SA 4.0 (assets) + `TRADEMARK.md`. Arquivos `LICENSE`, `LICENSE-ASSETS` e `TRADEMARK.md` estão na raiz do projeto. Repositório previsto: https://github.com/BigZ-OS/BigZ-OS (ainda não criado). Revisão jurídica da cláusula de atribuição (§7) e da marca continua recomendada antes do lançamento.
