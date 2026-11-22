# ADR-006 — Uso de marcas da Microsoft

- **Status:** Aceita · **Data:** 2026-11-21 · **Dona:** Beatrix · **Revisores:** Yuna, Tellah

## Contexto
As diretrizes de marca da Microsoft proíbem usar suas marcas no nome de produto, app, domínio ou rede social, alterar ou combinar as marcas, usar logos e ícones, e sugerir afiliação. O uso referencial verdadeiro ("compatível com") é permitido, sempre menos destacado que a marca própria. O nome "BigZ OS" também pode fazer leigos acharem que o produto dispensa licença do Windows.

## Decisão
- **Proibido:** "Windows" (ou variações, abreviações e trocadilhos como "Win", "Windoze") no nome do produto, das edições, do domínio, do repositório, de contas sociais e de pacotes. Proibido usar logo, ícone, símbolo ou design da Microsoft (incluindo o de quatro janelas ou algo parecido), fontes da Microsoft (ex.: Segoe) em assets distribuídos, e wallpapers e ícones do Windows.
- **Permitido:** texto simples e referencial, menor que a marca BigZ: "ferramentas open source **para Windows 11**".
- **Rodapé obrigatório** no site, no README e na tela "Sobre" da toolbox: *"Windows é marca registrada do grupo de empresas Microsoft. O BigZ OS não é afiliado, patrocinado nem endossado pela Microsoft."*
- O README e o site dizem logo no início: **"Requer Windows 11 original e licenciado."**
- `TRADEMARK.md` (Tellah) define o uso da marca BigZ por forks (renomear).

## Consequências
- ✅ Remove o principal gatilho de reclamação de marca.
- ⚠️ A Yuna precisa revisar logos e mockups (rodada 2 do plano).
- **[ADVOGADO]** Busca de anterioridade e registro de "BigZ OS" (INPI/USPTO).
- Pendência: o PDF das diretrizes **específicas do Windows** (2026) não foi lido (não verificado). Revisar quando possível.

## Fontes
- Microsoft Trademark and Brand Guidelines: <https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general>
- Windows Trademark Guidelines 2026 (PDF): <https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/mscle/documents/presentations/Windows_Trademark_Guidelines_2026.pdf>
- Termos de uso da Microsoft (fontes não redistribuíveis; trecho exato não verificado): <https://www.microsoft.com/en-us/legal/terms-of-use>
- Relatório, seção 1.4: [02-seguranca-legal-qa.md](../02-seguranca-legal-qa.md)
