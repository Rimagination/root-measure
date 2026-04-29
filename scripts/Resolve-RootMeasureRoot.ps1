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
(Resolve-Path -LiteralPath $pluginRoot).Path

