param(
  [string]$RootMeasureRoot = '',
  [string]$SearchPath = '',
  [int]$Limit = 20
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

function Test-RveFeatureCsv {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return $false
  }
  try {
    $header = Get-Content -LiteralPath $Path -Encoding UTF8 -TotalCount 1 -ErrorAction Stop
    return (($header -like 'File.Name,*') -and ($header -like '*Total.Root.Length*'))
  } catch {
    return $false
  }
}

function Find-FeatureCsv {
  param([string]$Directory)

  $default = Join-Path $Directory 'features.csv'
  if (Test-RveFeatureCsv $default) {
    return $default
  }

  foreach ($csv in @(Get-ChildItem -LiteralPath $Directory -File -Filter '*.csv' -ErrorAction SilentlyContinue | Sort-Object Name)) {
    if (Test-RveFeatureCsv $csv.FullName) {
      return $csv.FullName
    }
  }

  return $null
}

$root = & (Join-Path $PSScriptRoot 'Resolve-RootMeasureRoot.ps1') -RootMeasureRoot $RootMeasureRoot
if (-not [string]::IsNullOrWhiteSpace($SearchPath)) {
  $resolvedSearch = (Resolve-Path -LiteralPath $SearchPath).Path
  $searchItem = Get-Item -LiteralPath $resolvedSearch
  if ($searchItem.PSIsContainer -and $searchItem.Name -eq 'root-measure-results') {
    $runsRoot = $searchItem.FullName
  } elseif ($searchItem.PSIsContainer) {
    $runsRoot = Join-Path $searchItem.FullName 'root-measure-results'
  } else {
    $runsRoot = Join-Path $searchItem.Directory.FullName 'root-measure-results'
  }
} else {
  $runsRoot = Join-Path $root 'runs'
}

if (-not (Test-Path -LiteralPath $runsRoot)) {
  [ordered]@{
    root_measure_root = $root
    runs_root = $runsRoot
    runs = @()
  } | ConvertTo-Json -Depth 5
  return
}

$runs = @(Get-ChildItem -LiteralPath $runsRoot -Directory | ForEach-Object {
    $dir = $_.FullName
    $manifestPath = Join-Path $dir 'run_manifest.json'
    $featuresPath = Find-FeatureCsv $dir
    $viewerPath = Join-Path $dir 'viewer.html'
    $status = $null
    $preset = $null
    $finishedAt = $null
    $rowCount = $null
    if (Test-Path -LiteralPath $manifestPath) {
      try {
        $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
        $status = $manifest.status
        $preset = $manifest.preset
        $finishedAt = $manifest.finished_at
      } catch {
        $status = 'manifest-read-error'
      }
    }
    if ((-not [string]::IsNullOrWhiteSpace($featuresPath)) -and (Test-Path -LiteralPath $featuresPath)) {
      try {
        $rowCount = @(Import-Csv -LiteralPath $featuresPath).Count
      } catch {
        $rowCount = $null
      }
    }
    [pscustomobject][ordered]@{
      name = $_.Name
      path = $dir
      last_write_time = $_.LastWriteTime.ToString('o')
      status = $status
      preset = $preset
      finished_at = $finishedAt
      feature_rows = $rowCount
      has_manifest = Test-Path -LiteralPath $manifestPath
      has_features_csv = (-not [string]::IsNullOrWhiteSpace($featuresPath)) -and (Test-Path -LiteralPath $featuresPath)
      features_csv = $featuresPath
      has_viewer_html = Test-Path -LiteralPath $viewerPath
      viewer_html = if (Test-Path -LiteralPath $viewerPath) { $viewerPath } else { $null }
    }
  } | Sort-Object last_write_time -Descending | Select-Object -First $Limit)

[ordered]@{
  root_measure_root = $root
  runs_root = $runsRoot
  count = $runs.Count
  runs = @($runs)
} | ConvertTo-Json -Depth 7
