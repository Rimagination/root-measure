param()

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script = Join-Path $repoRoot 'scripts\list-runs.ps1'
$sandbox = Join-Path $repoRoot '.tmp\test-list-runs-path'
$inputDir = Join-Path $sandbox 'input-folder'
$resultsDir = Join-Path $inputDir 'root-measure-results'
$runDir = Join-Path $resultsDir 'root-measure-20260429-140000'

New-Item -ItemType Directory -Force -Path $runDir | Out-Null
@"
File.Name,Total.Root.Length.mm
scan1.png,123.4
"@ | Set-Content -LiteralPath (Join-Path $runDir 'features.csv') -Encoding UTF8
@'
{"status":"success","preset":"broken-roots-exact","finished_at":"2026-04-29T14:00:00+08:00"}
'@ | Set-Content -LiteralPath (Join-Path $runDir 'run_manifest.json') -Encoding UTF8

$result = & powershell -NoProfile -ExecutionPolicy Bypass -File $script -SearchPath $inputDir -Limit 5 | ConvertFrom-Json

if ($result.runs_root -ne $resultsDir) {
  Write-Error "Expected runs_root '$resultsDir' but got '$($result.runs_root)'."
}
if ($result.count -lt 1) {
  Write-Error 'Expected at least one run entry.'
}
if ($result.runs[0].path -ne $runDir) {
  Write-Error "Expected first run path '$runDir' but got '$($result.runs[0].path)'."
}

Write-Host 'PASS: runs --path resolves adjacent root-measure-results.'
