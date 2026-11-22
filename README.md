# BigZ OS

> **Status: pré-lançamento (F0 — Fundação).** Nada aqui está pronto para uso. Repositório oficial (a ser criado): <https://github.com/BigZ-OS/BigZ-OS>. Links entre `[colchetes]` serão preenchidos no lançamento.

**O Windows personalizado em que dá para confiar — gratuito, aberto e auditável.**

[Português](#português) · [English](#english)

---

## Português

### O que é
O BigZ OS é um conjunto **open source** de ferramentas que personaliza **o Windows 11 oficial que você já tem**:

- uma **toolbox** (CLI + interface gráfica) para usar no Windows oficial já instalado; e
- um **builder** que transforma **a sua ISO oficial** em uma de três edições, localmente.

| Edição | Para quem | Foco |
|---|---|---|
| **DEV** | Desenvolvedores | Pronto para trabalhar: ferramentas de dev, WSL/Hyper-V sob demanda, Explorer e atalhos úteis |
| **Balanced** | Uso geral | Seguro, estável, personalizável |
| **Full Performance** | Jogos e desempenho | Reduz o que pesa; modo extremo só por opção explícita e reversível |

### O que nos diferencia
1. **Plano antes de aplicar (dry-run):** você vê tudo que vai mudar, com o risco de cada item, antes de qualquer alteração.
2. **Reversão real por ajuste**, sem reinstalar o Windows. Onde a reversão exata não é possível (ex.: remoção de app na imagem), dizemos isso claramente.
3. **Segurança por padrão:** Windows Update, Defender, UAC, SmartScreen, Store e Xbox ficam **ativos**. Nada de remover o Defender nem desligar o Update.
4. **Nenhum binário opaco:** as releases são construídas no **CI público**, com `SHA256SUMS` e atestação de origem (proveniência) que você pode conferir.
5. **Testes automáticos em VM** a cada build do Windows suportado, com a **matriz de compatibilidade** publicada.
6. **Cada ajuste explica o porquê** (o que faz, o risco, como reverter), em [`docs/`](docs/).

### ⚠️ Leia antes de usar
- **Não distribuímos o Windows.** Nenhuma ISO, imagem ou binário da Microsoft. Você usa **a sua** ISO oficial e **a sua** licença.
- **Sem ativadores, cracks ou bypass de licença.** Nunca, nem na documentação.
- **Não somos afiliados, patrocinados nem endossados pela Microsoft.** "Windows" e "Microsoft" são marcas de seus titulares.
- **Isto modifica o sistema.** Teste primeiro em **máquina virtual**, faça backup e use o *dry-run*. Sem garantia.
- **Seja honesto consigo:** o **Windows padrão continua sendo a opção mais simples e confiável** para a maioria das pessoas. O BigZ OS é para quem quer controle, e mesmo assim cada passo é visível e reversível. Veja [Segurança e transparência](docs/seguranca-e-transparencia.md).

### Como usar
> Em desenvolvimento. O primeiro marco (F1) é a **toolbox v0.1** no Windows oficial. O builder vem na F2. Instruções reais serão adicionadas quando houver versão testada. Roadmap: [`docs/03-plano-consolidado.md`](docs/03-plano-consolidado.md).

### Licença
- **Código:** [GPL-3.0-or-later](LICENSE). **Imagens, temas e documentação autorais:** [CC BY-SA 4.0](LICENSE-ASSETS). **Nome e logo:** ver [política de marca](TRADEMARK.md).
- **Uso comercial é permitido.** Se você distribuir uma versão modificada, deve **dar os devidos créditos** ao BigZ OS e **publicar o código-fonte das suas modificações sob a mesma licença**, devolvendo à comunidade.
- Código de terceiros e suas licenças: [`NOTICE`](NOTICE) e [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md).
- Isto não é aconselhamento jurídico.

### Participe
Leia o [`CONTRIBUTING.md`](comunidade/CONTRIBUTING.md) e o [`CODE_OF_CONDUCT.md`](comunidade/CODE_OF_CONDUCT.md). Dúvidas e ideias: [GitHub Discussions — a definir]. Vulnerabilidades: reporte em privado, [SECURITY.md — a definir].

### Apoie ☕
Gratuito e sempre será. Se ajudou, você pode [pagar um café — link a definir]. Apoiar **não** dá suporte prioritário nem recursos exclusivos.

### Inspirações
Atlas OS, Chris Titus Tech WinUtil, Win11Debloat, Sophia Script, tiny11builder, entre outros. Só incorporamos código com licença compatível, registrado em `THIRD-PARTY-NOTICES.md`.

---

## English

**BigZ OS — the customized Windows you can trust: free, open and auditable.**

### What it is
An **open-source** toolkit that customizes **the official Windows 11 you already have**: a **toolbox** (CLI + GUI) for an installed Windows, and a **builder** that turns **your own official ISO** into one of three editions (**DEV**, **Balanced**, **Full Performance**), locally.

### What sets it apart
1. **Plan before apply (dry-run)** with the risk of each item.
2. **Real per-tweak revert** — no reinstall. Where exact revert isn't possible, we say so.
3. **Secure by default:** Windows Update, Defender, UAC, SmartScreen, Store and Xbox stay on.
4. **No opaque binaries:** releases are built in public CI, with `SHA256SUMS` and build-provenance attestation.
5. **Automated VM tests** per supported Windows build, with a published compatibility matrix.
6. **Every tweak documents the "why"** (what, risk, how to revert).

### ⚠️ Read first
- **We do not distribute Windows** — no ISOs, images or Microsoft binaries. You use your own ISO and license.
- **No activators, cracks or license bypasses.** Ever.
- **Not affiliated with, sponsored by, or endorsed by Microsoft.** "Windows" and "Microsoft" are trademarks of their owners.
- **It modifies your system.** Use a VM first, back up, use dry-run. No warranty.
- **Stock Windows remains the simplest and most trustworthy option for most people.** See [Security and transparency](docs/seguranca-e-transparencia.md).

### License (proposed, pending final approval)
Code: GPL-3.0-or-later. Original art/themes/docs: CC BY-SA 4.0. Name and logo: see [trademark policy](TRADEMARK.md). **Commercial use is allowed**: credit BigZ OS and, if you distribute a modified version, release your changes' source under the same license. Not legal advice.

### Contribute / Support
See [`CONTRIBUTING.md`](comunidade/CONTRIBUTING.md) and [`CODE_OF_CONDUCT.md`](comunidade/CODE_OF_CONDUCT.md). Free forever; optional coffee link [TBD] — donations buy no priority support.
