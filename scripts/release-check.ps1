param(
  [string]$RootMeasureRoot = '',
  [switch]$SkipSmoke
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$pluginRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$workspaceRoot = (Resolve-Path (Join-Path $pluginRoot '..\..')).Path
$rootCli = Join-Path $PSScriptRoot 'root-measure.ps1'
$checks = New-Object System.Collections.Generic.List[object]
$artifacts = [ordered]@{}

function New-Check {
  param(
    [string]$Name,
    [bool]$Pass,
    [string]$Message,
    [AllowNull()]$Actual = $null
  )
  [pscustomobject][ordered]@{
    name = $Name
    pass = $Pass
    message = $Message
    actual = $Actual
  }
}

function Add-Check {
  param(
    [string]$Name,
    [bool]$Pass,
    [string]$Message,
    [AllowNull()]$Actual = $null
  )
  $checks.Add((New-Check $Name $Pass $Message $Actual)) | Out-Null
}

function Invoke-RootMeasure {
  param([string[]]$Arguments)
  if (-not [string]::IsNullOrWhiteSpace($RootMeasureRoot)) {
    $Arguments += @('--root-measure-root', $RootMeasureRoot)
  }

  $oldArgs = $env:ROOT_MEASURE_CLI_ARGS
  try {
    $env:ROOT_MEASURE_CLI_ARGS = ($Arguments | ForEach-Object {
        $text = [string]$_
        if ($text -match '\s' -or $text -eq '') {
          '"' + ($text -replace '"', '\"') + '"'
        } else {
          $text
        }
      }) -join ' '
    $output = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $rootCli 2>&1 | ForEach-Object { [string]$_ })
    [pscustomobject]@{
      exit_code = $LASTEXITCODE
      output = $output
      text = ($output -join "`n")
    }
  } finally {
    if ($null -eq $oldArgs) {
      Remove-Item Env:\ROOT_MEASURE_CLI_ARGS -ErrorAction SilentlyContinue
    } else {
      $env:ROOT_MEASURE_CLI_ARGS = $oldArgs
    }
  }
}

function Convert-JsonFromText {
  param([string]$Text)
  try {
    return ($Text | ConvertFrom-Json)
  } catch {
    return $null
  }
}

try {
  $manifestPath = Join-Path $pluginRoot '.codex-plugin\plugin.json'
  $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
  Add-Check 'plugin_manifest' ($manifest.name -eq 'root-measure' -and -not [string]::IsNullOrWhiteSpace($manifest.version)) 'plugin.json parses and has identity/version.' $manifest.version
} catch {
  Add-Check 'plugin_manifest' $false 'plugin.json could not be parsed.' $_.Exception.Message
}

$marketplacePath = Join-Path $workspaceRoot '.agents\plugins\marketplace.json'
try {
  $marketplace = Get-Content -Raw -Encoding UTF8 -LiteralPath $marketplacePath | ConvertFrom-Json
  $entry = @($marketplace.plugins | Where-Object { $_.name -eq 'root-measure' })
  Add-Check 'marketplace_entry' ($entry.Count -eq 1 -and $entry[0].policy.installation -eq 'AVAILABLE') 'Marketplace contains an available root-measure entry.' ($entry | ConvertTo-Json -Depth 4)
} catch {
  Add-Check 'marketplace_entry' $false 'Marketplace entry could not be checked.' $_.Exception.Message
}

Add-Check 'bin_entry' (Test-Path -LiteralPath (Join-Path $pluginRoot 'bin\root-measure.cmd')) 'User-facing root-measure.cmd exists.' (Join-Path $pluginRoot 'bin\root-measure.cmd')
Add-Check 'front_door_script' (Test-Path -LiteralPath $rootCli) 'User-facing root-measure.ps1 exists.' $rootCli
Add-Check 'wizard_script' (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'start-analysis.ps1')) 'Interactive wizard script exists.' (Join-Path $PSScriptRoot 'start-analysis.ps1')

$scriptErrors = @()
foreach ($script in @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1' -File | Sort-Object Name)) {
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) {
    $scriptErrors += [pscustomobject]@{
      script = $script.Name
      error = $errors[0].Message
    }
  }
}
Add-Check 'powershell_syntax' ($scriptErrors.Count -eq 0) 'All plugin PowerShell scripts parse without syntax errors.' $scriptErrors

$doctor = Invoke-RootMeasure @('doctor')
$doctorJson = Convert-JsonFromText $doctor.text
Add-Check 'doctor' ($doctor.exit_code -eq 0 -and $doctorJson -and $doctorJson.status -eq 'pass') 'Toolchain doctor passes.' ([ordered]@{
    status = if ($doctorJson) { $doctorJson.status } else { $null }
    rv_sha256 = if ($doctorJson -and $doctorJson.rv) { $doctorJson.rv.sha256 } else { $null }
    cvutil_sha256 = if ($doctorJson -and $doctorJson.cvutil) { $doctorJson.cvutil.sha256 } else { $null }
  })

$rawVersion = Invoke-RootMeasure @('raw', '--', '--version')
Add-Check 'raw_passthrough' ($rawVersion.exit_code -eq 0 -and $rawVersion.text -match 'RhizoVision Explorer CLI') 'Unified CLI forwards raw rv.exe arguments.' $rawVersion.text

$profile = Invoke-RootMeasure @('profile')
$profileJson = Convert-JsonFromText $profile.text
$pitfallCount = if ($profileJson) { @($profileJson.pitfalls).Count } else { 0 }
$evidenceCount = if ($profileJson) { @($profileJson.exact_validation_evidence).Count } else { 0 }
Add-Check 'reproducibility_profile' ($profile.exit_code -eq 0 -and $pitfallCount -ge 10 -and $evidenceCount -ge 4) 'Reproducibility profile exposes pitfalls and exact validation evidence.' ([ordered]@{ pitfalls = $pitfallCount; exact_validation_evidence = $evidenceCount })

if (-not $SkipSmoke.IsPresent) {
  $root = & (Join-Path $PSScriptRoot 'Resolve-RootMeasureRoot.ps1') -RootMeasureRoot $RootMeasureRoot
  $scanCandidates = @(
    (Join-Path $root 'validation-data\rhizovision-explorer-github-imageexamples\scans'),
    (Join-Path $root 'tools\rve-toolchain\imageexamples\scans'),
    (Join-Path $root 'tools\RhizoVisionExplorer-2.0.3-windows-x64\imageexamples\scans')
  )
  $scanPath = @($scanCandidates | Where-Object { Test-Path -LiteralPath (Join-Path $_ 'scan1.jpg') } | Select-Object -First 1)
  if ($scanPath.Count -eq 0) {
    Add-Check 'scan_smoke' $false 'Could not find GitHub scan smoke images.' $scanCandidates
  } else {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $out = Join-Path $root "runs\root-measure-release-check-$stamp"
    $measure = Invoke-RootMeasure @('measure', '--input', $scanPath[0], '--output', $out, '--preset', 'broken-roots', '--dpi', '600')
    $artifacts['smoke_run'] = $out
    Add-Check 'scan_smoke_measure' ($measure.exit_code -eq 0) 'Unified CLI measure smoke run succeeds.' ([ordered]@{
        run = $out
        exit_code = $measure.exit_code
      })

    $inspect = Invoke-RootMeasure @('inspect', '--run', $out)
    $inspectJson = Convert-JsonFromText $inspect.text
    $featureRows = if ($inspectJson -and $inspectJson.features) { [int]$inspectJson.features.row_count } else { 0 }
    $viewerExists = if ($inspectJson -and $inspectJson.artifacts -and $inspectJson.artifacts.viewer_html) { [bool]$inspectJson.artifacts.viewer_html.exists } else { $false }
    Add-Check 'scan_smoke_inspect' ($inspect.exit_code -eq 0 -and $featureRows -eq 3 -and $viewerExists) 'Inspect sees 3 feature rows and viewer.html after smoke run.' ([ordered]@{ rows = $featureRows; viewer = $viewerExists })

    $features = Join-Path $out 'features.csv'
    $compareOut = Join-Path $out 'self-compare'
    $compare = Invoke-RootMeasure @('compare', '--actual', $features, '--expected', $features, '--key', 'File.Name', '--output', $compareOut)
    $compareJson = Convert-JsonFromText $compare.text
    Add-Check 'compare_self_exact' ($compare.exit_code -eq 0 -and $compareJson -and $compareJson.status -eq 'exact') 'Comparator reports exact when comparing smoke features.csv to itself.' ([ordered]@{
        status = if ($compareJson) { $compareJson.status } else { $null }
        matched_rows = if ($compareJson) { $compareJson.matched_rows } else { $null }
        nonzero_diff_cells = if ($compareJson) { $compareJson.nonzero_diff_cells } else { $null }
        summary_json = Join-Path $compareOut 'compare-summary.json'
      })
    $artifacts['self_compare'] = $compareOut
  }
}

$failed = @($checks | Where-Object { -not $_.pass })
$summaryStatus = if ($failed.Count -eq 0) { 'pass' } else { 'fail' }
$summaryRoot = if ([string]::IsNullOrWhiteSpace($RootMeasureRoot)) { '' } else { $RootMeasureRoot }
$checkArray = @($checks.ToArray())
$artifactObject = [pscustomobject]$artifacts
$summary = [ordered]@{
  status = $summaryStatus
  generated_at = (Get-Date).ToString('o')
  plugin_root = $pluginRoot
  root_measure_root = $summaryRoot
  checks = $checkArray
  artifacts = $artifactObject
}

$summary | ConvertTo-Json -Depth 10
if ($failed.Count -gt 0) {
  exit 1
}
exit 0

