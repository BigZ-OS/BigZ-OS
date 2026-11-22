# ADR-007 — Nada de ativadores, KMS ou MAS

- **Status:** Aceita · **Data:** 2026-11-21 · **Donos:** Beatrix + Lulu · **Revisores:** Rikku, Tellah

## Contexto
A licença do Windows diz: "You may not bypass or circumvent activation" (§5). Ativadores são alvo frequente de notificações da Microsoft e são detectados pelo Microsoft Defender (ex.: MAS). Muitos "Windows modificados" embutem ativação, o que mistura pirataria com o produto e destrói a confiança. A Carta proíbe cracks e bypass de licença.

## Decisão
- Nenhum ativador, emulador KMS, script HWID/KMS38/TSforge, MAS ou equivalente no código, no catálogo da toolbox, nos perfis ou no `autounattend.xml`.
- **Nem na documentação:** não citamos nomes, links nem instruções de ativadores, nem como "alternativa". Para ativação, apontamos só os canais oficiais da Microsoft.
- O builder e a toolbox **não tocam no estado de ativação**. O teste P0 confere que a ativação não muda.
- Issues e PRs que pedirem ou incluírem ativadores são fechados com link para esta ADR (Código de Conduta / CONTRIBUTING).

## Consequências
- ✅ Evita o tipo de conteúdo que mais gera notificação de remoção e detecção de antivírus.
- ✅ Mensagem clara: "BigZ requer licença original".
- ⚠️ Parte do público de "Windows modificado" espera ativação embutida. Aceitamos perder esse público.

## Fontes
- Licença do Windows 11 (OEM, abr/2024), §5 Authorized Software and Activation: <https://www.microsoft.com/content/dam/microsoft/usetm/documents/windows/11/oem-(pre-installed)/UseTerms_OEM_Windows_11_English.pdf>
- Defender bloqueando o MAS: <https://www.notebookcheck.net/Microsoft-Defender-might-be-right-to-block-Microsoft-Activation-Scripts-MAS.1200734.0.html>
- Contranotificação no github/dmca envolvendo repositório derrubado a pedido da Microsoft (conteúdo não lido em detalhe; não verificado): <https://github.com/github/dmca/blob/master/2019/12/2019-12-03-msft-counternotice.md>
- Carta do projeto, regra 1: [../00-CARTA-DO-PROJETO.md](../00-CARTA-DO-PROJETO.md)
