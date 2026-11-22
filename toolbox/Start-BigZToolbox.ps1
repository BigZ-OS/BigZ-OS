#Requires -Version 5.1
[CmdletBinding(DefaultParameterSetName = 'Gui')]
param(
    [ValidateSet('dev', 'balanced', 'full-performance')]
    [string]$Edition = 'balanced',

    [Parameter(Mandatory, ParameterSetName = 'Plan')]
    [switch]$Plan,

    [Parameter(ParameterSetName = 'Plan')]
    [AllowEmptyCollection()]
    [string[]]$Id,

    [Parameter(Mandatory, ParameterSetName = 'UiCheck')]
    [switch]$CheckUi
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'modules/BigZ.Toolbox.Plan.ps1')
$script:catalog = Read-BigZCatalog (Split-Path $PSScriptRoot -Parent)

if ($Plan) {
    if (-not $PSBoundParameters.ContainsKey('Id')) {
        $Id = @(Get-BigZDefaultId $script:catalog $Edition)
    }
    Get-BigZToolboxPlan $script:catalog $Edition $Id
    return
}

if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    throw 'Abra a Toolbox com powershell.exe -STA para carregar a interface WPF.'
}

Add-Type -AssemblyName PresentationFramework
$reader = [System.Xml.XmlReader]::Create((Join-Path $PSScriptRoot 'Toolbox.xaml'))
try {
    $window = [Windows.Markup.XamlReader]::Load($reader)
} finally {
    $reader.Dispose()
}

$script:ui = @{}
foreach ($name in 'DevRadio', 'BalancedRadio', 'FullRadio', 'Navigation', 'CatalogGrid', 'PlanText', 'PlanButton', 'UndoButton') {
    $script:ui[$name] = $window.FindName($name)
}
$script:editionNow = $Edition
$script:editionRows = @{}
$script:lastPlan = $null
$script:riskLabels = @{ low = 'Baixo'; medium = 'Médio'; high = 'Alto' }
$script:riskColors = @{ low = '#86EFAC'; medium = '#FDE68A'; high = '#FCA5A5' }

function Get-BigZEditionView {
    if (-not $script:editionRows.ContainsKey($script:editionNow)) {
        $defaults = @(Get-BigZDefaultId $script:catalog $script:editionNow)
        $byKind = @{}
        foreach ($kind in $script:catalog.Lists.Keys) {
            $byKind[$kind] = @(
                foreach ($entry in $script:catalog.Lists[$kind]) {
                    if ($script:editionNow -notin $entry.editions) { continue }
                    $name = if ($kind -eq 'tweak') { $entry.description } else { $entry.name }
                    [pscustomobject]@{
                        Id = $entry.id
                        Selected = $entry.id -in $defaults
                        Name = $name
                        Risk = $script:riskLabels[$entry.risk]
                        RiskBrush = $script:riskColors[$entry.risk]
                    }
                }
            )
        }
        $script:editionRows[$script:editionNow] = $byKind
    }
    $script:editionRows[$script:editionNow]
}

function Show-BigZCatalogSection {
    $section = $script:ui.Navigation.SelectedItem.Tag
    if ($section) {
        $rows = Get-BigZEditionView
        $script:ui.CatalogGrid.ItemsSource = $rows[$section]
    }
}

function Show-BigZPlan {
    param($CurrentPlan)

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("$($CurrentPlan.Edition) · $($CurrentPlan.Engine)")
    $lines.Add("$($CurrentPlan.Items.Count) item(ns) no plano de simulação.")
    foreach ($item in $CurrentPlan.Items) {
        $risk = $script:riskLabels[$item.Risk]
        $dependency = if ($item.Dependency) { ' · dependência' } else { '' }
        $lines.Add('')
        $lines.Add("[$risk$dependency] $($item.Name)")
        $lines.Add($item.Details)
    }
    foreach ($diagnostic in $CurrentPlan.Diagnostics) {
        $lines.Add('')
        $lines.Add($diagnostic)
    }
    $script:ui.PlanText.Text = $lines -join [Environment]::NewLine
}

$script:ui.Navigation.Add_SelectionChanged({ Show-BigZCatalogSection })
foreach ($name in 'DevRadio', 'BalancedRadio', 'FullRadio') {
    $script:ui[$name].Add_Checked({
        param($sourceControl)
        $script:editionNow = [string]$sourceControl.Tag
        $script:lastPlan = $null
        $script:ui.UndoButton.IsEnabled = $false
        $script:ui.PlanText.Text = 'Marque os itens e selecione Ver plano.'
        Show-BigZCatalogSection
    })
    if ($script:ui[$name].Tag -eq $Edition) { $script:ui[$name].IsChecked = $true }
}
$script:ui.Navigation.SelectedIndex = 0
$script:ui.PlanButton.Add_Click({
    try {
        $rows = Get-BigZEditionView
        $selected = @(foreach ($kind in 'app', 'tweak', 'preset') {
            $rows[$kind] | Where-Object { $_.Selected } | ForEach-Object { $_.Id }
        })
        $script:lastPlan = Get-BigZToolboxPlan $script:catalog $script:editionNow $selected
        $script:ui.UndoButton.IsEnabled = $script:lastPlan.Items.Count -gt 0
        Show-BigZPlan $script:lastPlan
    } catch {
        $script:lastPlan = $null
        $script:ui.UndoButton.IsEnabled = $false
        $script:ui.PlanText.Text = "Não foi possível gerar o plano: $($_.Exception.Message)"
    }
})
$script:ui.UndoButton.Add_Click({
    $lines = @('Reversão simulada. Nenhuma alteração foi aplicada nesta sessão.', '')
    foreach ($step in (Get-BigZToolboxUndoPlan $script:lastPlan)) {
        $lines += "$($step.Name): $($step.Details)"
    }
    $script:ui.PlanText.Text = $lines -join [Environment]::NewLine
})

if ($CheckUi) {
    $script:ui.DevRadio.IsChecked = $true
    if ($script:ui.CatalogGrid.Items.Count -lt 3) { throw 'A lista de apps DEV não foi carregada.' }
    $script:ui.Navigation.SelectedIndex = 1
    $firstTweak = $script:ui.CatalogGrid.Items[0]
    $firstTweak.Selected = $true
    $script:ui.PlanButton.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
    if (-not $script:ui.UndoButton.IsEnabled -or $script:ui.PlanText.Text -notlike "*$($firstTweak.Name)*") {
        throw $script:ui.PlanText.Text
    }
    $script:ui.UndoButton.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
    if ($script:ui.PlanText.Text -notlike 'Reversão simulada*') { throw 'O botão Desfazer não exibiu a simulação.' }
    $script:ui.FullRadio.IsChecked = $true
    $script:ui.Navigation.SelectedIndex = 2
    if ($script:ui.CatalogGrid.Items.Count -ne 3 -or $script:ui.UndoButton.IsEnabled) {
        throw 'A troca de edição ou de seção não atualizou a interface.'
    }
    $window.Measure([Windows.Size]::new(1110, 710))
    $window.Arrange([Windows.Rect]::new(0, 0, 1110, 710))
    'OK: WPF, edições, seções, plano e desfazer em simulação.'
    return
}

[void]$window.ShowDialog()
