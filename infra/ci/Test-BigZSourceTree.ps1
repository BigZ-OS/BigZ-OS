[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$raw = @(& git -C $root ls-tree -r -z --name-only HEAD)
if ($LASTEXITCODE -ne 0) { throw 'O Git não conseguiu ler a árvore que seria distribuída.' }
$tracked = @(($raw -join [string][char]10) -split '\x00' | Where-Object { $_ })
if (-not $tracked.Count) { throw 'A verificação do Git não retornou arquivos.' }
foreach ($path in $tracked) {
    if ($path -match '\.(iso|wim|esd|swm|vhdx?)(\.(sha256|manifest\.json))?\z' -or
        $path -match '(^|/)[^/]*-TESTONLY(\.|/|\z)') {
        throw "Artefato de laboratório ou Windows rastreado pelo Git: '$path'."
    }
    if ($path -like '*.manifest.json') {
        $content = @(& git -C $root show "HEAD:$path")
        if ($LASTEXITCODE -ne 0) { throw "Manifesto inacessível: '$path'." }
        $manifest = $content -join [Environment]::NewLine | ConvertFrom-Json -ErrorAction Stop
        if ($manifest.testOnly -eq $true) { throw "Manifesto de avaliação rastreado pelo Git: '$path'." }
    }
}
