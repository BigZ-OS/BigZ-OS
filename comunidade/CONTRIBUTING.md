# Contribuindo com o BigZ OS

> **Rascunho** — não publicado. / *Draft — unpublished. English summary at the end.*

Obrigada por querer ajudar! Todo tipo de contribuição vale: código, testes em VM, documentação, tradução, design, ideias.

Ao participar você concorda com o [Código de Conduta](CODE_OF_CONDUCT.md).

## Regras que não mudam
1. **Nada de ISO/imagens do Windows nem binários da Microsoft** no repositório ou em PRs.
2. **Nada de ativadores, cracks, bypass de licença** ou qualquer coisa que viole os termos da Microsoft.
3. **Sem binários opacos.** Tudo que roda precisa ter código-fonte legível.
4. **Cada tweak precisa de:** descrição, motivo, impacto (segurança/desempenho/compatibilidade), **como reverter** e em quais versões do Windows foi testado.
5. **Segurança primeiro:** nada que desative proteções sem aviso claro e opção de escolha do usuário.

## Licença das contribuições
- Código → **GPL-3.0-or-later**; assets/docs → **CC BY-SA 4.0**.
- Você só pode enviar o que **você escreveu** ou o que tem licença **compatível** (MIT, BSD, Apache-2.0, GPL-3.0…).
- **Código copiado de outro projeto** exige: indicar origem, licença e copyright no PR e em `THIRD-PARTY-NOTICES.md`. **Código sem licença não pode ser copiado.**
- Use **DCO**: assine seus commits com `git commit -s` (acrescenta `Signed-off-by:`), declarando que tem o direito de contribuir ([developercertificate.org](https://developercertificate.org/)).

## Como contribuir
1. **Abra uma Issue** ou Discussion antes de mudanças grandes.
2. Faça *fork* → branch (`tipo/descricao-curta`, ex.: `fix/taskbar-registry`).
3. **Teste em VM** (Hyper-V/VirtualBox/VMware) com a ISO oficial. Descreva no PR o que testou (edição, build do Windows).
4. Commits claros, em português ou inglês (código e commits podem ser em inglês). Sugestão: *Conventional Commits* (`feat:`, `fix:`, `docs:`).
5. Abra o PR preenchendo o modelo (o que muda, por quê, como reverter, testes).
6. Seja paciente: revisão é voluntária.

## Estilo (PowerShell)
- Compatível com **Windows PowerShell 5.1** e PowerShell 7 quando possível.
- Funções com nomes `Verbo-Substantivo`, comentários de ajuda, `Set-StrictMode`, tratamento de erro.
- Nada de `Invoke-Expression` em conteúdo baixado sem verificação; nada de ofuscação.
- Linting com PSScriptAnalyzer *(a ser configurado pela infra)*.

## Documentação, tradução, design
- Docs em Markdown; pt-BR é o idioma-base, inglês bem-vindo.
- Assets autorais entram como CC BY-SA 4.0; não envie ícones/fontes de terceiros sem licença clara.

## Segurança
**Não abra Issue pública para vulnerabilidades.** Contate em privado: `[SECURITY.md / contato a definir]`.

## Reconhecimento
Contribuidores são listados em `CONTRIBUTORS.md` / nas notas de versão.

---

### English summary
No Windows ISOs/Microsoft binaries, no activators/cracks, no opaque binaries. Every tweak needs docs and a revert path; test in a VM. Contributions are licensed GPL-3.0-or-later (code) / CC BY-SA 4.0 (assets, docs); only submit your own work or compatible-licensed code with attribution; sign off commits (DCO, `git commit -s`). Report vulnerabilities privately. Be kind: see the Code of Conduct.
