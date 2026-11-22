# Segurança e transparência

> Esta página é escrita para ser honesta, não para vender. Onde algo não está pronto, está dito. Estado: **pré-lançamento** — várias garantias abaixo são **metas de projeto** (marcadas), ainda não entregues.

## 1. A resposta curta
**O Windows padrão, da Microsoft, sem modificações, continua sendo a opção mais simples e confiável para a maioria das pessoas.** Ele recebe correções, é o que o suporte conhece e é o caminho com menos surpresas. O BigZ OS existe para quem **quer controle** (menos apps pré-instalados, ajustes de interface, perfil de dev ou de jogos) e aceita assumir a responsabilidade por modificar o sistema. Se você não tem motivo concreto para modificar o Windows, **não precisa**.

Qualquer modificação aumenta a chance de problema: um ajuste pode quebrar um programa, uma atualização futura pode desfazer ou conflitar com ele. Por isso o projeto é desenhado em torno de **visibilidade e reversão**, não de promessas de "mais rápido" ou "mais seguro que o original".

## 2. O que o BigZ OS faz e o que NÃO faz

| Faz | Não faz |
|---|---|
| Aplica ajustes documentados, um a um, **depois de você ver o plano** | Aplicar mudanças escondidas |
| Usa **a sua** ISO oficial e **a sua** licença do Windows | Distribuir ISO, imagem ou binário da Microsoft |
| Mantém Windows Update, Defender, UAC, SmartScreen, Store e Xbox **ativos** | Remover o Defender, desligar o UAC ou o Windows Update |
| Publica código-fonte e o histórico do CI | Embutir binários opacos, ofuscação ou telemetria oculta |
| Registra o que mudou e permite **reverter** | Prometer ganho de FPS/latência sem benchmark reproduzível |
| | Ativar o Windows, incluir KMS/MAS, cracks ou bypass de licença |

## 3. Garantias e como verificá-las

> **Legenda de estado:** ✅ já definido em decisão do projeto · 🛠 meta, ainda **não entregue**.

1. **Dry-run (plano antes de aplicar).** O plano mostra cada item, escopo (usuário/máquina), risco e como reverter. Nada muda até você confirmar. 🛠 (F1)
2. **Reversão por ajuste.** A toolbox guarda o estado anterior antes de aplicar e restaura em ordem inversa. **Limites:** remoção de app Appx *na imagem* só se desfaz reconstruindo a mídia; se outro programa alterou o mesmo valor depois, a reversão avisa o conflito em vez de sobrescrever. 🛠 (F1)
3. **Segurança por padrão.** Política de risco 🟢/🟡/🔴: **nenhum item 🔴 em nenhuma edição** (remover WinSxS, Defender, Store, WebView2, WinRE; desligar UAC ou o Windows Update). Itens 🟡 exigem confirmação explícita. ✅ (ADR-005)
4. **Sem binários opacos.** Releases são geradas **somente** no CI público (GitHub Actions). Cada release traz `SHA256SUMS` e **atestação de proveniência** que qualquer pessoa confere:
   ```
   gh attestation verify <arquivo> -R BigZ-OS/BigZ-OS
   ```
   (`BigZ-OS/BigZ-OS` é o repositório oficial previsto; ainda não foi criado.) 🛠
5. **Código assinado.** Pretendemos assinar os pacotes (Authenticode). Sem assinatura, o SmartScreen pode avisar; dizemos isso na página de download. 🛠
6. **Testes em VM** a cada build do Windows suportado, com matriz de compatibilidade pública. 🛠
7. **Revisão.** Mudanças em tweaks exigem **2 revisores** e a documentação do "porquê" ([modelo](modelo-por-que-tweak.md)). 🛠

## 4. Riscos que continuam existindo (sem rodeios)
- **Você está modificando o Windows.** Pode surgir incompatibilidade com um programa, driver, anticheat ou atualização. Teste em VM e faça backup.
- **Atualizações do Windows** podem reverter ou conflitar com ajustes. A matriz de testes cobre apenas as builds listadas; fora dela, é por sua conta.
- **Falsos positivos de antivírus.** Scripts que alteram o sistema são frequentemente sinalizados. Se acontecer, publicaremos o hash, o nome da detecção e o envio à Microsoft; **não** orientamos desativar o antivírus para rodar o projeto.
- **Termos da Microsoft.** O projeto não distribui o Windows, mas modificar sua própria cópia está sujeito aos termos de licença da Microsoft. Pontos duvidosos estão marcados para revisão jurídica no relatório interno.
- **Cópias falsas.** Projetos assim são alvo de imitações com malware. **Baixe só do repositório oficial** e confira o `SHA256SUMS`/atestação.
- **Sem garantia.** Software fornecido "como está" (ver licença).

## 5. Como confiar sem acreditar na nossa palavra
- Leia o código; é aberto.
- Rode primeiro o **dry-run** e leia o plano.
- Teste em **VM**.
- Confira o hash e a atestação de cada release.
- Veja os ajustes no catálogo e a justificativa de cada um.
- Em dúvida, **use o Windows padrão**.

## 6. Privacidade
Telemetria **desligada por padrão**; qualquer coleta futura será opt-in, documentada e desativável. 🛠 (ADR-009, Cloud). Não coletamos dados no uso local da toolbox.

## 7. Relatando problemas de segurança
Não abra Issue pública para vulnerabilidades. Use o canal privado descrito em `SECURITY.md` (contato **a definir**). Tempo de resposta e política de divulgação serão publicados lá.

## 8. Fontes
Decisões e pesquisas do projeto: [`02-seguranca-legal-qa.md`](02-seguranca-legal-qa.md), [`01-arquitetura-v0.md`](01-arquitetura-v0.md), [`03-plano-consolidado.md`](03-plano-consolidado.md).
