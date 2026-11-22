# BigZ OS — Status de Engenharia F0/F1

O esqueleto local, o motor de ajustes e o planejador da ISO estão implementados. Os 20 testes Pester passaram no Windows PowerShell 5.1, com estado de registro em memória e arquivos temporários isolados. A chamada `-Plan` da Toolbox também retornou um ajuste pelo motor real em modo declarativo.

## O que funciona

| Entrega | Comportamento |
| --- | --- |
| [Motor BigZ.Tweaks](../shared/modules/BigZ.Tweaks/BigZ.Tweaks.psd1) | Valida objetos JSON, versões, elegibilidade por edição, fase, dependências, conflitos, risco, proteção e alvos. Executa os dez pares HKCU/DWORD permitidos no catálogo F1. Retorna fonte, risco, estado desejado e diagnósticos no plano. |
| Aplicação e reversão | Captura o valor anterior e sua existência antes da escrita. Persiste o diário em JSON, verifica depois de escrever e restaura em ordem inversa. Retoma aplicação ou reversão com o mesmo diário após uma interrupção. Recusa outro alvo e preserva valores divergentes. |
| [Planejamento da ISO](../builder/Build-BigZIso.ps1) | Resolve os perfis DEV, Balanced e Full Performance, valida a herança e as referências, e separa ajustes offline, opções online e seleções de primeiro uso. Com `-IsoPath`, lê o tamanho e calcula SHA-256. O índice solicitado fica registrado como pendente de validação. |
| [Esquemas](../shared/schemas/) e [perfis](../shared/profiles/) | Formalizam a estrutura dos JSONs. O motor também aplica regras de negócio em execução, incluindo a lista exata de valores autorizados. A chave canônica de Full Performance é `full-performance`. |
| Estrutura | O template de `unattend.xml` é uma reserva para F2. Os documentos e os testes da Segurança continuam nas pastas atuais. `tests/hyperv/` fica reservado para orquestração do laboratório. O XAML existente continua em `toolbox/Toolbox.xaml`; qualquer mudança futura para `toolbox/ui/` deve atualizar o carregador no mesmo commit. |

Os perfis de build usam `shared/profiles/`. As pré-seleções online são lidas de `toolbox/catalog/profiles.json`, a mesma fonte da Toolbox. Os três perfis começam sem remoções offline. Appx permitido pode aparecer no plano, condicionado ao inventário real da imagem na próxima fase. O motor e o builder desta rodada foram escritos para o projeto. [ADR-002](decisoes/ADR-002-stack-do-builder.md) · [ADR-004](decisoes/ADR-004-contrato-json-de-tweaks-e-apps.md) · [ADR-005](decisoes/ADR-005-politica-de-risco-de-tweaks.md) · [Avisos de terceiros](../THIRD-PARTY-NOTICES.md)

## Como testar com segurança

Na raiz do repositório, em Windows PowerShell 5.1:

```powershell
Import-Module .\shared\modules\BigZ.Tweaks\BigZ.Tweaks.psd1
Get-BigZTweakPlan -CatalogPath .\shared\tweaks -Edition dev -Id explorer.show-file-extensions -DeclarationOnly
.\builder\Build-BigZIso.ps1 -Plan -Profile balanced
.\toolbox\Start-BigZToolbox.ps1 -Plan -Edition dev -Id explorer.show-file-extensions

Import-Module Pester -RequiredVersion 3.4.0
Invoke-Pester -Script @(
    '.\tests\unit\BigZ.Tweaks.Tests.ps1',
    '.\tests\integration\Build-BigZIso.Tests.ps1'
)
```

`-DeclarationOnly` valida sem consultar o registro. `Invoke-BigZTweak -DryRun` consulta o estado para mostrar diferenças e termina antes de criar o diário ou escrever no alvo. A escrita nativa fica limitada ao usuário corrente em Windows 11 25H2 x64 Home ou Pro. Para testar essa integração na VM, use `Invoke-BigZTweak`, `Test-BigZTweak` e `Undo-BigZTweak`. Informe um `-JournalPath` em pasta privada e use o mesmo diário ao retomar ou reverter. O motor bloqueia concorrência entre seus processos para o mesmo alvo. Um editor externo que grave o exato valor desejado não é distinguível pelo registro.

O teste de hash usa um arquivo de bytes conhecido com extensão `.iso`. Nenhuma imagem Windows foi montada, nenhum DISM foi executado e nenhum ajuste foi aplicado ao registro deste PC. [Testes do motor](../tests/unit/BigZ.Tweaks.Tests.ps1) · [Testes do planejador](../tests/integration/Build-BigZIso.Tests.ps1)

## O que falta

- Validar o adaptador nativo e os efeitos visuais dos ajustes em VMs Windows 11 25H2 Home e Pro. A confirmação de escrita do DWORD nos testes simulados cobre a lógica do motor. A interface do Windows pode exigir nova sessão para refletir algumas preferências.
- Validar origem oficial, metadados WIM/ESD, índice e boot UEFI. O planejador sempre retorna `CanBuild=false` nesta fase. Servicing offline por DISM, remoções Appx e a geração de ISO com ADK entram em F2.
- Validar o XML contra a imagem real no Windows SIM. Integrar a suíte isolada à CI e manter o laboratório Hyper-V separado.
