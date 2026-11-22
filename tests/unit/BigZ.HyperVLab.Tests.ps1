#Requires -Version 5.1
# Testes unitários das guardas do laboratório Hyper-V. Não precisam do Hyper-V nem de admin:
# os cmdlets Get-VM/Get-Command são simulados (Mock).

Describe 'BigZ.HyperVLab — guardas de segurança' {
    BeforeAll {
        $root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
        Import-Module (Join-Path $root 'tests/hyperv/BigZ.HyperVLab.psm1') -Force -ErrorAction Stop

        # Sem o módulo Hyper-V no host de CI, cria um stub para poder simular Get-VM.
        $script:createdStub = $false
        if (-not (Get-Command -Name 'Get-VM' -ErrorAction SilentlyContinue)) {
            function global:Get-VM {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Name', Justification = 'Stub substituído por Mock')]
                [CmdletBinding()]
                param([string]$Name)
            }
            $script:createdStub = $true
        }

        function Get-FakeVmObject {
            param([string]$Name = 'BigZ-REF', [string]$Notes = 'BigZ-Lab | teste', [string]$Path = 'C:\DEV\BigZ-Lab\vms', [string]$State = 'Off')
            [pscustomobject]@{ Name = $Name; Notes = $Notes; Path = $Path; State = $State }
        }
    }

    AfterAll {
        if ($script:createdStub) { Remove-Item -Path 'Function:\Get-VM' -ErrorAction SilentlyContinue }
    }

    Context 'Test-BigZLabPathUnderRoot' {
        It 'aceita caminho dentro da raiz' {
            Test-BigZLabPathUnderRoot -Path 'C:\DEV\BigZ-Lab\vms\BigZ-REF' -Root 'C:\DEV\BigZ-Lab\vms' | Should -BeTrue
        }
        It 'recusa a própria raiz' {
            Test-BigZLabPathUnderRoot -Path 'C:\DEV\BigZ-Lab\vms\' -Root 'C:\DEV\BigZ-Lab\vms' | Should -BeFalse
        }
        It 'recusa pasta irmã com o mesmo prefixo' {
            Test-BigZLabPathUnderRoot -Path 'C:\DEV\BigZ-Lab\vms2\X' -Root 'C:\DEV\BigZ-Lab\vms' | Should -BeFalse
        }
        It 'recusa escapar com ..' {
            Test-BigZLabPathUnderRoot -Path 'C:\DEV\BigZ-Lab\vms\..\..\Windows' -Root 'C:\DEV\BigZ-Lab\vms' | Should -BeFalse
        }
        It 'recusa caminho fora da raiz' {
            Test-BigZLabPathUnderRoot -Path 'C:\Users\x\VMs\Outra' -Root 'C:\DEV\BigZ-Lab\vms' | Should -BeFalse
        }
    }

    Context 'Test-BigZLabStartCapacity' {
        It 'permite ligar com memória livre suficiente' {
            (Test-BigZLabStartCapacity -FreeBytes 5GB -StartupBytes 4GB -MarginBytes 512MB).CanStart | Should -BeTrue
        }
        It 'recusa com 1,5 GB livres (cenário com os agentes rodando) e explica o motivo' {
            $r = Test-BigZLabStartCapacity -FreeBytes 1.5GB -StartupBytes 4GB -MarginBytes 512MB
            $r.CanStart | Should -BeFalse
            $r.Reason | Should -Match 'Pause os agentes'
        }
    }

    Context 'Assert-BigZLabElevation / Assert-BigZLabHyperV' {
        It 'falha com mensagem clara sem elevação' {
            Mock -ModuleName BigZ.HyperVLab Test-BigZLabElevation { $false }
            { Assert-BigZLabElevation } | Should -Throw -ExpectedMessage '*administrador*'
        }
        It 'não falha quando elevado' {
            Mock -ModuleName BigZ.HyperVLab Test-BigZLabElevation { $true }
            { Assert-BigZLabElevation } | Should -Not -Throw
        }
        It 'falha sem o módulo Hyper-V e não tenta ativá-lo' {
            Mock -ModuleName BigZ.HyperVLab Get-Command { $null }
            { Assert-BigZLabHyperV } | Should -Throw -ExpectedMessage '*NÃO o ativa*'
        }
    }

    Context 'Get-BigZLabVm protege VMs que não são do laboratório' {
        It 'retorna a VM marcada e dentro da pasta do laboratório' {
            Mock -ModuleName BigZ.HyperVLab Get-VM { Get-FakeVmObject -Path 'C:\DEV\BigZ-Lab\vms\BigZ-REF' }
            (Get-BigZLabVm -Name 'BigZ-REF' -LabRoot 'C:\DEV\BigZ-Lab').Name | Should -Be 'BigZ-REF'
        }
        It 'recusa VM sem o marcador BigZ-Lab' {
            Mock -ModuleName BigZ.HyperVLab Get-VM { Get-FakeVmObject -Notes 'VM pessoal' -Path 'C:\DEV\BigZ-Lab\vms\BigZ-REF' }
            { Get-BigZLabVm -Name 'BigZ-REF' -LabRoot 'C:\DEV\BigZ-Lab' } | Should -Throw -ExpectedMessage '*marcador*'
        }
        It 'recusa VM marcada mas fora da pasta do laboratório' {
            Mock -ModuleName BigZ.HyperVLab Get-VM { Get-FakeVmObject -Path 'D:\Outras\BigZ-REF' }
            { Get-BigZLabVm -Name 'BigZ-REF' -LabRoot 'C:\DEV\BigZ-Lab' } | Should -Throw -ExpectedMessage '*fora de*'
        }
        It 'falha se a VM não existe' {
            Mock -ModuleName BigZ.HyperVLab Get-VM { $null }
            { Get-BigZLabVm -Name 'Nada' } | Should -Throw -ExpectedMessage '*não encontrada*'
        }
    }

    Context 'Assert-BigZLabSingleVm (uma VM por vez)' {
        It 'recusa quando outra VM está ligada' {
            Mock -ModuleName BigZ.HyperVLab Get-VM { @((Get-FakeVmObject -Name 'Outra' -State 'Running'), (Get-FakeVmObject -Name 'BigZ-REF')) }
            { Assert-BigZLabSingleVm -ExceptName 'BigZ-REF' } | Should -Throw -ExpectedMessage '*uma VM por vez*'
        }
        It 'aceita quando só a própria VM está ligada' {
            Mock -ModuleName BigZ.HyperVLab Get-VM { @((Get-FakeVmObject -Name 'BigZ-REF' -State 'Running'), (Get-FakeVmObject -Name 'Outra')) }
            { Assert-BigZLabSingleVm -ExceptName 'BigZ-REF' } | Should -Not -Throw
        }
    }
}
