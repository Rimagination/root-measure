param(
  [string]$RootMeasureRoot = '',
  [string]$ExpectedRvSha256 = '666021070EC31B6599086D35CB8E6EACB7416B85A2CBAA032BCFBDCAB90080D4',
  [string]$ExpectedCvutilSha256 = 'AB6E1BEAAD64DDC02FCA9CF1952F7B5A526FEE702B33E4A2BACCAD30086AA39B',
  [switch]$IncludeHelp
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

function New-Check {
  param(
    [string]$Name,
    [bool]$Pass,
    [string]$Message,
    [AllowNull()]$Actual = $null,
    [AllowNull()]$Expected = $null
  )

  [pscustomobject][ordered]@{
    name = $Name
    pass = $Pass
    message = $Message
    actual = $Actual
    expected = $Expected
  }
}

$checks = @()
$root = & (Join-Path $PSScriptRoot 'Resolve-RootMeasureRoot.ps1') -RootMeasureRoot $RootMeasureRoot
$rv = Join-Path $root 'tools\rve-toolchain\rv.exe'
$cvutil = Join-Path $root 'tools\rve-toolchain\cvutil.dll'
$transparentWrapper = Join-Path $root 'scripts\Invoke-RootMeasure.ps1'
$rawWrapper = Join-Path $root 'scripts\Invoke-Rv.ps1'
$cmdWrapper = Join-Path $root 'scripts\rv.cmd'
$profileScript = Join-Path $PSScriptRoot 'reproducibility-profile.ps1'
$prefixDir = Join-Path $root '$prefix'
$installDir = Join-Path $root '$install'

$checks += New-Check 'root_measure_root' (Test-Path -LiteralPath $root) 'Root Measure project root exists.' $root $null
$checks += New-Check 'rv_exists' (Test-Path -LiteralPath $rv) 'rv.exe exists.' $rv $null

$rvHash = $null
$version = @()
if (Test-Path -LiteralPath $rv) {
  $rvHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $rv).Hash
  $version = @(& $rv --version 2>&1 | ForEach-Object { [string]$_ })
}
$checks += New-Check 'rv_sha256' ($rvHash -eq $ExpectedRvSha256) 'rv.exe hash matches the validated toolchain.' $rvHash $ExpectedRvSha256
$checks += New-Check 'cvutil_exists' (Test-Path -LiteralPath $cvutil) 'cvutil.dll exists.' $cvutil $null

$cvutilHash = $null
if (Test-Path -LiteralPath $cvutil) {
  $cvutilHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $cvutil).Hash
}
$checks += New-Check 'cvutil_sha256' ($cvutilHash -eq $ExpectedCvutilSha256) 'cvutil.dll hash matches the validated toolchain.' $cvutilHash $ExpectedCvutilSha256
$checks += New-Check 'transparent_wrapper' (Test-Path -LiteralPath $transparentWrapper) 'Transparent measurement wrapper exists.' $transparentWrapper $null
$checks += New-Check 'raw_powershell_wrapper' (Test-Path -LiteralPath $rawWrapper) 'Raw PowerShell passthrough wrapper exists.' $rawWrapper $null
$checks += New-Check 'raw_cmd_wrapper' (Test-Path -LiteralPath $cmdWrapper) 'Raw cmd passthrough wrapper exists.' $cmdWrapper $null
$checks += New-Check 'reproducibility_profile' (Test-Path -LiteralPath $profileScript) 'Codified reproducibility profile exists.' $profileScript $null
$checks += New-Check 'no_literal_prefix_install_dir' (-not (Test-Path -LiteralPath $prefixDir)) 'No suspicious literal $prefix install directory at project root.' $prefixDir $null
$checks += New-Check 'no_literal_install_dir' (-not (Test-Path -LiteralPath $installDir)) 'No suspicious literal $install install directory at project root.' $installDir $null

$rawPassthroughVersion = @()
if (Test-Path -LiteralPath $rawWrapper) {
  $rawPassthroughVersion = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $rawWrapper --version 2>&1 | ForEach-Object { [string]$_ })
}
$checks += New-Check 'raw_passthrough_version' ($rawPassthroughVersion -join "`n" -match 'RhizoVision Explorer CLI') 'Raw passthrough can forward --version to rv.exe.' ($rawPassthroughVersion -join "`n") 'RhizoVision Explorer CLI'

$help = @()
if ($IncludeHelp.IsPresent -and (Test-Path -LiteralPath $rv)) {
  $help = @(& $rv --help 2>&1 | ForEach-Object { [string]$_ })
}

$failed = @($checks | Where-Object { -not $_.pass })
$status = if ($failed.Count -eq 0) { 'pass' } else { 'fail' }

[ordered]@{
  status = $status
  root_measure_root = $root
  reproducibility_contract = [ordered]@{
    toolchain = 'Validated public-data reproduction requires the same rv.exe and cvutil.dll hashes unless the user intentionally accepts a new comparison baseline.'
    parameters = 'Use explicit rv.exe arguments, preset settings, scale, threshold, filtering, pruning, and diameter ranges. Do not rely on implicit defaults when comparing to public expected CSVs.'
    expected_csv = 'Compare generated features.csv to the public expected CSV with compare-features.ps1; arbitrary user runs are not claimed official-equivalent until compared.'
    pitfalls = 'Use reproducibility-profile.ps1 for known validation-history pitfalls before guiding public-data reproduction.'
  }
  rv = [ordered]@{
    path = $rv
    sha256 = $rvHash
    expected_sha256 = $ExpectedRvSha256
    version_output = $version
  }
  cvutil = [ordered]@{
    path = $cvutil
    sha256 = $cvutilHash
    expected_sha256 = $ExpectedCvutilSha256
  }
  wrappers = [ordered]@{
    transparent_measure = $transparentWrapper
    raw_powershell = $rawWrapper
    raw_cmd = $cmdWrapper
  }
  profile = [ordered]@{
    script = $profileScript
    gotchas_doc = Join-Path (Split-Path -Parent $PSScriptRoot) 'docs\reproducibility-gotchas.md'
  }
  high_risk_pitfalls = @(
    'Smoke tests are not numeric oracles.',
    'Do not rely on --metafile; translate metadata/settings to explicit CLI flags.',
    'Do not silently assume DPI.',
    'Duplicate expected File.Name rows require duplicate-aware comparison.',
    'Use Explorer-origin expected CSVs for Explorer validation; Analyzer/Crown tables are not Explorer oracles.'
  )
  checks = @($checks)
  help = $help
} | ConvertTo-Json -Depth 8

if ($status -ne 'pass') {
  exit 1
}
