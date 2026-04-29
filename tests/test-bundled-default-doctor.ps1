param()

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$cli = Join-Path $repoRoot 'bin\root-measure.cmd'

$output = @(& $cli doctor 2>&1 | ForEach-Object { [string]$_ })
$exitCode = $LASTEXITCODE
$text = ($output -join "`n")

if ($exitCode -ne 0) {
  Write-Error "Expected bundled default doctor to pass, but exit code was $exitCode.`n$text"
}

$json = $null
try {
  $json = $text | ConvertFrom-Json
} catch {
  Write-Error "Doctor output was not valid JSON.`n$text"
}

if ($json.status -ne 'pass') {
  Write-Error "Expected doctor status 'pass' but got '$($json.status)'."
}

if (-not $json.rv -or -not $json.rv.sha256) {
  Write-Error 'Expected bundled doctor output to include rv.exe hash.'
}

if (-not $json.cvutil -or -not $json.cvutil.sha256) {
  Write-Error 'Expected bundled doctor output to include cvutil.dll hash.'
}

Write-Host 'PASS: bundled default doctor succeeds without root override.'
