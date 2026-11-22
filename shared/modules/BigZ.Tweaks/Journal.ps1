function Get-BigZJournalPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'Informe -JournalPath para registrar a operação.' }
    $fullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    if ([IO.Path]::GetExtension($fullPath) -ine '.json' -or
        -not [IO.Directory]::Exists([IO.Path]::GetDirectoryName($fullPath))) {
        throw 'O diário deve ser um arquivo .json em uma pasta existente.'
    }
    return $fullPath
}

function Save-BigZJournal {
    param([string]$Path, $Journal, [switch]$Create)

    $directory = [IO.Path]::GetDirectoryName($Path)
    $temporary = [IO.Path]::Combine($directory, ".bigz-$([guid]::NewGuid().ToString('N')).tmp")
    $Journal.UpdatedAtUtc = [datetime]::UtcNow.ToString('o')
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($Journal | ConvertTo-Json -Depth 10))
    try {
        $stream = [IO.File]::Open($temporary, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try {
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush($true)
        }
        finally {
            $stream.Dispose()
        }
        if ($Create) {
            [IO.File]::Move($temporary, $Path)
        }
        else {
            [IO.File]::Replace($temporary, $Path, [NullString]::Value)
        }
    }
    finally {
        if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}

function Read-BigZJournal {
    param([string]$Path, [string]$TargetId)

    $journal = Read-BigZJson $Path
    Assert-BigZObjectShape $journal @('FormatVersion', 'TargetId', 'Edition', 'Intent', 'Entries', 'UpdatedAtUtc') -Label 'diário'
    if (-not (Test-BigZInteger $journal.FormatVersion) -or $journal.FormatVersion -ne 1 -or
        $journal.TargetId -cne $TargetId -or $journal.Edition -cnotin $script:BigZEditions -or
        $journal.Intent -cnotin @('apply', 'revert') -or $journal.Entries -isnot [array]) {
        throw 'Versão, alvo ou formato do diário incompatível.'
    }

    $ids = @{}
    $targets = @{}
    foreach ($entry in $journal.Entries) {
        Assert-BigZObjectShape $entry @('Id', 'Action', 'Before', 'Status') -Label 'item do diário'
        Assert-BigZId $entry.Id 'ID do diário'
        Assert-BigZRegistryAction $entry.Action "ação do diário '$($entry.Id)'"
        Assert-BigZSnapshot $entry.Before
        $target = "$($entry.Action.key)|$($entry.Action.name)"
        if ($ids.ContainsKey($entry.Id) -or $targets.ContainsKey($target) -or
            $entry.Status -cnotin @('Pending', 'Prepared', 'Applied', 'NoChange', 'Reverting', 'Reverted') -or
            ($journal.Intent -ceq 'apply' -and $entry.Status -cin @('Reverting', 'Reverted'))) {
            throw "Item inválido no diário: '$($entry.Id)'."
        }
        $ids[$entry.Id] = $true
        $targets[$target] = $true
    }
    return $journal
}

function Get-BigZInitialJournal {
    param($Plan, [string]$TargetId)

    $entries = foreach ($item in $Plan.Items) {
        $status = 'Pending'
        if ($item.Status -ceq 'AlreadyDesired') { $status = 'NoChange' }
        [pscustomobject]@{ Id = $item.Id; Action = $item.Action; Before = $item.Current; Status = $status }
    }
    return [pscustomobject]@{
        FormatVersion = 1
        TargetId = $TargetId
        Edition = $Plan.Edition
        Intent = 'apply'
        Entries = @($entries)
        UpdatedAtUtc = ''
    }
}

function Assert-BigZJournalMatchesPlan {
    param($Journal, $Plan)

    if ($Journal.Intent -cne 'apply' -or $Journal.Edition -cne $Plan.Edition -or
        $Journal.Entries.Count -ne $Plan.Items.Count) {
        throw 'O diário não corresponde ao plano atual. Use um diário novo para outro plano.'
    }
    for ($index = 0; $index -lt $Plan.Items.Count; $index++) {
        $entry = $Journal.Entries[$index]
        $item = $Plan.Items[$index]
        if ($entry.Id -cne $item.Id -or $entry.Action.key -ine $item.Action.key -or
            $entry.Action.name -ine $item.Action.name -or $entry.Action.value -ne $item.Action.value) {
            throw 'O plano mudou desde a criação do diário.'
        }
    }
}

function Enter-BigZTargetLock {
    param([string]$TargetId)

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($TargetId)
        $hash = [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
    $mutex = [Threading.Mutex]::new($false, "Global\BigZ.Tweaks.$hash")
    $acquired = $false
    try {
        try {
            $acquired = $mutex.WaitOne(0)
        }
        catch [Threading.AbandonedMutexException] {
            $acquired = $true
        }
        if (-not $acquired) { throw 'Já existe uma operação BigZ no mesmo alvo.' }
        return $mutex
    }
    finally {
        if (-not $acquired) { $mutex.Dispose() }
    }
}

function Exit-BigZTargetLock {
    param([Threading.Mutex]$Mutex)

    try {
        $Mutex.ReleaseMutex()
    }
    finally {
        $Mutex.Dispose()
    }
}
