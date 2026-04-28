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

$workspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$candidate = Join-Path $workspaceRoot 'root-measure'
if (Test-Path -LiteralPath (Join-Path $candidate 'scripts\Invoke-RootMeasure.ps1')) {
  (Resolve-Path -LiteralPath $candidate).Path
  return
}

$matches = @(Get-ChildItem -LiteralPath $workspaceRoot -Directory -ErrorAction SilentlyContinue | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName 'scripts\Invoke-RootMeasure.ps1')
  } | Select-Object -First 1)
if ($matches.Count -gt 0) {
  $matches[0].FullName
  return
}

throw "Could not locate Root Measure project under: $workspaceRoot"
