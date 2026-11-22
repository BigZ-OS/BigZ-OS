Describe 'Build-BigZIso -Plan' {
    BeforeAll {
        $root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
        $builder = Join-Path $root 'builder/Build-BigZIso.ps1'
        if (-not (Test-Path -LiteralPath $builder -PathType Leaf)) { throw "Builder ausente em '$builder'." }
    }

    It 'resolve DEV, Balanced e Full Performance sem mídia' {
        foreach ($edition in @('dev', 'balanced', 'full-performance')) {
            $result = & $builder -Plan -Profile $edition
            $result.Profile.Id | Should Be $edition
            ($result.Profile.Inheritance -join ',') | Should Be "base,$edition"
            $result.Profile.Target.Build | Should Be 26200
            $result.MediaInspected | Should Be $false
            $result.CanBuild | Should Be $false
        }
    }

    It 'calcula o hash somente lendo um arquivo de teste e não gera mídia' {
        $fake = Join-Path $TestDrive 'media de teste.iso'
        $destination = Join-Path $TestDrive 'saida.iso'
        [IO.File]::WriteAllBytes($fake, [byte[]]@(0, 1, 2, 3))
        $expectedHash = (Get-FileHash -LiteralPath $fake).Hash
        $result = & $builder -Plan -IsoPath $fake -ImageIndex 2 -OutputPath $destination
        $result.Source.Bytes | Should Be 4
        $result.Source.Sha256 | Should Be $expectedHash
        $result.Source.RequestedIndex | Should Be 2
        $result.Source.ImageMetadataVerified | Should Be $false
        (Test-Path -LiteralPath $destination) | Should Be $false
        (Get-FileHash -LiteralPath $fake).Hash | Should Be $expectedHash
    }

    It 'rejeita execução sem indicar modo e índice sem entrada' {
        { & $builder -Profile dev } | Should Throw
        { & $builder -Plan -ImageIndex 1 } | Should Throw
    }

    It 'preserva a prévia estática e checa o SHA-256 quando informado' {
        $source = Join-Path $TestDrive 'hash-source.iso'
        [IO.File]::WriteAllBytes($source, [byte[]]@(0, 1, 2, 3))
        $expected = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        (& $builder -Plan -IsoPath $source -ExpectedSha256 $expected).Source.ReferenceSha256Matched | Should Be $true
        { & $builder -Plan -IsoPath $source -ExpectedSha256 ('a' * 64) } | Should Throw
        { & $builder -Build -IsoPath $source -OutputPath (Join-Path $TestDrive 'unclear.iso') } | Should Throw
    }

    It 'rejeita herança circular antes de carregar mídia' {
        $profiles = Join-Path $TestDrive 'profiles'
        [void][IO.Directory]::CreateDirectory($profiles)
        '{"schemaVersion":1,"id":"dev","base":"dev","offlineTweaks":[],"optionalTweaks":[]}' |
            Set-Content -LiteralPath (Join-Path $profiles 'dev.json') -Encoding UTF8
        { & $builder -Plan -Profile dev -ProfilesPath $profiles } | Should Throw
    }

    It 'rejeita IDs de tweak desconhecidos em um perfil bem formado' {
        $profiles = Join-Path $TestDrive 'unknown'
        [void][IO.Directory]::CreateDirectory($profiles)
        Copy-Item -LiteralPath (Join-Path $root 'shared/profiles/base.json') -Destination $profiles
        '{"schemaVersion":1,"id":"dev","base":"base","offlineTweaks":["unknown.app"],"optionalTweaks":[]}' |
            Set-Content -LiteralPath (Join-Path $profiles 'dev.json') -Encoding UTF8
        { & $builder -Plan -Profile dev -ProfilesPath $profiles } | Should Throw
    }
}
