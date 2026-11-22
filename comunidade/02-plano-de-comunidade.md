# BigZ OS — Plano de Comunidade (rascunho)

> Autora: Tellah. 2026-11-21. **Nada foi criado nem publicado.** Toda criação de conta/canal exige aprovação do usuário via Auron (Carta, regra 6).
> Não verificado: números de membros/regras atuais de subreddits e servidores — isso é com a Lulu (Pesquisa).

## 1. Princípio
Poucos canais, bem cuidados. Fonte da verdade = **GitHub**. Chat = conversa efêmera.

## 2. Canais

| Canal | Função | Prós | Contras | Quando |
|---|---|---|---|---|
| **GitHub Issues** | Bugs e pedidos estruturados | Já no repositório, rastreável | Não serve para conversa livre | Dia 1 |
| **GitHub Discussions** | Perguntas, ideias, anúncios, showcase; **FAQ pesquisável** | Gratuito, indexável no Google, junto do código, sem outra conta | Menos "vivo" que chat | Dia 1 |
| **Discord** | Suporte rápido e vida social | Onde gamers/modders já estão; tempo real | Conhecimento se perde (não indexa), exige moderação constante, risco de pirataria/ativadores | Quando houver comunidade ativa (~dezenas de usuários) |
| **Reddit** (subreddit próprio) | Descoberta, anúncios | Alcance orgânico | Moderação, regras de autopromoção dos outros subs | Depois do 1º release estável; **não postar** em subs de terceiros sem ler as regras (Lulu) |
| Site/Docs (Yuna/Cloud) | Documentação oficial, download dos scripts | Controle total | Manutenção | Com o 1º release |

**Recomendação:** começar com **GitHub Issues + Discussions**. Abrir **Discord** quando a demanda de suporte justificar, com 2+ moderadores. Reddit por último.

## 3. Regras de comunidade (todas as plataformas)
- Código de Conduta vale em todos os canais.
- **Proibido** pedir/compartilhar ativadores, cracks, ISOs pirateadas.
- Pedidos de suporte devem informar: edição, build do Windows, se é VM ou hardware real, logs.
- Aviso fixo: "modifica o sistema — teste em VM e faça backup".
- Moderação: mínimo 2 moderadores; ações registradas; contato `[a definir]`.

## 4. Modelos a criar (rascunhar após aprovação)
- `.github/ISSUE_TEMPLATE/` (bug, tweak request, pergunta), `PULL_REQUEST_TEMPLATE.md`
- `SECURITY.md`, `FUNDING.yml`, `THIRD-PARTY-NOTICES.md`, `TRADEMARK.md`, `CONTRIBUTORS.md`
- FAQ: "É legal?", "Preciso de licença do Windows?", "Posso usar comercialmente?", "Como reverto?"
- Guia de primeiros passos "good first issue" para novos contribuidores

## 5. Financiamento: Buy Me a Coffee vs Ko-fi vs GitHub Sponsors
Tabela completa com fontes e taxas em [`01-licenca-e-comunidade.md`, §7](01-licenca-e-comunidade.md).

Resumo: BMC **5%** + Stripe (2,9% + US$ 0,30) ([help BMC](https://help.buymeacoffee.com/en/articles/8105744)); Ko-fi **0%** em doações únicas no plano grátis (*não verificado diretamente*); GitHub Sponsors **0%** para contas pessoais ([docs](https://docs.github.com/en/sponsors/getting-started-with-github-sponsors/about-github-sponsors)).

Decisão da Carta: **somente Buy Me a Coffee**. Passos (todos dependem do criador):
1. Conferir se BMC funciona para residentes no Brasil (cadastro, saque, impostos).
2. Criar a página; texto: "gratuito, sempre; café não dá privilégios".
3. Só então: botão no README, `FUNDING.yml`, site.
4. Transparência: relatório simples periódico de uso do dinheiro (opcional).
Impostos sobre doações recebidas: tema para contador — **fora do meu escopo**.

## 6. Lançamento em fases
1. **Pré-lançamento (agora):** docs, licença, README (rascunhos prontos). Repo ainda privado.
2. **Alfa fechado:** convidados testam em VM; feedback via Issues.
3. **Beta público:** repo público, Discussions ligado, 1º post de anúncio.
4. **1.0:** release com checksums, site, Discord/Reddit se houver demanda.

## 7. Métricas simples
Issues abertas/fechadas, tempo de 1ª resposta, contribuidores únicos, estrelas/forks, downloads de releases. Sem coleta de telemetria dos usuários sem consentimento explícito.

## 8. Riscos
- **Pirataria/ativadores** na comunidade → regra clara + moderação (risco de DMCA/remoção do repositório).
- **Afiliação falsa à Microsoft** → aviso em README/site.
- **Fork malicioso com o nome BigZ OS** (malware) → política de marca + checksums oficiais + aviso "baixe só do repositório oficial".
- **Burnout do criador** → `GOVERNANCE.md` simples, co-mantenedores.
