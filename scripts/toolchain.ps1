param(
  [string]$RootMeasureRoot = '',
  [switch]$IncludeHelp
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$root = & (Join-Path $PSScriptRoot 'Resolve-RootMeasureRoot.ps1') -RootMeasureRoot $RootMeasureRoot
$rv = Join-Path $root 'tools\rve-toolchain\rv.exe'
$cvutil = Join-Path $root 'tools\rve-toolchain\cvutil.dll'

if (-not (Test-Path -LiteralPath $rv)) {
  throw "rv.exe not found: $rv"
}

$version = @(& $rv --version 2>&1 | ForEach-Object { [string]$_ })
$help = @()
if ($IncludeHelp.IsPresent) {
  $help = @(& $rv --help 2>&1 | ForEach-Object { [string]$_ })
}

[ordered]@{
  root_measure_root = $root
  rv = [ordered]@{
    path = $rv
    sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $rv).Hash
    version_output = $version
  }
  cvutil = [ordered]@{
    path = $cvutil
    exists = Test-Path -LiteralPath $cvutil
    sha256 = if (Test-Path -LiteralPath $cvutil) { (Get-FileHash -Algorithm SHA256 -LiteralPath $cvutil).Hash } else { $null }
  }
  wrappers = [ordered]@{
    transparent_measure = Join-Path $root 'scripts\Invoke-RootMeasure.ps1'
    raw_powershell = Join-Path $root 'scripts\Invoke-Rv.ps1'
    raw_cmd = Join-Path $root 'scripts\rv.cmd'
  }
  help = $help
} | ConvertTo-Json -Depth 8
