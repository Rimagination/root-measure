$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Keep this script free of PowerShell parameters so every rv.exe option,
# including short flags like -r, is forwarded without script-level binding.
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$rootOverride = if ($env:ROOT_MEASURE_ROOT) { $env:ROOT_MEASURE_ROOT } else { '' }

if (-not [string]::IsNullOrWhiteSpace($rootOverride)) {
  $resolvedRoot = & (Join-Path $PSScriptRoot 'Resolve-RootMeasureRoot.ps1') -RootMeasureRoot $rootOverride
  if ($resolvedRoot -ne $projectRoot) {
    $externalWrapper = Join-Path $resolvedRoot 'scripts\Invoke-Rv.ps1'
    if (-not (Test-Path -LiteralPath $externalWrapper)) {
      throw "Invoke-Rv.ps1 not found in explicit Root Measure root: $externalWrapper"
    }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $externalWrapper @args
    exit $LASTEXITCODE
  }
}

$rv = Join-Path $projectRoot 'tools\rve-toolchain\rv.exe'

if (-not (Test-Path -LiteralPath $rv)) {
  throw "rv.exe is not bundled in this plugin checkout: $rv. Use --root-measure-root or ROOT_MEASURE_ROOT to point at a full backend root, or install a bundled release."
}

& $rv @args
exit $LASTEXITCODE
