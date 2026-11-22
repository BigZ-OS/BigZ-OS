$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Import-Module (Join-Path $repoRoot 'shared/modules/BigZ.Tweaks/BigZ.Tweaks.psd1') -Force -ErrorAction Stop
Import-Module (Join-Path $repoRoot 'builder/modules/BigZ.Media.psm1') -Force -ErrorAction Stop

InModuleScope BigZ.Media {
    Describe 'Builder F2 sem operações de manutenção no host' {
        BeforeAll {
            function Get-TestImageFixture {
                param([string]$Edition = 'Professional', [int]$Build = 26300, [int]$Index = 2, [int]$Architecture = 9)
                [pscustomobject]@{
                    Index = $Index; Edition = $Edition; Build = $Build; Architecture = $Architecture
                    InstallationType = 'Client'; DefaultLanguage = 'pt-BR'
                }
            }

            function Get-TestSourceFixture {
                param([string]$Path)
                [IO.File]::WriteAllBytes($Path, [byte[]]@(3, 1, 4))
                [pscustomobject]@{
                    Path = $Path
                    Bytes = 3
                    Sha256 = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
                    ImageMetadataVerified = $false
                }
            }

            function Get-TestPlanFixture {
                $action = [pscustomobject]@{
                    type = 'appx.deprovision'; packageName = 'Microsoft.BingNews'
                }
                [pscustomobject]@{
                    Id = 'balanced'
                    ProfileMarker = [pscustomobject]@{
                        type = 'registry.setOfflineValue'; hive = 'software'; key = 'BigZOS'
                        name = 'Profile'; valueType = 'String'; value = 'balanced'
                    }
                    OfflineTweaks = @([pscustomobject]@{
                        Id = 'appx.remove-news'; Phase = 'offline'; Risk = 'medium'; SecurityImpact = 'none'
                        Status = 'Declared'; Action = $action
                        Requires = @{ builds = @(26200, 26300); architectures = @('x64'); admin = $true }
                    })
                }
            }
        }

        It 'seleciona 25H2 e 26H2 por edição ou índice, sem aceitar ambiguidade' {
            $pro = Get-TestImageFixture
            $homeImage = Get-TestImageFixture -Edition Core -Build 26200 -Index 1
            (Get-BigZSelectedImage @($pro, $homeImage) 0 Professional).Build | Should Be 26300
            (Get-BigZSelectedImage @($pro, $homeImage) 1 '').Build | Should Be 26200
            { Get-BigZSelectedImage @($pro, $pro) 0 Professional } | Should Throw
            { Get-BigZSelectedImage @($pro, $homeImage) 1 Professional } | Should Throw
            { Get-BigZSelectedImage @((Get-TestImageFixture -Architecture 12)) 2 '' } | Should Throw
        }

        It 'reserva TestOnly para EnterpriseEval e exige saída marcada' {
            $evaluation = Get-TestImageFixture -Edition EnterpriseEval
            (Get-BigZSelectedImage @($evaluation) 2 '' -TestOnly).Edition | Should Be 'EnterpriseEval'
            { Get-BigZSelectedImage @($evaluation) 2 '' } | Should Throw
            { Get-BigZSelectedImage @((Get-TestImageFixture)) 2 '' -TestOnly } | Should Throw
            $markedPath = Join-Path $TestDrive 'Balanced-TESTONLY.iso'
            $normalPath = Join-Path $TestDrive 'Balanced.iso'
            (Get-BigZArtifactLayout $markedPath -TestOnly).Iso | Should Be $markedPath
            { Get-BigZArtifactLayout $normalPath -TestOnly } | Should Throw
            { Get-BigZArtifactLayout $markedPath } | Should Throw
        }

        It 'valida a identidade Appx exata, o publicador e a ausência' {
            $news = [pscustomobject]@{
                DisplayName = 'Microsoft.BingNews'
                PackageName = 'Microsoft.BingNews_1.2.3.0_neutral_~_8wekyb3d8bbwe'
                PublisherId = '8wekyb3d8bbwe'
            }
            (Get-BigZVerifiedPackageName @($news) 'Microsoft.BingNews') | Should Be $news.PackageName
            [bool](Get-BigZVerifiedPackageName @() 'Microsoft.BingNews') | Should Be $false
            { Get-BigZVerifiedPackageName @($news, $news) 'Microsoft.BingNews' } | Should Throw
            $news.PublisherId = 'fakepublisher'
            { Get-BigZVerifiedPackageName @($news) 'Microsoft.BingNews' } | Should Throw
            { Get-BigZVerifiedPackageName @() 'Microsoft.WindowsStore' } | Should Throw
        }

        It 'revalida builds e restringe registro offline a alvos tipados' {
            $planFixture = Get-TestPlanFixture
            Assert-BigZPlannedImage $planFixture (Get-TestImageFixture)
            $planFixture.OfflineTweaks[0].Requires.builds = @(26200)
            { Assert-BigZPlannedImage $planFixture (Get-TestImageFixture) } | Should Throw
            $planFixture.ProfileMarker.key = 'Policies\Microsoft\Windows\WindowsUpdate'
            { Assert-BigZOfflineAction $planFixture.ProfileMarker } | Should Throw
        }

        It 'grava índice 1 e idioma sem automatizar disco, conta, ativação ou termos' {
            $template = Join-Path (Get-Module BigZ.Media).ModuleBase '../templates/unattend.xml'
            $testMedia = Join-Path $TestDrive 'media-xml'
            [void][IO.Directory]::CreateDirectory((Join-Path $testMedia 'sources'))
            '[Available UI Languages]', 'pt-BR = 3' |
                Set-Content -LiteralPath (Join-Path $testMedia 'sources/lang.ini') -Encoding UTF8
            Write-BigZAnswerFile @{ MediaPath = $testMedia } $template 'pt-BR'
            [xml]$resultXml = Get-Content -LiteralPath (Join-Path $testMedia 'autounattend.xml') -Raw
            $resultXml.SelectSingleNode('//*[local-name()="MetaData"]/*[local-name()="Value"]').InnerText | Should Be '1'
            $resultXml.SelectSingleNode('//*[local-name()="SetupUILanguage"]/*[local-name()="UILanguage"]').InnerText | Should Be 'pt-BR'
            (@($resultXml.SelectNodes('//*[local-name()="ProductKey" or local-name()="AcceptEula" or local-name()="DiskConfiguration" or local-name()="RunSynchronous" or local-name()="AutoLogon"]'))).Count | Should Be 0
        }

        It 'publica ISO e manifesto coerentes usando exportação, montagem e captura simuladas' {
            $source = Get-TestSourceFixture (Join-Path $TestDrive 'simulated-install.iso')
            $job = Initialize-BigZJob (Join-Path $TestDrive 'work') $source.Path
            $artifact = Get-BigZArtifactLayout (Join-Path $TestDrive 'Balanced.iso')
            Mock Open-BigZIso { 'R:\' }
            Mock Get-BigZInstallerLayout { 'R:\sources\install.esd' }
            Mock Get-BigZImageInventory {
                if ($ImagePath -like '*install.wim') { Get-TestImageFixture -Index 1 }
                else { Get-TestImageFixture }
            }
            Mock Copy-BigZInstaller {}
            Mock Export-BigZInstallImage {}
            Mock Close-BigZIso {}
            Mock Open-BigZWim {}
            Mock Invoke-BigZAppxDeprovision { [pscustomobject]@{ Result = 'already-absent'; PackageName = $null } }
            Mock Write-BigZOfflineRegistry {}
            Mock Close-BigZWim {}
            Mock Write-BigZAnswerFile {}
            Mock Invoke-BigZOscdimg { [IO.File]::WriteAllBytes($Path, [byte[]]@(1, 2, 3, 4)) }

            $tools = [pscustomobject]@{ DismVersion = 'fake'; Oscdimg = @{ Version = 'fake' } }
            $fixture = Get-TestPlanFixture
            $result = Invoke-BigZBuildPipeline $job $tools $source $fixture $artifact 'simulated-template' 0 Professional
            $manifest = Get-Content -LiteralPath $artifact.Manifest -Raw | ConvertFrom-Json
            $result.Mode | Should Be 'build'
            $manifest.SourceImage.Index | Should Be 2
            $manifest.SourceContainer | Should Be 'ESD'
            $manifest.OutputImage.Index | Should Be 1
            $manifest.Output.Sha256 | Should Be (Get-FileHash -LiteralPath $artifact.Iso -Algorithm SHA256).Hash
            $manifest.OfflineChanges[0].Result | Should Be 'already-absent'
            (Get-Content -LiteralPath $artifact.Checksum) | Should Be "$($manifest.Output.Sha256) *Balanced.iso"
            Assert-MockCalled Export-BigZInstallImage -Times 1 -Exactly -ParameterFilter { $Index -eq 2 }
            Assert-MockCalled Close-BigZWim -Times 1 -Exactly -ParameterFilter { $Save }
        }

        It 'mantém staging e recursos do job identificáveis para recuperação' {
            $work = Join-Path $TestDrive 'work-recovery'
            $source = Get-TestSourceFixture (Join-Path $TestDrive 'simulated-recovery.iso')
            $job = Initialize-BigZJob $work $source.Path
            $job.Record.WimMountRequested = $true
            Save-BigZJobState $job 'mounting-wim'
            Mock Assert-BigZElevation {}
            Mock Get-BigZWindowsToolchain { @{ Reg = 'mock' } }
            Mock Close-BigZOfflineHive {}
            Mock Close-BigZWim {}
            Mock Close-BigZIso {}

            $result = Restore-BigZMediaJob -WorkRoot $work -Id $job.Id -Confirm:$false
            $result.JobId | Should Be $job.Id
            $finished = Read-BigZJob $work ([guid]$job.Id)
            $finished.Record.Stage | Should Be 'recovered'
            Assert-MockCalled Close-BigZWim -Times 1 -Exactly -ParameterFilter { $Job.Id -eq $finished.Id -and -not $Save }
        }

        It 'recusa consultar como própria uma montagem que aponta para outro WIM' {
            $work = Join-Path $TestDrive 'work-foreign'
            $source = Get-TestSourceFixture (Join-Path $TestDrive 'simulated-foreign.iso')
            $job = Initialize-BigZJob $work $source.Path
            $job.Record.WimMountRequested = $true
            Mock Get-BigZMountedImage { [pscustomobject]@{ Path = $Job.MountPath; ImagePath = 'C:\foreign.wim'; ImageIndex = 1 } }
            { Get-BigZOwnedWimMount $job } | Should Throw
            $job.Record.WimMountRequested | Should Be $true
        }

        It 'bloqueia saídas existentes e deixa arquivos finais ausentes se oscdimg falhar' {
            $isoPath = Join-Path $TestDrive 'Interrupted.iso'
            $artifact = Get-BigZArtifactLayout $isoPath
            [IO.File]::WriteAllText($artifact.Checksum, 'preexistente')
            { Assert-BigZArtifactVacant $artifact } | Should Throw

            $second = Get-BigZArtifactLayout (Join-Path $TestDrive 'Other.iso')
            $job = [pscustomobject]@{ Id = [guid]::NewGuid().ToString('N') }
            Mock Invoke-BigZOscdimg { throw 'Falha simulada' }
            { Publish-BigZMediaArtifact $job @{} $second @{} 'TEST' } | Should Throw
            (Test-Path -LiteralPath $second.Iso) | Should Be $false
            (Test-Path -LiteralPath $second.Manifest) | Should Be $false
            (Test-Path -LiteralPath $second.Checksum) | Should Be $false
        }
    }
}
