# Política de Segurança — BigZ OS

> **Rascunho — não publicado.** O contato `[CONTATO-SEGURANCA]` e o domínio `[DOMINIO-OFICIAL]` ainda serão definidos pelo mantenedor.

O BigZ OS é um conjunto de scripts e ferramentas open source aplicados sobre o **Windows 11 original e licenciado** do usuário. Não distribuímos imagens nem binários da Microsoft ([ADR-001](docs/decisoes/ADR-001-sem-distribuicao-de-binarios-microsoft.md)). Esta política diz como reportar vulnerabilidades e como verificar que um download é autêntico.

## Versões suportadas

| Versão | Recebe correções de segurança |
|---|---|
| Última release estável | ✅ |
| Release estável anterior | ✅ (por 90 dias após a nova release) |
| Pré-releases, branches e forks | ❌ |

Builds do Windows suportados: os listados na matriz de compatibilidade da release (inicialmente Windows 11 25H2 x64, Home/Pro).

## Como reportar uma vulnerabilidade

**Não abra issue pública** para falhas de segurança.

1. **Preferencial:** use o **reporte privado de vulnerabilidades do GitHub**, na aba *Security* → *Report a vulnerability* do repositório oficial.
2. **Alternativa:** e-mail para `[CONTATO-SEGURANCA]` com o assunto `[BigZ SECURITY]`.

Inclua, se possível:
- versão do BigZ e build do Windows (`winver`);
- edição (DEV, Balanced, Full Performance) e se usou o builder ou a toolbox;
- passos para reproduzir, impacto esperado e prova de conceito;
- se o problema já é público.

### Nossos prazos-alvo
| Etapa | Prazo |
|---|---|
| Confirmação de recebimento | até 72 horas |
| Triagem e classificação de severidade | até 7 dias |
| Correção de severidade crítica/alta | até 30 dias |
| Divulgação | coordenada com quem reportou, via GitHub Security Advisory |

São metas de um projeto voluntário, não garantias contratuais. Daremos crédito a quem reportar, se quiser.

## Escopo

**Dentro do escopo**
- Scripts do **builder** e o `autounattend.xml` gerado.
- **Toolbox** (CLI/GUI), motor de tweaks, catálogos e perfis.
- Workflows de CI/release, `SHA256SUMS` e atestados.
- Qualquer tweak que reduza a proteção do sistema **sem** o aviso e o opt-in exigidos pela [ADR-005](docs/decisoes/ADR-005-politica-de-risco-de-tweaks.md). Para nós, isso é vulnerabilidade.
- Escalonamento de privilégio pelo processo elevado da toolbox, injeção de comandos via catálogo, download sem verificação de hash.

**Fora do escopo**
- Vulnerabilidades do próprio Windows ou de apps de terceiros instalados via winget: reporte à Microsoft (<https://msrc.microsoft.com/>) ou ao fornecedor.
- Sites, ISOs ou "builds BigZ" não oficiais (ver abaixo).
- Problemas que exigem que o atacante já seja administrador da máquina.

## Downloads oficiais e verificação

- **Único local de download:** GitHub Releases do repositório oficial <https://github.com/BigZ-OS/BigZ-OS/releases>. O site oficial `[DOMINIO-OFICIAL]` só aponta para lá.
- **O BigZ OS nunca distribui ISO.** Qualquer "ISO do BigZ OS" pronta para download **não é nossa** e deve ser tratada como possivelmente maliciosa.
- Toda release traz `SHA256SUMS.txt` e um **atestado de proveniência** gerado no CI público.

Verifique antes de executar (PowerShell):

```powershell
# 1) Hash do arquivo baixado: compare com a linha correspondente em SHA256SUMS.txt
Get-FileHash .\bigz-toolbox-vX.Y.Z.zip -Algorithm SHA256

# 2) Proveniência (requer GitHub CLI): confirma que o arquivo foi gerado pelo CI do repositório oficial
gh attestation verify .\bigz-toolbox-vX.Y.Z.zip -R BigZ-OS/BigZ-OS

# 3) Assinatura Authenticode dos scripts, quando a release for assinada
Get-AuthenticodeSignature .\bigz-toolbox\*.ps1 | Format-Table Status, SignerCertificate, Path
```

## Antivírus e falsos positivos

Scripts que alteram configurações do Windows às vezes são marcados por antivírus.
- **Nunca** pedimos para você desligar o antivírus para instalar o BigZ.
- Nosso código não é ofuscado. Você pode ler cada script antes de rodar.
- Se o Defender ou outro antivírus marcar um arquivo **oficial** (o hash confere com o `SHA256SUMS.txt`), abra uma issue com o nome da detecção e o hash. Nós enviamos o arquivo para análise como falso positivo ([Microsoft Security Intelligence](https://www.microsoft.com/wdsi/filesubmission)).
- Se o hash **não** confere, apague o arquivo e baixe de novo da página oficial.

## Princípios de segurança do projeto

- Segurança **ligada por padrão** em todas as edições: Windows Update, Defender, UAC, SmartScreen, Store, WinRE ([ADR-005](docs/decisoes/ADR-005-politica-de-risco-de-tweaks.md)).
- Nada de ativadores, KMS ou cracks ([ADR-007](docs/decisoes/ADR-007-sem-ativadores.md)).
- Builds só no CI público, actions fixadas por SHA, permissões mínimas.
- Mudanças em tweaks, no motor e em workflows exigem **2 aprovações**, uma delas do time de Segurança/QA.
- Telemetria desligada por padrão ([ADR-009](docs/decisoes/ADR-009-infraestrutura.md)).

## Aviso

O BigZ OS é fornecido "no estado em que se encontra", sem garantias, conforme a licença do projeto. "Windows" é marca registrada do grupo de empresas Microsoft. O BigZ OS não é afiliado, patrocinado nem endossado pela Microsoft.
