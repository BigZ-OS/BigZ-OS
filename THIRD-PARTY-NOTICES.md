# Avisos de terceiros (THIRD-PARTY-NOTICES)

> Rascunho (Tellah, 2026-11-21). Esta lista registra **código de terceiros efetivamente incorporado** ao BigZ OS e as fontes **candidatas** estudadas. Quem copiar qualquer trecho deve **adicionar uma linha na tabela "Incorporado"** (origem, arquivo, commit, licença, copyright) **no mesmo PR**. Não é parecer jurídico.

## Regras
1. Só entra código com licença **compatível com GPL-3.0-or-later** (MIT, BSD, Apache-2.0, GPL-3.0…). Manter o aviso de copyright e o texto da licença originais.
2. **Código sem licença não pode ser copiado.** Caso do **tiny11builder** (ver abaixo).
3. Licenças sem permissão de uso comercial ou com restrição de campo de uso são incompatíveis.
4. Não redistribuímos binários da Microsoft.
5. Dependências instaladas pelo usuário (winget, módulos) mantêm suas próprias licenças; não são redistribuídas por nós.

## Incorporado
| Origem | Arquivo(s) no BigZ | Commit de origem | Licença | Copyright |
|---|---|---|---|---|
| *(nenhum trecho registrado até a data deste rascunho; Cid/Rikku devem preencher ao copiar algo)* | | | | |

## Fontes estudadas (licença verificada nos clones locais em `builder/_refs/`)
| Projeto | Licença | Situação | Commit lido |
|---|---|---|---|
| [WinUtil](https://github.com/ChrisTitusTech/winutil) — CT Tech Group LLC | MIT | Reaproveitável com aviso | `70c23c80641d7370532af2f619b2842658600842` |
| [Win11Debloat](https://github.com/Raphire/Win11Debloat) — Raphire | MIT | Reaproveitável com aviso | `3d8feefbbc672d55af4b84c8681a1996538e04e2` |
| [Sophia Script for Windows](https://github.com/farag2/Sophia-Script-for-Windows) — farag2 | MIT | Reaproveitável com aviso | `2c43986f8b35da925954be9a2e72087aa5ed6b27` |
| [trusted-uninstaller-cli](https://github.com/Ameliorated-LLC/trusted-uninstaller-cli) — Ameliorated LLC | MIT | Reaproveitável com aviso (usado pelo Atlas) | `f325e9d950e6b37003a46c786fd1b6c20f3180dd` |
| [Atlas](https://github.com/Atlas-OS/Atlas) | GPL-3.0 (pacote e Atlas Manager, conforme README) | Compatível com GPL-3.0; **não** depender do AME Wizard (não é open source). Clone local vazio — licença lida no GitHub | — |
| [tiny11builder](https://github.com/ntdevlabs/tiny11builder) — ntdevlabs | **Nenhuma licença no checkout** (`NOTICE.md` do checkout: "contains no standalone license file") | **NÃO COPIAR CÓDIGO.** Apenas reimplementar a ideia do zero (ADR-008) ou obter permissão por escrito | `38f7ab6` |

> A licença deve ser **reconferida no repositório de origem na data da cópia**; as licenças podem mudar.

## Textos das licenças MIT (cópia integral dos arquivos de licença)

### WinUtil

```text
MIT License

Copyright (c) 2022 CT Tech Group LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

```

### Win11Debloat

```text
MIT License

Copyright (c) 2020 Raphire (https://github.com/Raphire)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

```

### Sophia Script for Windows

```text
MIT License

Copyright (c) 2023 farag2

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

```

### trusted-uninstaller-cli

```text
The MIT License (MIT)

Copyright (c) Ameliorated LLC. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
