$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Keep this script free of PowerShell parameters so every rv.exe option,
# including short flags like -r, is forwarded without script-level binding.
$rootOverride = if ($env:ROOT_MEASURE_ROOT) { $env:ROOT_MEASURE_ROOT } else { '' }
$root = & (Join-Path $PSScriptRoot 'Resolve-RootMeasureRoot.ps1') -RootMeasureRoot $rootOverride
$wrapper = Join-Path $root 'scripts\Invoke-Rv.ps1'
$arguments = @($args)

if (-not (Test-Path -LiteralPath $wrapper)) {
  throw "Invoke-Rv.ps1 not found: $wrapper"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $wrapper @arguments
exit $LASTEXITCODE

