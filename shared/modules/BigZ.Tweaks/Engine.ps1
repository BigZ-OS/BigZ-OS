function Resolve-BigZPlan {
    param([hashtable]$Catalog, [string[]]$Id, [string]$Edition, [string]$Phase, $Adapter, [switch]$DeclarationOnly)

    $edition = $Edition.ToLowerInvariant()
    $phase = $Phase.ToLowerInvariant()
    $marks = @{}
    $order = [Collections.Generic.List[string]]::new()
    $diagnostics = [Collections.Generic.List[object]]::new()

    foreach ($requested in $Id) {
        Assert-BigZId $requested 'ID solicitado'
        if (-not $Catalog.ContainsKey($requested)) { throw "Tweak desconhecido '$requested'." }
        Add-BigZTweakOrder $requested $Catalog $marks $order
    }

    if (-not $DeclarationOnly) {
        if ($phase -cne 'online') { throw 'A fase offline admite apenas -DeclarationOnly.' }
        if ($null -eq $Adapter) { $Adapter = Get-BigZNativeAdapter }
        Assert-BigZAdapter $Adapter
    }

    $acceptedBuilds = @(26200)
    if ($phase -ceq 'offline') { $acceptedBuilds += 26300 }
    $targets = @{}
    $items = foreach ($tweakId in $order) {
        $tweak = $Catalog[$tweakId]
        $current = $null
        $desired = $null
        $status = 'Declared'
        $problems = @(
            if ($tweak.phase -cne $phase) { 'Fase incompatível.' }
            if ($edition -cnotin $tweak.editions) { 'Edição BigZ incompatível.' }
            if (-not @($tweak.requires.builds | Where-Object { $_ -in $acceptedBuilds }).Count) { 'Build fora da matriz v0.' }
            if ($tweak.risk -ceq 'high') { 'Risco alto bloqueado pela política v0.' }
            if ($tweak.securityImpact -cne 'none') { 'Redução de proteção bloqueada pela política v0.' }
            foreach ($conflict in $tweak.conflictsWith) {
                if ($marks.ContainsKey($conflict)) { "Conflito com '$conflict'." }
            }
        )

        if ($tweak.action.type -ceq 'registry.setValue') {
            $target = "$($tweak.action.key)|$($tweak.action.name)"
            $desired = Get-BigZDesiredState $tweak.action
        }
        elseif ($tweak.action.type -ceq 'registry.setOfflineValue') {
            $target = "$($tweak.action.hive)|$($tweak.action.key)|$($tweak.action.name)"
        }
        else {
            $target = $tweak.action.packageName
        }
        if ($targets.ContainsKey($target)) { $problems += "Alvo já selecionado por '$($targets[$target])'." }
        $targets[$target] = $tweakId

        if ($problems.Count -eq 0 -and -not $DeclarationOnly) {
            try {
                $current = & $Adapter.ReadState $tweak.action
                Assert-BigZSnapshot $current
                $status = 'NeedsChange'
                if (Test-BigZSameState $current $desired) { $status = 'AlreadyDesired' }
            }
            catch {
                $problems += $_.Exception.Message
            }
        }
        if ($problems.Count -gt 0) {
            $status = 'Blocked'
            foreach ($problem in $problems) {
                $diagnostics.Add([pscustomobject]@{ Id = $tweakId; Message = $problem })
            }
        }

        [pscustomobject]@{
            Id = $tweakId
            Description = $tweak.description
            Phase = $tweak.phase
            Scope = $tweak.scope
            Risk = $tweak.risk
            SecurityImpact = $tweak.securityImpact
            Source = $tweak.source
            Restart = $tweak.restart
            Requires = $tweak.requires
            Action = $tweak.action
            Verify = $tweak.verify
            Rollback = $tweak.rollback
            Current = $current
            Desired = $desired
            Status = $status
        }
    }

    return [pscustomobject]@{
        Edition = $edition
        Phase = $phase
        DeclarationOnly = [bool]$DeclarationOnly
        IsValid = $diagnostics.Count -eq 0
        CanApply = -not $DeclarationOnly -and $diagnostics.Count -eq 0 -and $order.Count -gt 0
        Items = @($items)
        Diagnostics = $diagnostics.ToArray()
    }
}

function Get-BigZTweakPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CatalogPath,
        [AllowEmptyCollection()][string[]]$Id = @(),
        [Parameter(Mandatory)][ValidateSet('dev', 'balanced', 'full-performance')][string]$Edition,
        [ValidateSet('online', 'offline')][string]$Phase = 'online',
        [switch]$DeclarationOnly,
        [psobject]$Adapter
    )

    $catalog = Read-BigZTweakCatalog $CatalogPath
    Resolve-BigZPlan $catalog $Id $Edition $Phase $Adapter -DeclarationOnly:$DeclarationOnly
}

function Test-BigZTweak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CatalogPath,
        [Parameter(Mandatory)][string[]]$Id,
        [Parameter(Mandatory)][ValidateSet('dev', 'balanced', 'full-performance')][string]$Edition,
        [psobject]$Adapter
    )

    $plan = Get-BigZTweakPlan -CatalogPath $CatalogPath -Id $Id -Edition $Edition -Adapter $Adapter
    return [pscustomobject]@{
        Satisfied = $plan.IsValid -and @($plan.Items | Where-Object Status -ne 'AlreadyDesired').Count -eq 0
        Items = $plan.Items
        Diagnostics = $plan.Diagnostics
    }
}

function Invoke-BigZJournalEntry {
    param($Entry, $Journal, [string]$Path, $Adapter)

    $current = & $Adapter.ReadState $Entry.Action
    $desired = Get-BigZDesiredState $Entry.Action
    $atDesired = Test-BigZSameState $current $desired
    $atOriginal = Test-BigZSameState $current $Entry.Before

    if ($Entry.Status -cin @('NoChange', 'Applied')) {
        if (-not $atDesired) { throw "Estado mudou após aplicar '$($Entry.Id)'." }
        return
    }

    if ($Entry.Status -ceq 'Pending') {
        if (-not $atOriginal) { throw "Estado mudou antes de aplicar '$($Entry.Id)'." }
        $Entry.Status = 'Prepared'
        Save-BigZJournal $Path $Journal
    }
    elseif ($atDesired) {
        # An interrupted operation may have written the value before marking it applied.
        $Entry.Status = 'Applied'
        Save-BigZJournal $Path $Journal
        return
    }
    elseif (-not $atOriginal) {
        throw "O estado de '$($Entry.Id)' divergiu durante a aplicação."
    }

    if (-not (Test-BigZSameState (& $Adapter.ReadState $Entry.Action) $Entry.Before)) {
        throw "Estado mudou após preparar '$($Entry.Id)'."
    }
    $null = & $Adapter.WriteState $Entry.Action $desired
    if (-not (Test-BigZSameState (& $Adapter.ReadState $Entry.Action) $desired)) {
        throw "Verificação falhou para '$($Entry.Id)'."
    }
    $Entry.Status = 'Applied'
    Save-BigZJournal $Path $Journal
}

function Invoke-BigZTweak {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$CatalogPath,
        [Parameter(Mandatory)][string[]]$Id,
        [Parameter(Mandatory)][ValidateSet('dev', 'balanced', 'full-performance')][string]$Edition,
        [string]$JournalPath,
        [switch]$DryRun,
        [psobject]$Adapter
    )

    if ($DryRun) { return Get-BigZTweakPlan -CatalogPath $CatalogPath -Id $Id -Edition $Edition -Adapter $Adapter }
    if ($null -eq $Adapter) { $Adapter = Get-BigZNativeAdapter }
    Assert-BigZAdapter $Adapter
    if (-not $PSCmdlet.ShouldProcess($Adapter.TargetId, "Aplicar $($Id -join ', ')")) {
        return Get-BigZTweakPlan -CatalogPath $CatalogPath -Id $Id -Edition $Edition -Adapter $Adapter
    }

    $path = Get-BigZJournalPath $JournalPath
    $mutex = Enter-BigZTargetLock $Adapter.TargetId
    try {
        $plan = Get-BigZTweakPlan -CatalogPath $CatalogPath -Id $Id -Edition $Edition -Adapter $Adapter
        if (-not $plan.CanApply) {
            $messages = $plan.Diagnostics | ForEach-Object { "$($_.Id) $($_.Message)" }
            throw "Plano não aplicável. $($messages -join ' ')"
        }

        if ([IO.File]::Exists($path)) {
            $journal = Read-BigZJournal $path $Adapter.TargetId
            Assert-BigZJournalMatchesPlan $journal $plan
        }
        else {
            $journal = Get-BigZInitialJournal $plan $Adapter.TargetId
            Save-BigZJournal $path $journal -Create
        }
        foreach ($entry in $journal.Entries) {
            Invoke-BigZJournalEntry $entry $journal $path $Adapter
        }
        return [pscustomobject]@{ Succeeded = $true; JournalPath = $path; Entries = $journal.Entries }
    }
    finally {
        Exit-BigZTargetLock $mutex
    }
}

function Undo-BigZJournalEntry {
    param($Entry, $Journal, [string]$Path, $Adapter)

    if ($Entry.Status -cin @('NoChange', 'Reverted')) { return }
    if ($Entry.Status -ceq 'Pending') {
        $Entry.Status = 'Reverted'
        Save-BigZJournal $Path $Journal
        return
    }

    $current = & $Adapter.ReadState $Entry.Action
    $desired = Get-BigZDesiredState $Entry.Action
    if (Test-BigZSameState $current $Entry.Before) {
        $Entry.Status = 'Reverted'
        Save-BigZJournal $Path $Journal
        return
    }
    if (-not (Test-BigZSameState $current $desired)) {
        return [pscustomobject]@{ Id = $Entry.Id; Message = 'Estado externo divergente. O valor atual foi preservado.' }
    }

    $Entry.Status = 'Reverting'
    Save-BigZJournal $Path $Journal
    if (-not (Test-BigZSameState (& $Adapter.ReadState $Entry.Action) $desired)) {
        return [pscustomobject]@{ Id = $Entry.Id; Message = 'Estado mudou durante a reversão. O valor atual foi preservado.' }
    }
    $null = & $Adapter.WriteState $Entry.Action $Entry.Before
    if (-not (Test-BigZSameState (& $Adapter.ReadState $Entry.Action) $Entry.Before)) {
        throw "Verificação de reversão falhou para '$($Entry.Id)'."
    }
    $Entry.Status = 'Reverted'
    Save-BigZJournal $Path $Journal
}

function Undo-BigZTweak {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$JournalPath,
        [switch]$DryRun,
        [psobject]$Adapter
    )

    if ($null -eq $Adapter) { $Adapter = Get-BigZNativeAdapter }
    Assert-BigZAdapter $Adapter
    $path = Get-BigZJournalPath $JournalPath

    if ($DryRun -or -not $PSCmdlet.ShouldProcess($Adapter.TargetId, "Reverter alterações de $path")) {
        $journal = Read-BigZJournal $path $Adapter.TargetId
        $preview = foreach ($entry in $journal.Entries) {
            if ($entry.Status -cin @('Prepared', 'Applied', 'Reverting')) {
                [pscustomobject]@{ Id = $entry.Id; Restore = $entry.Before; Current = (& $Adapter.ReadState $entry.Action) }
            }
        }
        return [pscustomobject]@{ DryRun = $true; Entries = @($preview) }
    }

    $mutex = Enter-BigZTargetLock $Adapter.TargetId
    try {
        $journal = Read-BigZJournal $path $Adapter.TargetId
        if ($journal.Intent -cne 'revert') {
            $journal.Intent = 'revert'
            Save-BigZJournal $path $journal
        }
        $issues = @(
            for ($index = $journal.Entries.Count - 1; $index -ge 0; $index--) {
                Undo-BigZJournalEntry $journal.Entries[$index] $journal $path $Adapter
            }
        )
        return [pscustomobject]@{
            Succeeded = $issues.Count -eq 0
            JournalPath = $path
            Entries = $journal.Entries
            Diagnostics = $issues
        }
    }
    finally {
        Exit-BigZTargetLock $mutex
    }
}
