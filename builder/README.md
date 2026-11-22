# Builder BigZ OS · F2

O builder usa uma ISO oficial fornecida pelo usuário e gera mídia local UEFI x64 para o índice escolhido. A matriz de seleção aceita os builds 26200 e 26300 do Windows 11 Home (Core) ou Pro (Professional). O inventário mostra o build registrado na imagem, junto do índice e da edição. A seleção aceita os metadados previstos. O boot e o comportamento da instalação ainda exigem uma rodada em VM. [Windows 11 release information](https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information)

## Preparação

Use Windows PowerShell 5.1 x64 e instale **Deployment Tools** do Windows ADK oficial, que inclui `oscdimg`. Abra a sessão **como administrador** para `-Build`, `-Plan -InspectMedia` ou `-RecoverJob`. O script solicita o procedimento no erro de pré-requisito. O builder não abre o UAC por conta própria. [Windows ADK](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install/)

Use `C:\DEV\BigZ-Lab\iso\` para a mídia de entrada, `C:\DEV\BigZ-Lab\work\` para jobs e `C:\DEV\BigZ-Lab\out\` para saídas. A cópia de trabalho e a saída exigem espaço livre em volumes NTFS locais. O builder processa um job por vez. Para registrar a comparação com uma referência oficial, informe seu valor com `-ExpectedSha256`. O hash calculado sem referência identifica o arquivo lido. [Página oficial do Windows 11](https://www.microsoft.com/software-download/windows11)

## Prévia e primeiro build Balanced

Prévia estática a partir da raiz do repositório, sem montar mídia:

```powershell
.\builder\Build-BigZIso.ps1 -Plan -Profile balanced
```

Em uma sessão elevada, com uma única ISO Home/Pro na pasta `iso`:

```powershell
$media = @(Get-ChildItem -LiteralPath 'C:\DEV\BigZ-Lab\iso' -Filter '*.iso' -File)
if ($media.Count -ne 1) { throw 'Selecione explicitamente a ISO oficial Home/Pro.' }
$builder = 'C:\DEV\PROJETOS_MDEV\BigZ OS\builder\Build-BigZIso.ps1'
& $builder -Plan -InspectMedia -Profile balanced -IsoPath $media[0].FullName |
    Select-Object -ExpandProperty ImageInventory |
    Format-Table Index, Name, Edition, Build, Architecture, DefaultLanguage

$build = @{
    Build = $true
    Profile = 'balanced'
    IsoPath = $media[0].FullName
    WindowsEdition = 'Professional'
    WorkRoot = 'C:\DEV\BigZ-Lab\work'
    OutputPath = 'C:\DEV\BigZ-Lab\out\BigZ-Balanced-x64-pt-BR.iso'
    Verbose = $true
}
& $builder @build
```

`-WindowsEdition Professional` seleciona o índice Pro se ele for único. Use `-ImageIndex` caso precise selecionar pelo número listado, ou use os dois argumentos se quiser exigir que coincidam. Se a ISO estiver conectada, ejete-a antes de chamar o builder. A montagem da ISO é somente leitura. Manutenção e commit acontecem na cópia do WIM exportado. [Inventário e manutenção DISM](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-image-management-command-line-options-s14?view=windows-11)

O Balanced desprovisiona Microsoft News quando o inventário confirma o nome completo e o publicador permitidos. Quando o pacote está ausente, o manifesto registra esse resultado. O registro offline grava a seleção do BigZ em `HKLM\SOFTWARE\BigZOS\Profile` **dentro da imagem**. O executor permite somente operações declarativas revisadas. O Windows Setup recebe o índice exportado 1 e, quando compatível com a mídia, o idioma. Disco, conta, termos, ativação e requisitos de hardware seguem no fluxo do Windows. [DISM e Appx](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-app-package--appx-or-appxbundle--servicing-command-line-options?view=windows-11) · [Arquivo de resposta](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-automation-overview) · [Oscdimg](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/oscdimg-command-line-options?view=windows-11)

A saída local inclui a ISO, `.iso.manifest.json` e `.iso.sha256`. O manifesto identifica a origem e seu SHA-256, o perfil, a edição Windows de origem, os ajustes, as ferramentas e a saída. O builder só publica o nome final da ISO depois dos dois arquivos auxiliares. Um job concluído libera o payload de trabalho e preserva `job.json` e os logs. Resultados de builds e imagens Windows ficam fora do versionamento, da CI, das releases e do backup do projeto.

## Enterprise Evaluation

Para o laboratório de avaliação, use a ISO oficial Enterprise Evaluation fornecida pelo testador e localizada em `C:\DEV\BigZ-Lab\iso\`. Selecione `-TestOnly -WindowsEdition EnterpriseEval` e uma saída como `C:\DEV\BigZ-Lab\out\BigZ-Balanced-TESTONLY.iso`. O modo aceita só `EnterpriseEval` e marca o job e o manifesto com `testOnly: true`. Relate build e resultados como Enterprise Evaluation. Validação Home/Pro é outra execução, com a licença aplicável à sua instância. [Microsoft Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-enterprise) · [ADR-010](../docs/decisoes/ADR-010-licenca-das-vms-de-teste.md)

## Recuperação e testes

Após interrupção, encontre o ID mostrado no erro ou no diretório `work\job-…`. Para recuperar **aquele job**, rode em sessão elevada:

```powershell
.\builder\Build-BigZIso.ps1 -RecoverJob '<GUID-do-job>' -WorkRoot 'C:\DEV\BigZ-Lab\work'
```

A recuperação descarrega a hive do job, descarta sua montagem identificada do WIM e desconecta a ISO quando o dispositivo coincide com o diário. Se a propriedade da montagem estiver incerta, preserve o job e use a mensagem e `dism.log` para diagnosticar. Se o diário já indica os três recursos liberados, a recuperação apenas registra o estado `recovered`. Em ambos os casos, `-RecoverJob` preserva os logs, o payload de trabalho e os arquivos em `out`, inclusive uma eventual pasta `.bigz-<ID>` com a ISO parcial. Uma nova execução usa outro job e parte da ISO original. O mesmo comando pode ser repetido se a ISO final, o manifesto e o checksum ainda não existirem.

`oscdimg.exe`, `reg.exe` e `robocopy.exe` gravam stdout e stderr nos logs do job. As mensagens de falha indicam a etapa, o código de saída quando disponível e o final do log, mesmo sob `$ErrorActionPreference = 'Stop'`. O DISM e a montagem de mídia usam cmdlets com tratamento de erros próprio.

Os testes locais usam arquivos temporários. Montagem, DISM e registro offline são simulados. O teste de stderr executa um processo auxiliar que só grava texto e devolve um código de saída:

```powershell
Import-Module Pester -RequiredVersion 5.7.1
Invoke-Pester -Path @(
    '.\tests\unit\BigZ.Tweaks.Tests.ps1',
    '.\tests\unit\BigZ.Media.Tests.ps1',
    '.\tests\integration\Build-BigZIso.Tests.ps1'
)
```
