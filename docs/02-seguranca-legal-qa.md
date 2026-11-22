# 02 — Segurança, Conformidade Legal e QA (v0)

> Setor: Segurança, QA & Conformidade (Beatrix) · Reporta ao Auron · Data: 2026-11-21
> Status: **rascunho interno**. Nada foi publicado.
>
> ⚖️ **Aviso:** isto **não é parecer jurídico**. É uma leitura técnica dos termos públicos da Microsoft e de casos conhecidos. Os pontos marcados com **[ADVOGADO]** precisam de um advogado de software/propriedade intelectual antes do lançamento público.
> 🔎 O que não consegui confirmar numa fonte está marcado como **(não verificado)**.

---

## Resumo executivo

1. **O modelo da Carta está certo.** Os projetos que seguem no ar (Atlas OS, ReviOS, tiny11builder, WinUtil) distribuem **scripts/configurações** e trabalham sobre o Windows **oficial e licenciado do próprio usuário**. O caso de remoção documentado mais próximo (Ninjutsu OS, 2020) envolvia um "Windows modificado" com link de download.
2. **Linhas vermelhas:** nada de ISO/WIM/ESD/binários da Microsoft hospedados por nós; nada de ativação/KMS/HWID; nada de "Windows" no nome, domínio ou logo; nada de fontes, ícones ou wallpapers da Microsoft no nosso pacote.
3. **Zona cinzenta:** a licença proíbe "contornar restrições técnicas" (seção 2.c.iv). Foi o argumento usado pela BSA contra o Ninjutsu. Burlar TPM/CPU e a conta Microsoft no OOBE entra aqui → só como **opção desligada por padrão**, com aviso, e **[ADVOGADO]**.
4. **Segurança:** a Full Performance é a edição de maior risco. Regra: **nada que quebre o Windows Update ou o servicing** (WinSxS, CBS, stack de update) em nenhuma edição. Defender, VBS e mitigações só desligados por **opt-in explícito e reversível**.
5. **Confiança:** CI público no GitHub Actions, SHA-256 + atestado de proveniência (SLSA) em toda release, scripts sem ofuscação, SECURITY.md com reporte privado, PR com 2 revisores para tweaks.
6. **QA v0:** matriz de 3 edições × 2 hipervisores × 2 builds do Windows, com checklist de regressão (updates, Store, drivers, anti-cheat, WSL/Docker etc.).

---

## 1. Riscos legais

### 1.1 O que a licença do Windows 11 diz

Fonte: *Microsoft Software License Terms — Windows Operating System* (OEM, versão "Last updated April 2024"), PDF oficial: <https://www.microsoft.com/content/dam/microsoft/usetm/documents/windows/11/oem-(pre-installed)/UseTerms_OEM_Windows_11_English.pdf> (índice: <https://www.microsoft.com/en-us/useterms>).

> Nota: o índice da Microsoft lista só os termos **OEM** do Windows 11. Não achei termos **retail** do Windows 11 publicados. Um blog técnico relata o mesmo e diz que OEM e retail diferem pouco ([oofhours, 2024](https://oofhours.com/2024/12/29/love-hate-windows-imaging-and-licensing/)). Usar o texto OEM como referência é razoável, mas **(não verificado para retail)**.

| Cláusula (texto oficial, trecho) | O que significa para o BigZ |
|---|---|
| **2.c Restrictions** — "you may not … **(ii) publish, copy (other than the permitted backup copy), rent, lease, or lend the software**" | **Proíbe hospedar/distribuir ISO, WIM ou binários do Windows**, modificados ou não. É a base da regra nº 1 da Carta. |
| 2.c **(iii)** "transfer the software (except as permitted by this agreement)" | Não podemos "repassar" instalações prontas nem imagens pré-instaladas. |
| 2.c **(iv)** "**work around any technical restrictions or limitations in the software**" | **Zona cinzenta principal.** Burlar requisito de hardware, a conta Microsoft no OOBE ou limites de edição pode ser lido como violação. Desativar recursos por chaves documentadas (políticas de grupo, configurações) tem leitura bem mais segura. **[ADVOGADO]** |
| 2.c **(vi)** "reverse engineer, decompile, or disassemble the software … except … permitted by applicable law" | Não fazemos patch de binários do sistema (ex.: `uxtheme.dll`, `explorer.exe`). Customização do shell só por APIs, registro e apps próprios. |
| **5. Authorized Software and Activation** — "You may not bypass or circumvent activation." … "the software will attempt to repair itself by replacing any tampered Microsoft software" | **Proibido** qualquer ativador, KMS, HWID ou script de ativação na toolbox. Lembrete técnico: o Windows pode "reparar" arquivos alterados. Mais um motivo para não mexer em binários. |
| **6. Updates** — "The software periodically checks for system and app updates, and downloads and installs them for you. **You may obtain updates only from Microsoft or authorized sources** … you agree to receive these types of automatic updates" | Não podemos servir updates do Windows por espelho próprio. **Desativar updates contraria o espírito da cláusula 6** e é risco de segurança. Adiar ou pausar pelos mecanismos oficiais (Windows Update for Business, políticas) é o caminho defensável. **[ADVOGADO]** sobre "desativar" vs. "adiar". |
| 2.d.(iv) Virtualização — "one instance … whether that device is physical or virtual … separate license for each instance" | **Impacto no QA:** cada VM de teste precisa de licença. Usar a **avaliação de 90 dias do Windows 11 Enterprise** ([Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-enterprise)) ou licenças próprias. Veja a seção 4. |
| 2.e Backup copy — "a single copy of the software for backup purposes" | Base para o usuário gerar a **própria** ISO modificada para uso **próprio**. Não autoriza compartilhar a ISO gerada. |
| 7.a Hardware Specifications | Instalar em hardware sem suporte é desaconselhado pela Microsoft. A cobertura da imprensa diz que esses aparelhos "não têm direito a updates" ([Tom's Hardware](https://www.tomshardware.com/software/windows/microsoft-allows-windows-11-to-be-installed-on-older-unsupported-hardware-but-specifically-nixes-official-support-minimum-requirements-for-full-compatibility-remain-unchanged)). A página da Microsoft não foi lida diretamente **(não verificado)**. |

**Outras fontes da Microsoft:**
- Página de permissões de copyright: "For software downloads, unless expressly permitted in the accompanying License Terms or End-User License Agreement (EULA), Microsoft does not allow redistribution." — <https://www.microsoft.com/en-us/legal/intellectualproperty/copyright/permissions>
- Termos de uso: copiar software "to any other server or location for further reproduction or redistribution is expressly prohibited". As **fontes que acompanham produtos Microsoft** (ex.: Segoe UI) não podem ser modificadas nem redistribuídas — <https://www.microsoft.com/en-us/legal/terms-of-use> (via resumo de busca; **trecho exato não verificado**). **Impacto para o Design (Yuna):** não empacotar fontes, ícones nem wallpapers da Microsoft.
- Segundo a documentação do Atlas, a Microsoft permite **linkar para a página de download**, mas não direto para o arquivo ([Atlas docs](https://docs.atlasos.net/faq/install-faq/atlas-iso-files/)) **(não verificado na fonte da Microsoft)**. O tiny11builder baixa a ISO só de hosts da Microsoft ([usage.md](https://github.com/ntdevlabs/tiny11builder/blob/winui-preview/docs/usage.md)). **Recomendação:** o builder aceita a ISO que o usuário já tem, ou abre a página oficial de download. Nada de espelhos.

### 1.2 Como os projetos de referência se mantêm no ar

| Projeto | Modelo | O que distribui | Licença do código | Observações de risco |
|---|---|---|---|---|
| **Atlas OS** | *Playbook* aplicado sobre Windows oficial, via AME Wizard | Arquivos de configuração e ferramentas. "It does not change Windows activation; users need their own Windows installation and license." ([README](https://github.com/Atlas-OS/Atlas/blob/main/README.md)) | GPLv3 (playbook). Backend do AME (TrustedUninstaller) em MIT; GUI do AME é fechada ([README](https://github.com/Atlas-OS/Atlas/blob/main/README.md)) | Diz explicitamente: "Distributing ISO files violates Microsoft's terms and poses major safety risks" ([docs](https://docs.atlasos.net/faq/install-faq/atlas-iso-files/)) |
| **ReviOS** | Começou com ISO, hoje usa *Playbook* | Playbook. Os docs citam a ISO "in the past" ([revi.cc](https://revi.cc/docs/playbook/general)) | (não verificado) | **Motivo oficial da mudança não encontrado.** Os docs citam vantagens técnicas (não depender da versão do Windows). Dizer que foi por motivo legal é inferência **(não verificado)**. |
| **tiny11builder** | *Builder*: gera a ISO a partir da ISO oficial do usuário, com ferramentas Microsoft (DISM, oscdimg) | Código do builder. O oscdimg é baixado do servidor da Microsoft com SHA-256 fixado ([usage.md](https://github.com/ntdevlabs/tiny11builder/blob/winui-preview/docs/usage.md)) | Sem arquivo de licença: "This upstream checkout contains no standalone license file" ([NOTICE.md](https://github.com/ntdevlabs/tiny11builder/blob/winui-preview/NOTICE.md)) | ⚠️ O autor **também** publica ISOs prontas no Internet Archive ([archive.org](https://archive.org/details/tiny11_25H2)). Não achei relato de remoção, mas isso é **tolerância, não permissão**. **Não copiar esse comportamento.** |
| **WinUtil (Chris Titus)** | *Toolbox* pós-instalação em PowerShell | Script, executado por `irm https://christitus.com/win \| iex` ([README](https://github.com/ChrisTitusTech/winutil)) | MIT (pela barra lateral do repo) | Não mexe na imagem do sistema; só configurações e instalação de apps via winget. Menor exposição legal. |

**Padrão comum:** (a) nenhum binário da Microsoft hospedado; (b) o usuário fornece Windows e licença; (c) não mexe na ativação; (d) código aberto e auditável.

### 1.3 Casos de DMCA/remoção conhecidos

| Caso | O que aconteceu | Fonte | Lição |
|---|---|---|---|
| **Ninjutsu OS (jun/2020)** | A **BSA, em nome da Microsoft**, enviou notificação ao GitHub contra `ninjutsu-project.github.io`, um Windows 10 modificado para pentest com link de download. Duas alegações: (1) acesso a material "copyrighted, nonpublic, proprietary" da Microsoft; (2) "the link provides a **work around technical restrictions** of the software, which violates Microsoft's Software License Terms", citando funções como "Disable many of the annoying features built into windows". O GitHub retirou a página. | [TorrentFreak, 11/06/2020](https://torrentfreak.com/removing-annoying-windows-10-features-is-a-dmca-violation-microsoft-says-200611/) · [notificação no github/dmca](https://github.com/github/dmca/commit/e6911fbf79c67c6f9e834cb4bc7cdc10679318e7) · [discussão HN](https://news.ycombinator.com/item?id=23486887) | **O caso mais relevante para nós.** A cláusula 2.c.iv foi usada até contra uma lista de tweaks. O alvo central, porém, era a distribuição do sistema modificado. Mitigação: nunca distribuir imagem; documentar tweaks como **configurações suportadas**; evitar a linguagem "burlar/contornar". |
| **Vazamento do Windows 11 (2021)** | A Microsoft enviou DMCA contra cópias vazadas da build do Windows 11. | [PCMag via Medium](https://medium.com/pcmag-access/microsoft-files-dmca-takedown-notices-on-leaked-copies-of-windows-11-4d546845f6ee) · [TheWindowsClub](https://news.thewindowsclub.com/microsoft-files-dmca-takedown-notice-against-windows-11-leak-105857/) | A Microsoft age contra **redistribuição de imagens**. |
| **Outras notificações da Microsoft no GitHub** | O repositório público `github/dmca` tem notificações da Microsoft, ex.: [2019-03-14](https://github.com/github/dmca/blob/master/2019/03/2019-03-14-Microsoft.md), [2022-01-27](https://github.com/github/dmca/blob/master/2022/01/2022-01-27-microsoft.md), [contranotificação 2019-12-03](https://github.com/github/dmca/blob/master/2019/12/2019-12-03-msft-counternotice.md). Uma busca indicou que envolvem vazamento de código-fonte, Windows Server 2003 e um ativador KMS. | Links ao lado | **(não verificado: não li o conteúdo de cada notificação.)** O padrão sugere: ativadores e código/binário da Microsoft são alvo. |
| **Ghost Spectre** | **Não encontrei nenhuma notificação DMCA nem remoção** ligada ao Ghost Spectre. Achei só a política de DMCA de um site de download ([ghostspectre.org/dmca](https://www.ghostspectre.org/dmca)), que não prova remoção. Esse site pode não ser oficial. | — | O exemplo citado no pedido **não se confirma**. Isso não prova segurança jurídica: distribuir ISO modificada continua violando a cláusula 2.c.ii, havendo ou não ação da Microsoft. |

Como o GitHub age: em regra, dá ao dono do repositório cerca de **1 dia útil** para remover o conteúdo apontado, antes de desativar o repositório ([GitHub DMCA policy](https://docs.github.com/en/site-policy/content-removal-policies/dmca-takedown-policy)). → **Plano de contingência:** espelho do código (sem binários da Microsoft) em outro forge e backup no Drive, já previsto na Carta. Contranotificação só com advogado **[ADVOGADO]**.

### 1.4 Marca "Windows" (nome, site, logo)

Fonte: Microsoft Trademark and Brand Guidelines — <https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general>. As diretrizes específicas do Windows (PDF 2026) estão incorporadas a elas, mas não consegui extrair o texto do PDF **(não verificado)**: <https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/mscle/documents/presentations/Windows_Trademark_Guidelines_2026.pdf>.

Regras citadas da página geral:
- "Don't use Microsoft's Brand Assets in the name of your business, product, service, app, domain name, social media account…" → **proibido** "BigZ Windows", "WinBigZ", `bigzwindows.com`, `@bigzwindows`.
- "Don't alter … or misappropriate … by combining Microsoft's Brand Assets with other terms, misspellings…" → nada de "Windoze", "BigZ-Win11" etc.
- "Don't use Microsoft's logos, icons, or designs, in any manner." → nenhum logo de quatro janelas, nem parecido, no site, no instalador ou na arte.
- "Don't imply an affiliation, endorsement, sponsorship, or approval with or by Microsoft."
- **Permitido (uso referencial):** dizer a verdade sobre compatibilidade ("you may truthfully state whether your app is compatible or interoperable"), usar a marca **menos destacada** que a nossa e como adjetivo, com nota de rodapé de marca.

**Conclusão de marca:**
- ✅ "**BigZ OS** — ferramentas open source **para Windows 11**" (texto simples, menor que a marca BigZ).
- ✅ Rodapé: "Windows é marca registrada do grupo de empresas Microsoft. O BigZ OS não é afiliado, patrocinado nem endossado pela Microsoft."
- ⚠️ O nome "BigZ **OS**" pode fazer leigos acharem que é outro sistema que dispensa licença do Windows. Mitigação: o README e o site dizem logo no início "**requer Windows 11 original e licenciado**". Vale avaliar o nome com o setor de Comunidade/Design e **[ADVOGADO]** (busca de anterioridade da marca BigZ).

### 1.5 Conclusão legal — pode / não pode

| ✅ Podemos | ⚠️ Só com cuidado / opt-in / [ADVOGADO] | ❌ Não podemos |
|---|---|---|
| Publicar scripts, playbooks e configurações próprias, open source | Burlar TPM/CPU/Secure Boot (requisito de hardware) | Hospedar, espelhar ou linkar direto ISO/WIM/ESD/binário da Microsoft |
| Builder que roda **na máquina do usuário** sobre a **ISO oficial dele** | Burlar conta Microsoft/rede no OOBE | Distribuir ISO "BigZ" pronta, inclusive no Archive, torrent ou Drive |
| Remover apps provisionados e desativar recursos por **mecanismos documentados** (DISM, políticas, configurações) | Desativar (não adiar) Windows Update | Ativadores, KMS, HWID, scripts como MAS, cracks |
| Toolbox que instala apps de terceiros pelas **fontes oficiais** (winget) | Remover componentes do sistema (não apps) da imagem | Patch em binários do Windows (`uxtheme`, `explorer` etc.) |
| Usar "para Windows 11" de forma referencial | Redistribuir binários de terceiros (cada licença) | "Windows" no nome, domínio ou logo; logos/fontes/ícones da Microsoft |
| Linkar a página oficial de download da Microsoft | Licença do próprio BigZ: "uso comercial exige atribuição e contribuição de volta" **não é uma licença OSI** → afeta o SignPath (seção 3) | Prometer "legal/aprovado pela Microsoft" |

**Perguntas para o advogado [ADVOGADO]:**
1. Um builder que remove componentes e burla requisitos de hardware, rodando na máquina do usuário, viola a cláusula 2.c.iv? Quem responde, o projeto ou o usuário?
2. Riscos de DMCA §1201 (anti-circunvenção) nos EUA e equivalentes no Brasil (Lei 9.609/98, Lei de Software; Lei 9.610/98) para scripts de tweak.
3. Desativar vs. adiar o Windows Update à luz da cláusula 6.
4. Registro e anterioridade da marca "BigZ OS" no INPI/USPTO.
5. Compatibilidade da licença desejada (comercial com atribuição e contribuição) com GPL/MIT de código reaproveitado do Atlas/WinUtil.
6. Isenção de responsabilidade (disclaimer) e garantias: o que precisa constar para usuários no Brasil (CDC).

---

## 2. Segurança técnica

### 2.1 Polêmicas reais em "Windows modificados"

| Incidente | Fonte |
|---|---|
| ISOs piratas de Windows 10 Pro 22H2 em torrent traziam **Trojan.Clipper.231** (rouba criptomoeda) escondido na **partição EFI**, que antivírus costumam não varrer. Doctor Web, 2023; estimativa de ~US$ 19 mil desviados. | [TechSpot](https://www.techspot.com/news/99063-trojanclipper231-crypto-hijacker-infecting-windows-hidden-efi-partition.html) · [TweakTown](https://www.tweaktown.com/news/91975/pirated-copies-of-windows-10-feature-hidden-malicious-apps-designed-to-steal-crypto/index.html) |
| Windows pirata com **minerador + Xtreme RAT**. Os serviços maliciosos desativavam o Defender e baixavam payloads (eSentire, casos de fim de 2021 a início de 2022). | [eSentire](https://www.esentire.com/blog/pirated-windows-os-backdoored-with-cryptominer-and-xtreme-rat) · [Infosecurity](https://www.infosecurity-magazine.com/news/pirated-windows-os-cryptominer-and/) |
| **AtlasOS (2023):** críticas públicas por remover o Defender e desligar mitigações de CPU e VBS/HVCI (Alex Ionescu à Vice). O Atlas depois voltou com o Defender e tornou as opções configuráveis. | [Vice](https://www.vice.com/en/article/windows-for-gamers-rolls-dice-with-your-security-atlasos) · [Neowin](https://www.neowin.net/news/atlasos-says-defender-will-be-back-and-it-may-even-be-more-secure-than-original-windows-10/) · [Atlas e segurança](https://docs.atlasos.net/faq/general-faq/atlas-and-security/) |
| **Ghost Spectre:** guias descrevem edições que removem Windows Security, avisos do UAC e o serviço de Windows Update. A imagem vem de fonte não oficial e há muitos sites "oficiais" de SEO. Não achei auditoria independente. | [Candid.Technology](https://candid.technology/ghost-spectre-windows-11/) · [TweakTown](https://www.tweaktown.com/news/90388/windows-11-superlite-is-custom-build-that-disables-telemetry-and-bloatware/index.html) · [ElevenForum](https://www.elevenforum.com/t/ghost-spectre.48754/post-774389) (relato isolado de alerta do Malwarebytes, **não verificado**) |
| **Ativador MAS** detectado pelo Microsoft Defender. | [Notebookcheck](https://www.notebookcheck.net/Microsoft-Defender-might-be-right-to-block-Microsoft-Activation-Scripts-MAS.1200734.0.html) |
| Rede "**Stargazers Ghost Network**": cerca de 3.000 contas falsas no GitHub distribuindo malware (Lumma, Rhadamanthys etc.). **Risco para nós:** forks e clones falsos do BigZ. | [Yahoo/Check Point](https://www.yahoo.com/news/secretive-network-exploits-github-spread-110000882.html) |

**Lição:** o maior risco não é o tweak, é a **origem não verificável** da imagem. Daí a regra: nunca ISO pronta, sempre builder auditável + checksum + proveniência.

### 2.2 Catálogo de tweaks perigosos e nossa política

Legenda: 🟢 permitido padrão · 🟡 opt-in com aviso e reversão · 🔴 proibido em todas as edições.

| Tweak | Risco | Fonte | DEV | Balanced | Full Perf. |
|---|---|---|---|---|---|
| Apagar arquivos do **WinSxS** / "limpar" o component store manualmente | "may severely damage your system so that your PC might not boot and make it impossible to update" | [Microsoft Learn](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/clean-up-the-winsxs-folder) | 🔴 | 🔴 | 🔴 (só `DISM /StartComponentCleanup`, que é suportado) |
| Remover pacotes de servicing / stack do **Windows Update** (equivale ao "tiny11 core") | "Core cannot be updated or serviced"; remove WinRE; desativa Update e Defender, "cannot be reversed" | [tiny11builder](https://github.com/ntdevlabs/tiny11builder) · [usage.md](https://github.com/ntdevlabs/tiny11builder/blob/winui-preview/docs/usage.md) | 🔴 | 🔴 | 🔴 |
| **Desativar o Windows Update** (serviço desligado, bloqueio por hosts/firewall) | Fica sem correções de segurança; contraria a cláusula 6 da licença | Licença, seção 6 | 🔴 | 🔴 | 🔴 → usar **pausar/adiar** por política oficial (🟡) |
| Adiar feature updates / pausar updates por política | Baixo | Mecanismo oficial (WUfB) | 🟡 | 🟡 | 🟢 padrão: adiar feature updates; segurança mensal **ativa** |
| **Remover** o Defender (arquivos/pacotes) | Sem antivírus; quebra Windows Security; padrão visto em malware (eSentire) | [eSentire](https://www.esentire.com/blog/pirated-windows-os-backdoored-with-cryptominer-and-xtreme-rat) | 🔴 | 🔴 | 🔴 |
| **Desativar** o Defender | Sem proteção em tempo real. Alternativa limpa: instalar outro AV, que põe o Defender em **modo passivo** automaticamente. Com o Security Center desativado o Defender não detecta outro AV. | [MS Learn: compatibilidade](https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-antivirus-compatibility) · [Tamper Protection FAQ](https://learn.microsoft.com/en-us/defender-endpoint/faqs-on-tamper-protection) | 🔴 | 🔴 | 🟡 só com outro AV instalado; nunca desligar Tamper Protection por script |
| **Desligar o UAC** (`EnableLUA=0`) | Todo processo roda como admin; "some Universal Windows Platform apps might not work" | [MS Learn: UAC](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/user-account-control/architecture) | 🔴 | 🔴 | 🔴 (manter UAC padrão; no máximo 🟡 reduzir o escurecimento da tela) |
| Desligar **SmartScreen** | Downloads maliciosos passam sem aviso | Atlas lista como opção de segurança ([README](https://github.com/Atlas-OS/Atlas/blob/main/README.md)) | 🔴 | 🔴 | 🟡 |
| Desligar **mitigações de CPU** (Spectre/Meltdown) | Expõe a ataques de canal lateral | [Vice/Ionescu](https://www.vice.com/en/article/windows-for-gamers-rolls-dice-with-your-security-atlasos) | 🔴 | 🔴 | 🟡 (aviso forte; reversível) |
| Desligar **Memory Integrity (HVCI)** e **Virtual Machine Platform** | Menos proteção contra injeção de código e drivers maliciosos. A própria Microsoft cita isso como opção para jogos. Desligar o VMP quebra o **WSL**. | [Microsoft Support](https://support.microsoft.com/article/a255f612-2949-4373-a566-ff6f3f474613) · [Neowin](https://neowin.net/news/disable-these-features-to-improve-gaming-performance-in-windows-11) | 🔴 (DEV precisa de WSL) | 🟡 | 🟡 (sugerir reativar depois; **não padrão**) |
| Remover a **Microsoft Store** / frameworks UWP (VCLibs, .NET Native, WebView2) | Quebra winget (App Installer), apps UWP, Xbox/Game Pass, widgets e apps que usam WebView2 | tiny11 mantém Store e runtimes compartilhados na versão normal ([usage.md](https://github.com/ntdevlabs/tiny11builder/blob/winui-preview/docs/usage.md)) | 🔴 | 🔴 | 🔴 remover a Store; 🟡 remover apps da Store |
| Remover **Edge/WebView2** | Apps (incluindo Microsoft 365, Teams e widgets) dependem do WebView2 | tiny11 remove Edge/WebView2 ([usage.md](https://github.com/ntdevlabs/tiny11builder/blob/winui-preview/docs/usage.md)) | 🔴 WebView2 · 🟡 Edge | 🔴 WebView2 · 🟡 Edge | 🔴 WebView2 · 🟡 Edge |
| Remover **WinRE** / Restauração do Sistema | Sem recuperação em caso de boot quebrado | tiny11 core remove WinRE | 🔴 | 🔴 | 🔴 |
| **BitLocker/criptografia de dispositivo** | No 24H2 a criptografia é ativada em instalação limpa, com chave salva na conta Microsoft. Se a conta for perdida ou o tweak mexer no TPM/Secure Boot, **o usuário perde acesso aos dados**. | [Tom's Hardware](https://www.tomshardware.com/software/windows/windows-11-24h2-will-enable-bitlocker-encryption-for-everyone-happens-on-both-clean-installs-and-reinstalls) · [Windows Latest](https://windowslatest.com/2024/05/08/microsoft-confirms-windows-11-24h2-turns-on-device-encryption-by-default) · [TechRadar](https://www.techradar.com/computing/windows/warning-check-your-pcs-windows-11-encryption-feature-to-make-sure-your-data-is-not-at-risk) | 🟢 manter; a toolbox **mostra onde está a chave de recuperação** | idem | 🟡 permitir não ativar a criptografia automática **na instalação limpa**; nunca desligar em disco já criptografado sem backup da chave |
| Burlar TPM/Secure Boot/CPU | Pode ficar sem updates; risco legal (2.c.iv); Secure Boot desligado facilita bootkits (ex.: BlackLotus) | [Tom's Hardware](https://www.tomshardware.com/software/windows/microsoft-allows-windows-11-to-be-installed-on-older-unsupported-hardware-but-specifically-nixes-official-support-minimum-requirements-for-full-compatibility-remain-unchanged) · [BlackLotus](https://en.wikipedia.org/wiki/BlackLotus) | 🟡 | 🟡 | 🟡 (desligado por padrão; **[ADVOGADO]**) |
| Patch em binários do sistema / temas não assinados | Viola 2.c.vi; o Windows pode "reparar" os arquivos; risco de não dar boot | Licença 2.c.vi e 5 | 🔴 | 🔴 | 🔴 |
| Desligar telemetria por política/configuração | Baixo. Alguns níveis só existem no Enterprise/Education **(não verificado)** | — | 🟢 | 🟢 | 🟢 |
| Tweaks de anti-cheat sensíveis (drivers, presets agressivos) | Easy Anti-Cheat acusou "Untrusted System File" após o preset Standard do WinUtil | [Fórum Chris Titus](https://forum.christitus.com/t/discord-epic-games-easy-anti-cheat-untrusted-system-file-amdlhk64-dll-after-running-standard-preset/130) | — | 🟡 | 🟡 + teste obrigatório no QA (seção 4) |

### 2.3 Mitigação por edição

**Princípios para as três edições:**
1. **Update e servicing intactos.** Teste de aceite: `DISM /Online /Cleanup-Image /RestoreHealth` e um update cumulativo precisam passar após aplicar a edição.
2. **Opt-in explícito** para qualquer item 🟡: tela com o risco em linguagem simples, link da fonte e botão "reverter".
3. **Reversível por padrão:** cada tweak traz `Apply` e `Revert` e registra o estado anterior em JSON. Antes de mudanças de risco, a toolbox cria um ponto de restauração.
4. **Sem persistência estranha:** nenhuma tarefa agendada ou serviço do BigZ fica rodando após a instalação, salvo o atualizador da própria toolbox, que é opcional e auditável.
5. **Nada baixado em tempo de execução sem hash fixado.** Mesmo padrão do tiny11 com o oscdimg.

**Full Performance (maior risco):**
- O padrão continua **seguro**: Defender ativo, UAC ativo, updates de segurança ativos, VBS ativo.
- O perfil "Desempenho extremo" é um **segundo passo opt-in**, com lista de riscos, checkbox "entendo" e reversão em um clique.
- Selo visível na toolbox: "**Modo de risco ativo**" enquanto qualquer item 🟡 estiver ligado.
- Nunca desligar Defender e SmartScreen juntos sem outro AV detectado.

**DEV:** manter WSL/VMP/Hyper-V, Developer Mode opcional, nada de desligar UAC. Docker e WSL entram no teste de regressão.

**Balanced:** apenas 🟢 por padrão. É a edição "recomendada para quem não sabe escolher".

---

## 3. Política de confiança (releases e processo)

### 3.1 Release
| Item | Política | Fonte/ferramenta |
|---|---|---|
| Build | **Só no CI público** (GitHub Actions, runner hospedado). Nenhum artefato de release feito em máquina pessoal. | — |
| Conteúdo | Só nosso código (scripts .ps1, configs, app da toolbox). **Zero binário da Microsoft.** Binários de terceiros: só por download da fonte oficial com SHA-256 fixado. | Carta, regra 1 |
| Checksums | `SHA256SUMS.txt` em toda release; exibido no README e na página de release. | — |
| Proveniência | `actions/attest` (antes `attest-build-provenance`) → o usuário confere com `gh attestation verify <arquivo> -R <org>/<repo>`. Em runner hospedado isso dá **SLSA Build L2**; com workflow reutilizável isolado, **L3**. | [GitHub Docs](https://docs.github.com/actions/security-guides/using-artifact-attestations-to-establish-provenance-for-builds) · [blog SLSA L3](https://github.blog/enterprise-software/devsecops/enhance-build-security-and-reach-slsa-level-3-with-github-artifact-attestations/) · [actions/attest-build-provenance](https://github.com/actions/attest-build-provenance) |
| Assinatura de código (Authenticode) | Assinar `.ps1` e o `.exe` da toolbox. Opção gratuita: **SignPath Foundation** (OSS). Exige **licença OSI**, repositório público, MFA de toda a equipe e a atribuição "Free code signing provided by SignPath.io, certificate by SignPath Foundation". | [signpath.org](https://signpath.org/) · [termos](https://signpath.org/terms) · [SignPath OSS](https://about.signpath.io/product/open-source) |
| ⚠️ Conflito | A licença desejada na Carta (uso comercial exige atribuição e contribuição) **provavelmente não é OSI** e pode **impedir o SignPath gratuito**. Decisão conjunta com Tellah (Comunidade) e Auron. Alternativa: certificado pago ou serviço de assinatura da Microsoft (custo e elegibilidade **não verificados**). | — |
| Builds reproduzíveis | Meta v1: mesma tag → mesmo hash (versões fixas das actions por SHA de commit, sem timestamps em zip: `SOURCE_DATE_EPOCH`, ordem de arquivos estável). Um segundo workflow refaz o build e compara hashes. | [reproducible-builds.org](https://reproducible-builds.org/) |
| Distribuição | **Só** GitHub Releases do repositório oficial e o site oficial (que aponta para lá). Nada de Drive, Mega ou torrent para usuários. O Drive é só backup interno. | — |
| One-liner `irm \| iex` | Se existir, o script baixa a release, **confere SHA-256 e assinatura** antes de executar. A documentação recomenda "baixar, inspecionar, rodar". | Boa prática citada em [Gridinsoft](https://blog.gridinsoft.com/behavior-win32-winutilabuse-c/) |
| Anti-falsificação | Página "Downloads oficiais" com o único domínio e repositório válidos. Monitorar clones/forks com nome parecido (Stargazers Ghost Network). | [Check Point via Yahoo](https://www.yahoo.com/news/secretive-network-exploits-github-spread-110000882.html) |

### 3.2 Falsos positivos de antivírus em PowerShell
Por que acontece: scripts que mexem em Defender, serviços e registro com privilégio de admin, baixados da internet, parecem comportamento de malware. Exemplo: a detecção `Behavior:Win32/WinUtilAbuse.C` ([Gridinsoft](https://blog.gridinsoft.com/behavior-win32-winutilabuse-c/)); ativadores como o MAS também são bloqueados ([Notebookcheck](https://www.notebookcheck.net/Microsoft-Defender-might-be-right-to-block-Microsoft-Activation-Scripts-MAS.1200734.0.html)).

Como lidar:
1. **Não ofuscar.** Nada de base64, `-EncodedCommand`, `Invoke-Expression` de strings montadas ou compressão de script. Código legível é a melhor defesa.
2. **Não desativar o Defender "por baixo"** (exclusões amplas, desligar Tamper Protection, matar serviços). Isso é o que malware faz.
3. **Assinar** scripts e executável (3.1).
4. **Antes de cada release:** varrer os artefatos com o Defender local e com o VirusTotal (o upload torna o arquivo público; só artefatos já públicos). Registrar o resultado nas notas da release.
5. **Falso positivo confirmado:** enviar ao Microsoft Security Intelligence ([wdsi/filesubmission](https://www.microsoft.com/wdsi/filesubmission), [aka.ms/wdsi](https://aka.ms/wdsi)) como "incorrectly detected" e aos outros fornecedores que detectarem. Abrir issue pública com hash, nome da detecção e status. Fonte do processo: [MS Learn](https://learn.microsoft.com/en-us/defender-endpoint/defender-endpoint-false-positives-negatives). Relatos de 2026 dizem que até apps assinados continuam sinalizados depois do envio ([Q&A](https://learn.microsoft.com/en-ca/answers/questions/5929545/microsoft-defender-false-positive-and-wdsi-submiss)). Paciência e transparência.
6. **Nunca** mandar o usuário desligar o antivírus para instalar o BigZ.

### 3.3 SECURITY.md (modelo a criar em `comunidade/` ou na raiz do repo)
Conteúdo mínimo, segundo o [GitHub Docs](https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository): versões suportadas e como reportar. Proposta:
- Versões suportadas: a última release estável e a anterior.
- Como reportar: **GitHub Private Vulnerability Reporting** (ativar no repo) ou e-mail dedicado do projeto (a criar; **não** usar e-mail pessoal).
- Prazos-alvo: confirmar em 72 h, triagem em 7 dias, correção crítica em 30 dias. São metas iniciais, a calibrar.
- Escopo: scripts do builder, toolbox e workflows de CI. Fora de escopo: bugs do próprio Windows (encaminhar à Microsoft).
- Divulgação coordenada via GitHub Security Advisories.
- Seção "**Downloads oficiais**": hashes, repo e domínio únicos.

### 3.4 Processo de revisão de PR
- Proteção da branch `main`: PR obrigatório, CI verde, **sem force-push**, commits assinados (recomendado).
- `CODEOWNERS`: `builder/` → Cid + Beatrix; `toolbox/tweaks/` → Rikku + Beatrix; `.github/workflows/` → Cloud + Beatrix.
- **2 aprovações** para tweaks 🟡 e para workflows; 1 para docs.
- Todo PR de tweak precisa ter, no template: o que muda (chaves e valores); **fonte** (Microsoft Learn de preferência); classe 🟢/🟡/🔴; como reverter; edições afetadas; evidência de teste em VM (checklist 4.3).
- CI obrigatório: PSScriptAnalyzer, Pester (testes de apply/revert), varredura de segredos, Dependabot para actions, actions fixadas por SHA, workflows com `permissions:` mínimas. Recomendado: OpenSSF Scorecard.
- Proibido em PR: binários (exceto ícones e imagens próprias), downloads sem hash, código ofuscado, telemetria do BigZ sem opt-in.
- Contribuidores novos: workflow que exige aprovação manual para rodar CI em PR de fork.

---

## 4. Plano de QA v0

### 4.1 Ambiente
- **Licenças das VMs:** a licença exige uma licença por instância, virtual ou física (seção 2.d.iv). Usar a **avaliação de 90 dias do Windows 11 Enterprise** ([Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-enterprise)) ou licenças Pro/Home próprias. As VMs prontas "Windows 11 development environment" da Microsoft ficaram indisponíveis desde out/2024 ([Neowin](https://www.neowin.net/news/microsofts-official-windows-11-virtual-machines-are-no-longer-available/)); status atual **não verificado**.
  - ⚠️ A avaliação é **Enterprise**, e os usuários finais terão **Home/Pro**. Validar Home/Pro com ao menos uma licença real antes do v1.
- **Hyper-V:** VM **Geração 2**, Secure Boot com modelo "Microsoft Windows", **vTPM** ativado ([guia Microsoft Tech Community](https://techcommunity.microsoft.com/blog/itopstalkblog/how-to-run-a-windows-11-vm-on-hyper-v/3713948)). Checkpoint "limpo" antes de cada execução.
- **VirtualBox 7:** suporta TPM 2.0 e EFI/Secure Boot para Windows 11 **(não verificado nesta pesquisa)**. Útil para testar em host sem Hyper-V e sem VBS aninhado.
- **Máquina física de referência (v1):** ao menos 1 PC com GPU dedicada para jogos, anti-cheat e drivers reais. A VM não cobre GPU.
- Automação: Pester + scripts de coleta (`Get-WindowsUpdateLog`, `DISM /CheckHealth`, `sfc /verifyonly`, `Get-AppxPackage`, `Get-MpComputerStatus`, `Confirm-SecureBootUEFI`, `manage-bde -status`), salvos como artefato.

### 4.2 Matriz de testes v0

| # | Edição | Hipervisor | Windows base | Caminho | Prioridade |
|---|---|---|---|---|---|
| 1 | Balanced | Hyper-V | 11 25H2 (atual) | Builder → instalação limpa | P0 |
| 2 | Balanced | VirtualBox | 11 25H2 | Toolbox sobre instalação existente | P0 |
| 3 | DEV | Hyper-V | 11 25H2 | Builder → instalação limpa | P0 |
| 4 | DEV | Hyper-V | 11 25H2 | Toolbox sobre instalação existente | P1 |
| 5 | Full Perf. (padrão seguro) | Hyper-V | 11 25H2 | Builder → instalação limpa | P0 |
| 6 | Full Perf. + perfil extremo (todos 🟡) | Hyper-V | 11 25H2 | Aplicar → **reverter** | P0 |
| 7 | Todas | Hyper-V | Build anterior suportada (ex.: 24H2) | Builder | P1 |
| 8 | Todas | Hyper-V | Insider/próxima build | Builder (detectar quebras cedo) | P2 |
| 9 | Balanced | Hyper-V | 25H2 | Upgrade in-place (feature update) **após** aplicar a edição | P0 |
| 10 | Full Perf. | Físico | 25H2 | Jogos + anti-cheat | P1 (v1) |

> Builds: o README do Atlas cita 25H2 (build 26200) e 26H2 (build 26300) ([README](https://github.com/Atlas-OS/Atlas/blob/main/README.md)). Cid (Engenharia) deve fixar as builds-alvo oficiais do BigZ.

### 4.3 Checklist de regressão (por execução)

**Integridade e updates (bloqueante, P0)**
- [ ] `sfc /scannow` sem violação nova · `DISM /Online /Cleanup-Image /RestoreHealth` OK
- [ ] Windows Update encontra e **instala** o cumulativo do mês + atualização do Defender
- [ ] Feature update / upgrade in-place não falha (linha 9 da matriz)
- [ ] Ativação continua "ativado" (sem mudança em relação ao Windows de base)
- [ ] WinRE presente (`reagentc /info`) · ponto de restauração criado pela toolbox
- [ ] **Reverter** todos os tweaks volta o estado ao snapshot de referência (diff de registro e serviços)

**Segurança (bloqueante, P0)**
- [ ] Defender ativo com definições atualizadas (exceto opt-in documentado) · Tamper Protection ligado
- [ ] UAC ativo (`EnableLUA=1`) · SmartScreen conforme a edição
- [ ] Secure Boot e TPM inalterados · VBS/HVCI conforme a edição
- [ ] BitLocker: status registrado; chave de recuperação localizável antes e depois
- [ ] Nenhum serviço, tarefa agendada ou conexão de rede do BigZ além do documentado (comparar Autoruns e `netstat` antes e depois)
- [ ] Artefatos da release: hash confere, atestado verifica, varredura AV registrada

**Apps e plataforma (P0/P1)**
- [ ] Microsoft Store abre e instala um app · **winget** funciona (`winget install` de teste)
- [ ] Edge/WebView2: um app que usa WebView2 abre
- [ ] Explorer, menu Iniciar, barra de tarefas e Configurações abrem sem erro após 3 reinícios
- [ ] Impressão, áudio, rede Wi-Fi/Ethernet, Bluetooth (físico)

**Drivers (P1, físico no v1)**
- [ ] Windows Update instala drivers · instalador de GPU NVIDIA/AMD/Intel conclui
- [ ] Gerenciador de Dispositivos sem dispositivo desconhecido novo

**Jogos (Full Perf. e Balanced, P1)**
- [ ] Steam, Epic, Xbox app/Game Pass instalam e abrem
- [ ] Anti-cheat: Easy Anti-Cheat, BattlEye e Riot Vanguard (requer TPM/Secure Boot, **não verificado**) iniciam sem erro de "arquivo não confiável"
- [ ] DirectX/VC++ runtimes presentes · Game Mode e GPU scheduling conforme a edição
- [ ] Benchmark simples (mesmo jogo/cena) antes e depois, para provar o ganho de forma honesta

**Ferramentas dev (DEV, P0)**
- [ ] WSL2 instala e inicia uma distro · Docker Desktop (backend WSL2) roda `hello-world`
- [ ] Hyper-V/VMP ativos · Windows Terminal, Git, VS Code, Node/Python via winget
- [ ] Visual Studio Build Tools compila um projeto de teste · Developer Mode opcional funciona

**Critério de saída v0:** todos os P0 verdes em 25H2 nas linhas 1, 3, 5, 6 e 9; nenhum item 🔴 presente no código (verificação automática por lista de chaves proibidas no CI).

---

## 5. Próximos passos sugeridos (para o Auron decidir)
1. **[ADVOGADO]** Levar as 6 perguntas da seção 1.5 a um advogado antes de qualquer lançamento público.
2. ADR: "Política de tweaks 🟢/🟡/🔴" (este documento como base) → `docs/decisoes/`.
3. Tellah + Beatrix: decidir a licença do BigZ considerando o SignPath (exige OSI).
4. Cloud: workflow de release com SHA256SUMS + atestado, actions fixadas por SHA.
5. Rikku/Cid: cada tweak no catálogo com fonte, classe, `Apply/Revert`. Nada 🔴.
6. Yuna: identidade sem marcas/fontes/ícones da Microsoft; rodapé de marca.
7. Beatrix: montar a VM Hyper-V de referência e escrever os testes Pester do checklist P0.

## Limitações desta pesquisa
- Texto **retail** da licença do Windows 11 não encontrado; usei o OEM (abr/2024).
- PDF das diretrizes de marca **específicas do Windows** (2026) não foi lido.
- Conteúdo das notificações DMCA da Microsoft de 2019/2022 no `github/dmca` não foi lido individualmente.
- Nenhum caso de DMCA contra o **Ghost Spectre** encontrado.
- Motivo oficial da troca de ISO por playbook no **ReviOS** não encontrado.
- Passos de TPM no VirtualBox 7 e requisitos exatos de anti-cheat não confirmados.
