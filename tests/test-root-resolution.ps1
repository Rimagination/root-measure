param()

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$resolver = Join-Path $repoRoot 'scripts\Resolve-RootMeasureRoot.ps1'
$resolved = & powershell -NoProfile -ExecutionPolicy Bypass -File $resolver
$resolved = ($resolved | Out-String).Trim()

if ($resolved -ne $repoRoot) {
  Write-Error "Expected default root '$repoRoot' but got '$resolved'."
}

Write-Host 'PASS: default root resolves to plugin repository.'
