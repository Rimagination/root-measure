param(
  [string]$RootMeasureRoot = ''
)

$ErrorActionPreference = 'Stop'

if (-not [string]::IsNullOrWhiteSpace($RootMeasureRoot)) {
  $resolved = (Resolve-Path -LiteralPath $RootMeasureRoot).Path
  if (-not (Test-Path -LiteralPath (Join-Path $resolved 'scripts\Invoke-RootMeasure.ps1'))) {
    throw "Not a Root Measure project root: $resolved"
  }
  $resolved
  return
}

if (-not [string]::IsNullOrWhiteSpace($env:ROOT_MEASURE_ROOT)) {
  $resolved = (Resolve-Path -LiteralPath $env:ROOT_MEASURE_ROOT).Path
  if (-not (Test-Path -LiteralPath (Join-Path $resolved 'scripts\Invoke-RootMeasure.ps1'))) {
    throw "Not a Root Measure project root: $resolved"
  }
  $resolved
  return
}

$pluginRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$searchRoots = New-Object System.Collections.Generic.List[string]
$current = [System.IO.DirectoryInfo]::new($pluginRoot)
while ($null -ne $current) {
  $searchRoots.Add($current.FullName) | Out-Null
  $current = $current.Parent
}

foreach ($root in $searchRoots) {
  $candidate = Join-Path $root 'root-measure'
  if (Test-Path -LiteralPath (Join-Path $candidate 'scripts\Invoke-RootMeasure.ps1')) {
    (Resolve-Path -LiteralPath $candidate).Path
    return
  }
}

foreach ($root in $searchRoots) {
  $matches = @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | Where-Object {
      Test-Path -LiteralPath (Join-Path $_.FullName 'scripts\Invoke-RootMeasure.ps1')
    } | Select-Object -First 1)
  if ($matches.Count -gt 0) {
    $matches[0].FullName
    return
  }
}

throw "Could not locate Root Measure project from plugin root: $pluginRoot"

