function Read-BigZRegistryState {
    param($Action)

    $subKey = $Action.key.Substring('HKCU\'.Length)
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($subKey, $false)
    if ($null -eq $key) {
        return [pscustomobject]@{ KeyExists = $false; Exists = $false; ValueType = $null; Value = $null }
    }
    try {
        if ($Action.name -notin $key.GetValueNames()) {
            return [pscustomobject]@{ KeyExists = $true; Exists = $false; ValueType = $null; Value = $null }
        }
        $kind = $key.GetValueKind($Action.name).ToString()
        $value = $null
        if ($kind -ceq 'DWord') { $value = $key.GetValue($Action.name) }
        return [pscustomobject]@{ KeyExists = $true; Exists = $true; ValueType = $kind; Value = $value }
    }
    finally {
        $key.Dispose()
    }
}

function Write-BigZRegistryState {
    param($Action, $State)

    Assert-BigZRegistryAction $Action 'registro atual'
    Assert-BigZSnapshot $State
    $subKey = $Action.key.Substring('HKCU\'.Length)
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($subKey, $true)
    if ($null -eq $key) { throw "Chave de registro ausente para '$($Action.name)'." }
    try {
        if ($State.Exists) {
            $key.SetValue($Action.name, [int]$State.Value, [Microsoft.Win32.RegistryValueKind]::DWord)
        }
        else {
            $key.DeleteValue($Action.name, $false)
        }
    }
    finally {
        $key.Dispose()
    }
}

function New-BigZNativeAdapter {
    $windows = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $architecture = $env:PROCESSOR_ARCHITECTURE.ToLowerInvariant()
    if ($architecture -ceq 'amd64') { $architecture = 'x64' }
    return [pscustomobject]@{
        TargetId = "hkcu:$([Environment]::MachineName):$sid"
        Context = [pscustomobject]@{
            Build = [int]$windows.CurrentBuildNumber
            Architecture = $architecture
            WindowsEdition = $windows.EditionID
        }
        ReadState = { param($action) Read-BigZRegistryState $action }
        WriteState = { param($action, $state) Write-BigZRegistryState $action $state }
    }
}

function Assert-BigZAdapter {
    param($Adapter)

    if ([string]::IsNullOrWhiteSpace($Adapter.TargetId) -or $Adapter.ReadState -isnot [scriptblock] -or
        $Adapter.WriteState -isnot [scriptblock]) {
        throw 'Adaptador de estado inválido.'
    }
    if ($Adapter.Context.Build -ne 26200 -or $Adapter.Context.Architecture -cne 'x64' -or
        $Adapter.Context.WindowsEdition -cnotin @('Core', 'Professional')) {
        throw 'Execução online limitada ao Windows 11 25H2 x64, Home ou Pro, neste marco.'
    }
}

function New-BigZDesiredState {
    param($Action)

    return [pscustomobject]@{ KeyExists = $true; Exists = $true; ValueType = 'DWord'; Value = [int]$Action.value }
}

function Assert-BigZSnapshot {
    param($State)

    Assert-BigZFields $State @('KeyExists', 'Exists', 'ValueType', 'Value') -Label 'snapshot'
    if ($State.KeyExists -isnot [bool] -or -not $State.KeyExists -or $State.Exists -isnot [bool]) {
        throw 'Snapshot exige uma chave de registro existente.'
    }
    if ($State.Exists) {
        if ($State.ValueType -cne 'DWord' -or -not (Test-BigZInteger $State.Value) -or
            $State.Value -lt [int]::MinValue -or $State.Value -gt [int]::MaxValue) {
            throw 'O snapshot de um valor existente deve preservar seu DWORD original.'
        }
    }
    elseif ($null -ne $State.ValueType -or $null -ne $State.Value) {
        throw 'Um valor ausente não pode ter dados no snapshot.'
    }
}

function Test-BigZSameState {
    param($Left, $Right)

    return $Left.KeyExists -eq $Right.KeyExists -and $Left.Exists -eq $Right.Exists -and
        $Left.ValueType -ceq $Right.ValueType -and $Left.Value -ceq $Right.Value
}
