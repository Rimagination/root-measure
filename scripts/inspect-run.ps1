param(
  [Parameter(Mandatory = $true)]
  [string]$RunDirectory
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

function Read-TextTail {
  param(
    [string]$Path,
    [int]$Count = 60
  )
  if (-not (Test-Path -LiteralPath $Path)) {
    return @()
  }
  return [string[]]@(Get-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction SilentlyContinue | Select-Object -Last $Count | ForEach-Object { [string]$_ })
}

function Get-FileState {
  param([string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) {
    return [ordered]@{
      path = $null
      exists = $false
      size_bytes = $null
    }
  }
  [ordered]@{
    path = $Path
    exists = Test-Path -LiteralPath $Path
    size_bytes = if (Test-Path -LiteralPath $Path) { (Get-Item -LiteralPath $Path).Length } else { $null }
  }
}

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

  $csvs = @(Get-ChildItem -LiteralPath $Directory -File -Filter '*.csv' -ErrorAction SilentlyContinue | Sort-Object Name)
  foreach ($csv in $csvs) {
    if (Test-RveFeatureCsv $csv.FullName) {
      return $csv.FullName
    }
  }

  return $null
}

function Convert-PropertiesToOrderedHash {
  param([AllowNull()]$Object)
  $hash = [ordered]@{}
  if ($null -eq $Object) {
    return $hash
  }
  foreach ($prop in $Object.PSObject.Properties) {
    $hash[$prop.Name] = $prop.Value
  }
  return $hash
}

function Get-ArtifactInventory {
  param([string]$Directory)

  $files = @(Get-ChildItem -LiteralPath $Directory -File -Recurse -ErrorAction SilentlyContinue | Sort-Object FullName)
  foreach ($file in $files) {
    $kind = switch -Regex ($file.Name) {
      '^features\.csv$' { 'features_csv'; break }
      '\.csv$' { if (Test-RveFeatureCsv $file.FullName) { 'features_csv' } else { 'csv' }; break }
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
      name = $file.Name
      path = $file.FullName
      relative_path = $file.FullName.Substring($Directory.Length).TrimStart('\', '/')
      kind = $kind
      extension = $file.Extension
      size_bytes = $file.Length
      last_write_time = $file.LastWriteTime.ToString('o')
    }
  }
}

$run = [System.IO.Path]::GetFullPath($RunDirectory)
if (-not (Test-Path -LiteralPath $run)) {
  throw "Run directory not found: $run"
}

$manifestPath = Join-Path $run 'run_manifest.json'
$viewerDataPath = Join-Path $run 'viewer-data.json'
$featuresPath = Find-FeatureCsv $run
$stdoutPath = Join-Path $run 'rv.stdout.txt'
$stderrPath = Join-Path $run 'rv.stderr.txt'
$rvLogPath = Join-Path $run 'rv.log'
$viewerPath = Join-Path $run 'viewer.html'

$manifest = $null
$viewerData = $null
$rows = @()
$columns = @()
if (Test-Path -LiteralPath $manifestPath) {
  $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
}
if (Test-Path -LiteralPath $viewerDataPath) {
  $viewerData = Get-Content -Raw -Encoding UTF8 -LiteralPath $viewerDataPath | ConvertFrom-Json
}
if ((-not [string]::IsNullOrWhiteSpace($featuresPath)) -and (Test-Path -LiteralPath $featuresPath)) {
  $rows = @(Import-Csv -LiteralPath $featuresPath)
  if ($rows.Count -gt 0) {
    $columns = @($rows[0].PSObject.Properties.Name)
  }
}

$keyColumns = @(
  'File.Name',
  'Number.of.Root.Tips',
  'Number.of.Branch.Points',
  'Total.Root.Length.mm',
  'Depth.mm',
  'Maximum.Width.mm',
  'Network.Area.mm2',
  'Average.Diameter.mm',
  'Median.Diameter.mm',
  'Maximum.Diameter.mm',
  'Average.Root.Orientation.deg',
  'Computation.Time.s'
)

$sampleRows = @()
foreach ($row in ($rows | Select-Object -First 3)) {
  $record = [ordered]@{}
  foreach ($col in $keyColumns) {
    if ($row.PSObject.Properties.Name -contains $col) {
      $record[$col] = $row.$col
    }
  }
  $sampleRows += [pscustomobject]$record
}

$imageRecords = @()
if ($viewerData -and $viewerData.images) {
  $imageRecords = @($viewerData.images | Select-Object -First 10 | ForEach-Object {
      [pscustomobject][ordered]@{
        file_name = $_.file_name
        status = $_.status
        original_path = $_.original_path
        segment_image = $_.segment_image
        feature_image = $_.feature_image
        sha256 = $_.sha256
      }
    })
}

[ordered]@{
  run_directory = $run
  status = if ($manifest) { $manifest.status } elseif ($viewerData) { $viewerData.status } else { $null }
  exit_code = if ($manifest) { $manifest.exit_code } else { $null }
  preset = if ($manifest) { $manifest.preset } else { $null }
  started_at = if ($manifest) { $manifest.started_at } else { $null }
  finished_at = if ($manifest) { $manifest.finished_at } else { $null }
  input = if ($manifest -and $manifest.input) {
    [ordered]@{
      path = $manifest.input.path
      file_count = @($manifest.input.files).Count
      files = @($manifest.input.files | Select-Object -First 20 | ForEach-Object {
          [pscustomobject][ordered]@{
            name = $_.name
            path = $_.path
            sha256 = $_.sha256
            size_bytes = $_.size_bytes
          }
        })
    }
  } else {
    $null
  }
  parameters = if ($manifest) { Convert-PropertiesToOrderedHash $manifest.parameters } else { $null }
  command_args = if ($manifest -and $manifest.parameters) { $manifest.parameters.rv_args } else { @() }
  toolchain = if ($manifest -and $manifest.toolchain) {
    [ordered]@{
      rv = if ($manifest.toolchain.rv) {
        [ordered]@{ path = $manifest.toolchain.rv.path; sha256 = $manifest.toolchain.rv.sha256 }
      } else { $null }
      cvutil = if ($manifest.toolchain.cvutil) {
        [ordered]@{ path = $manifest.toolchain.cvutil.path; sha256 = $manifest.toolchain.cvutil.sha256 }
      } else { $null }
    }
  } else {
    $null
  }
  artifacts = [ordered]@{
    manifest = Get-FileState $manifestPath
    viewer_data = Get-FileState $viewerDataPath
    viewer_html = Get-FileState $viewerPath
    features_csv = Get-FileState $featuresPath
    stdout = Get-FileState $stdoutPath
    stderr = Get-FileState $stderrPath
    rv_log = Get-FileState $rvLogPath
  }
  artifact_inventory = @(Get-ArtifactInventory $run)
  features = [ordered]@{
    row_count = $rows.Count
    column_count = $columns.Count
    columns = $columns
    sample_rows = @($sampleRows)
  }
  images = @($imageRecords)
  warnings = if ($manifest) { @($manifest.warnings) } elseif ($viewerData) { @($viewerData.warnings) } else { @() }
  errors = if ($manifest) { @($manifest.errors) } elseif ($viewerData) { @($viewerData.errors) } else { @() }
  log_excerpt = [ordered]@{
    stdout_tail = @(Read-TextTail $stdoutPath)
    stderr_tail = @(Read-TextTail $stderrPath)
    rv_log_tail = @(Read-TextTail $rvLogPath)
  }
} | ConvertTo-Json -Depth 12
