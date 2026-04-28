param(
  [string]$RootMeasureRoot = ''
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

function Ask-Text {
  param(
    [string]$Prompt,
    [string]$Default = ''
  )
  if ([string]::IsNullOrWhiteSpace($Default)) {
    return (Read-Host $Prompt).Trim()
  }
  $value = (Read-Host "$Prompt [$Default]").Trim()
  if ([string]::IsNullOrWhiteSpace($value)) {
    return $Default
  }
  return $value
}

function Ask-Choice {
  param(
    [string]$Prompt,
    [string[]]$Allowed,
    [string]$Default
  )
  while ($true) {
    $value = Ask-Text $Prompt $Default
    if ($Allowed -contains $value) {
      return $value
    }
    Write-Host "Please enter one of: $($Allowed -join ', ')"
  }
}

function Invoke-RootMeasure {
  param([string[]]$Arguments)
  $rootCli = Join-Path $PSScriptRoot 'root-measure.ps1'
  if (-not [string]::IsNullOrWhiteSpace($RootMeasureRoot)) {
    $Arguments += @('--root-measure-root', $RootMeasureRoot)
  }
  & powershell -NoProfile -ExecutionPolicy Bypass -File $rootCli @Arguments
  exit $LASTEXITCODE
}

function Add-ScaleArguments {
  param([string[]]$Arguments)
  Write-Host ''
  Write-Host 'Scale controls whether mm, area, and volume metrics are physically meaningful.'
  Write-Host '1. I know DPI'
  Write-Host '2. I know pixels/mm'
  Write-Host '3. No scale for now; run measurement and QC only'
  $scale = Ask-Choice 'Choose scale type' @('1', '2', '3') '1'
  if ($scale -eq '1') {
    $dpi = Ask-Text 'DPI'
    if (-not [string]::IsNullOrWhiteSpace($dpi)) {
      return @($Arguments + @('--dpi', $dpi))
    }
  }
  if ($scale -eq '2') {
    $ppm = Ask-Text 'pixels/mm'
    if (-not [string]::IsNullOrWhiteSpace($ppm)) {
      return @($Arguments + @('--pixels-per-mm', $ppm))
    }
  }
  Write-Host 'No scale provided. This run is useful for workflow QC, but mm-based metrics should not be treated as physical measurements.'
  return @($Arguments)
}

function Start-MeasurementWizard {
  $inputPath = Ask-Text 'Image file or folder path'
  if ([string]::IsNullOrWhiteSpace($inputPath)) {
    throw 'Input path is required.'
  }
  Write-Host ''
  Write-Host 'Root type:'
  Write-Host '1. broken roots'
  Write-Host '2. whole root / crown'
  Write-Host '3. custom preset'
  $presetChoice = Ask-Choice 'Choose' @('1', '2', '3') '1'
  $preset = switch ($presetChoice) {
    '1' { 'broken-roots' }
    '2' { 'whole-root' }
    default { 'custom' }
  }

  $args = @('measure', '--input', $inputPath, '--preset', $preset)
  $output = Ask-Text 'Output directory; leave blank for automatic runs folder' ''
  if (-not [string]::IsNullOrWhiteSpace($output)) {
    $args += @('--output', $output)
  }
  $args = Add-ScaleArguments $args

  $withArtifacts = Ask-Choice 'Generate viewer, segment images, feature overlays, and logs? 1=yes, 2=no' @('1', '2') '1'
  if ($withArtifacts -eq '2') {
    $args += @('--no-viewer', '--no-segment-images', '--no-feature-images')
  }

  Invoke-RootMeasure $args
}

function Start-ReproductionWizard {
  Write-Host ''
  Write-Host 'Public-data reproduction requires downloaded images, an expected CSV, and a parameter source.'
  Write-Host 'If the parameters cannot be expressed by a high-level preset, use: root-measure raw -- <rv.exe arguments>.'
  $inputPath = Ask-Text 'Image file or folder path'
  $expected = Ask-Text 'expected CSV path'
  if ([string]::IsNullOrWhiteSpace($inputPath) -or [string]::IsNullOrWhiteSpace($expected)) {
    throw 'Reproduction requires both image path and expected CSV.'
  }

  Write-Host ''
  Write-Host 'This wizard runs a high-level preset first, then compares to expected CSV. Use raw for special public workflows.'
  $presetChoice = Ask-Choice 'preset: 1=broken-roots, 2=whole-root, 3=custom' @('1', '2', '3') '1'
  $preset = switch ($presetChoice) {
    '1' { 'broken-roots' }
    '2' { 'whole-root' }
    default { 'custom' }
  }

  $output = Ask-Text 'Output directory; leave blank for automatic runs folder' ''
  $measureArgs = @('measure', '--input', $inputPath, '--preset', $preset)
  if (-not [string]::IsNullOrWhiteSpace($output)) {
    $measureArgs += @('--output', $output)
  }
  $measureArgs = Add-ScaleArguments $measureArgs

  $rootCli = Join-Path $PSScriptRoot 'root-measure.ps1'
  if (-not [string]::IsNullOrWhiteSpace($RootMeasureRoot)) {
    $measureArgs += @('--root-measure-root', $RootMeasureRoot)
  }
  & powershell -NoProfile -ExecutionPolicy Bypass -File $rootCli @measureArgs
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  if ([string]::IsNullOrWhiteSpace($output)) {
    Write-Host ''
    Write-Host 'Measurement finished. Because the output directory was automatic, use the output_root shown above and run compare separately.'
    exit 0
  }

  $features = Join-Path ([System.IO.Path]::GetFullPath($output)) 'features.csv'
  $key = Ask-Text 'Comparison key columns, comma-separated' 'File.Name'
  $dup = Ask-Text 'Duplicate key mode: Fail, Occurrence, BestMatch' 'Fail'
  $compareOut = Join-Path ([System.IO.Path]::GetFullPath($output)) 'compare'
  Invoke-RootMeasure @('compare', '--actual', $features, '--expected', $expected, '--key', $key, '--duplicate-key-mode', $dup, '--output', $compareOut)
}

function Start-InspectWizard {
  $run = Ask-Text 'Run directory path'
  if ([string]::IsNullOrWhiteSpace($run)) {
    throw 'Run directory is required.'
  }
  Invoke-RootMeasure @('inspect', '--run', $run)
}

function Start-TroubleshootWizard {
  Write-Host ''
  Write-Host 'Troubleshooting starts with toolchain checks, then can inspect an existing run directory.'
  $rootCli = Join-Path $PSScriptRoot 'root-measure.ps1'
  $doctorArgs = @('doctor')
  if (-not [string]::IsNullOrWhiteSpace($RootMeasureRoot)) {
    $doctorArgs += @('--root-measure-root', $RootMeasureRoot)
  }
  & powershell -NoProfile -ExecutionPolicy Bypass -File $rootCli @doctorArgs
  $choice = Ask-Choice 'Inspect an existing run directory? 1=yes, 2=no' @('1', '2') '1'
  if ($choice -eq '1') {
    Start-InspectWizard
  }
}

function Start-RawWizard {
  Write-Host ''
  Write-Host 'Enter full rv.exe arguments. Example: -r -v -na --segment --feature --convert --factordpi 600 -op D:\out -o features.csv D:\images'
  $line = Ask-Text 'rv.exe arguments'
  if ([string]::IsNullOrWhiteSpace($line)) {
    throw 'rv.exe arguments are required.'
  }
  $tokens = [System.Management.Automation.PSParser]::Tokenize($line, [ref]$null) |
    Where-Object { $_.Type -in @('CommandArgument', 'CommandParameter', 'String', 'Number') } |
    ForEach-Object { $_.Content }
  Invoke-RootMeasure (@('raw', '--') + @($tokens))
}

Write-Host 'Root Measure analysis wizard'
Write-Host ''
Write-Host '1. Analyze my own new data'
Write-Host '2. Reproduce public data and compare an expected CSV'
Write-Host '3. Inspect an existing result folder'
Write-Host '4. Tune parameters / troubleshoot'
Write-Host '5. Use full raw rv.exe arguments'
$task = Ask-Choice 'Choose task type' @('1', '2', '3', '4', '5') '1'

switch ($task) {
  '1' { Start-MeasurementWizard }
  '2' { Start-ReproductionWizard }
  '3' { Start-InspectWizard }
  '4' { Start-TroubleshootWizard }
  '5' { Start-RawWizard }
}
