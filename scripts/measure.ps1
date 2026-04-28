param(
  [Parameter(Mandatory = $true)]
  [string]$InputPath,

  [string]$OutputRoot = '',

  [ValidateSet('broken-roots-exact', 'whole-root-exact', 'custom')]
  [string]$Preset = 'broken-roots-exact',

  [double]$Dpi = 0,
  [double]$PixelsPerMm = 0,

  [string]$RootMeasureRoot = '',

  [switch]$NoViewer,
  [switch]$NoSegmentImages,
  [switch]$NoFeatureImages
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

function Get-ArtifactInventory {
  param([string]$Directory)

  if (-not (Test-Path -LiteralPath $Directory)) {
    return @()
  }

  @(Get-ChildItem -LiteralPath $Directory -File -Recurse -ErrorAction SilentlyContinue | Sort-Object FullName | ForEach-Object {
      $kind = switch -Regex ($_.Name) {
        '^features\.csv$' { 'features_csv'; break }
        '^run_manifest\.json$' { 'manifest'; break }
        '^viewer-data\.json$' { 'viewer_data'; break }
        '^viewer\.html$' { 'viewer_html'; break }
        '^rv\.(stdout|stderr)\.txt$' { 'log'; break }
        '^rv\.log$' { 'log'; break }
        '_seg\.' { 'segment_image'; break }
        '_features\.' { 'feature_image'; break }
        default { 'other' }
      }
      [pscustomobject][ordered]@{
        name = $_.Name
        path = $_.FullName
        relative_path = $_.FullName.Substring($Directory.Length).TrimStart('\', '/')
        kind = $kind
        size_bytes = $_.Length
      }
    })
}

function Get-FeatureRowCount {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    return $null
  }

  try {
    return @(Import-Csv -LiteralPath $Path).Count
  } catch {
    return $null
  }
}

$root = & (Join-Path $PSScriptRoot 'Resolve-RootMeasureRoot.ps1') -RootMeasureRoot $RootMeasureRoot

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $OutputRoot = Join-Path $root "runs\root-measure-user-$stamp"
}

$script = Join-Path $root 'scripts\Invoke-RootMeasure.ps1'
$args = @(
  'measure',
  '-InputPath', $InputPath,
  '-OutputRoot', $OutputRoot,
  '-Preset', $Preset
)

if ($Dpi -gt 0) {
  $args += @('-Dpi', [string]$Dpi)
}
if ($PixelsPerMm -gt 0) {
  $args += @('-PixelsPerMm', [string]$PixelsPerMm)
}
if ($NoViewer.IsPresent) {
  $args += '-NoViewer'
}
if ($NoSegmentImages.IsPresent) {
  $args += '-NoSegmentImages'
}
if ($NoFeatureImages.IsPresent) {
  $args += '-NoFeatureImages'
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $script @args
$exitCode = $LASTEXITCODE

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputRoot)
$featuresPath = Join-Path $resolvedOutput 'features.csv'
$summary = [ordered]@{
  root_measure_root = $root
  output_root = $resolvedOutput
  exit_code = $exitCode
  feature_rows = Get-FeatureRowCount $featuresPath
  artifacts = [ordered]@{
    viewer_html = Join-Path $resolvedOutput 'viewer.html'
    viewer_data = Join-Path $resolvedOutput 'viewer-data.json'
    manifest = Join-Path $resolvedOutput 'run_manifest.json'
    features_csv = $featuresPath
    stdout = Join-Path $resolvedOutput 'rv.stdout.txt'
    stderr = Join-Path $resolvedOutput 'rv.stderr.txt'
    rv_log = Join-Path $resolvedOutput 'rv.log'
  }
  artifact_inventory = @(Get-ArtifactInventory $resolvedOutput)
}

$summary | ConvertTo-Json -Depth 6
exit $exitCode
