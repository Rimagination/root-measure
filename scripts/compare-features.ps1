param(
  [Parameter(Mandatory = $true)]
  [string]$ExpectedCsv,

  [Parameter(Mandatory = $true)]
  [string]$ActualCsv,

  [string[]]$KeyColumns = @('File.Name'),
  [string[]]$Metrics = @(),
  [string[]]$ExcludeColumns = @('Computation.Time.s'),

  [ValidateSet('Fail', 'Occurrence', 'BestMatch')]
  [string]$DuplicateKeyMode = 'Fail',

  [double]$Tolerance = 0,
  [double]$RelativeTolerance = 0,
  [string]$OutputDirectory = '',
  [int]$MaxDiffRows = 1000
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

function Resolve-ExistingFile {
  param([string]$Path, [string]$Label)
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "$Label not found: $Path"
  }
  (Resolve-Path -LiteralPath $Path).Path
}

function Get-CsvColumns {
  param([object[]]$Rows, [string]$Path)
  if ($Rows.Count -gt 0) {
    return @($Rows[0].PSObject.Properties.Name)
  }

  $header = Get-Content -LiteralPath $Path -Encoding UTF8 -TotalCount 1
  if ([string]::IsNullOrWhiteSpace($header)) {
    return @()
  }
  return @($header -split ',')
}

function ConvertTo-Key {
  param([object]$Row, [string[]]$Columns)
  $parts = @()
  foreach ($col in $Columns) {
    $value = if ($Row.PSObject.Properties.Name -contains $col) { [string]$Row.$col } else { '' }
    $parts += $value
  }
  return ($parts -join [char]31)
}

function New-RowMap {
  param(
    [object[]]$Rows,
    [string[]]$Columns,
    [string]$Mode
  )

  $map = @{}
  $groups = @{}
  $seen = @{}
  $duplicates = @{}
  $index = 0

  foreach ($row in $Rows) {
    $index += 1
    $baseKey = ConvertTo-Key $row $Columns
    if (-not $groups.ContainsKey($baseKey)) {
      $groups[$baseKey] = @()
    }
    if (-not $seen.ContainsKey($baseKey)) {
      $seen[$baseKey] = 0
    }
    $seen[$baseKey] += 1

    if ($seen[$baseKey] -gt 1) {
      $duplicates[$baseKey] = $seen[$baseKey]
    }

    $key = $baseKey
    if ($Mode -eq 'Occurrence') {
      $key = $baseKey + [char]30 + $seen[$baseKey]
    }

    $entry = [pscustomobject][ordered]@{
      key = $key
      base_key = $baseKey
      row = $row
      row_index = $index
      occurrence = $seen[$baseKey]
    }
    $groups[$baseKey] = @($groups[$baseKey]) + $entry

    if (-not $map.ContainsKey($key)) {
      $map[$key] = $entry
    }
  }

  [pscustomobject][ordered]@{
    map = $map
    groups = $groups
    duplicates = $duplicates
  }
}

function Try-ParseDouble {
  param([AllowNull()]$Value)
  $text = [string]$Value
  if ([string]::IsNullOrWhiteSpace($text)) {
    return [pscustomobject]@{ ok = $false; value = $null }
  }

  $number = 0.0
  $styles = [System.Globalization.NumberStyles]::Float -bor [System.Globalization.NumberStyles]::AllowThousands
  $culture = [System.Globalization.CultureInfo]::InvariantCulture
  if ([double]::TryParse($text, $styles, $culture, [ref]$number)) {
    return [pscustomobject]@{ ok = $true; value = $number }
  }
  if ([double]::TryParse($text, [ref]$number)) {
    return [pscustomobject]@{ ok = $true; value = $number }
  }
  [pscustomobject]@{ ok = $false; value = $null }
}

function Test-ValueEqual {
  param(
    [AllowNull()]$Expected,
    [AllowNull()]$Actual,
    [double]$AbsTolerance,
    [double]$RelTolerance
  )

  $expectedText = [string]$Expected
  $actualText = [string]$Actual
  if ($expectedText -eq $actualText) {
    return [pscustomobject][ordered]@{ equal = $true; abs_diff = 0.0; rel_diff = 0.0; mode = 'text' }
  }

  $expectedNumber = Try-ParseDouble $expectedText
  $actualNumber = Try-ParseDouble $actualText
  if ($expectedNumber.ok -and $actualNumber.ok) {
    $abs = [Math]::Abs($actualNumber.value - $expectedNumber.value)
    $rel = if ([Math]::Abs($expectedNumber.value) -gt 0) { $abs / [Math]::Abs($expectedNumber.value) } elseif ($abs -eq 0) { 0.0 } else { [double]::PositiveInfinity }
    $equal = ($abs -le $AbsTolerance)
    if (-not $equal -and $RelTolerance -gt 0) {
      $equal = ($rel -le $RelTolerance)
    }
    return [pscustomobject][ordered]@{ equal = $equal; abs_diff = $abs; rel_diff = $rel; mode = 'numeric' }
  }

  [pscustomobject][ordered]@{ equal = $false; abs_diff = $null; rel_diff = $null; mode = 'text' }
}

function Compare-FeatureRows {
  param(
    [object]$ExpectedRow,
    [object]$ActualRow,
    [string[]]$MetricColumns,
    [double]$AbsTolerance,
    [double]$RelTolerance,
    [string]$KeyText
  )

  $rowDiffs = @()
  $diffCount = 0
  $absDiffSum = 0.0
  $maxAbs = 0.0
  $maxRel = 0.0

  foreach ($metric in $MetricColumns) {
    $comparison = Test-ValueEqual $ExpectedRow.$metric $ActualRow.$metric $AbsTolerance $RelTolerance
    if (-not $comparison.equal) {
      $diffCount += 1
      if ($comparison.abs_diff -ne $null -and -not [double]::IsInfinity($comparison.abs_diff)) {
        $absDiffSum += [double]$comparison.abs_diff
        $maxAbs = [Math]::Max($maxAbs, [double]$comparison.abs_diff)
      }
      if ($comparison.rel_diff -ne $null -and -not [double]::IsInfinity($comparison.rel_diff)) {
        $maxRel = [Math]::Max($maxRel, [double]$comparison.rel_diff)
      }
      $rowDiffs += [pscustomobject][ordered]@{
        key = $KeyText
        metric = $metric
        expected = $ExpectedRow.$metric
        actual = $ActualRow.$metric
        abs_diff = $comparison.abs_diff
        rel_diff = $comparison.rel_diff
        mode = $comparison.mode
      }
    }
  }

  [pscustomobject][ordered]@{
    exact = ($diffCount -eq 0)
    diff_count = $diffCount
    abs_diff_sum = $absDiffSum
    max_abs_diff = $maxAbs
    max_rel_diff = $maxRel
    diffs = @($rowDiffs)
  }
}

function Format-KeyForOutput {
  param([string]$Key)
  ($Key -replace [string][char]31, ' | ') -replace [string][char]30, ' #'
}

$expectedPath = Resolve-ExistingFile $ExpectedCsv 'Expected CSV'
$actualPath = Resolve-ExistingFile $ActualCsv 'Actual CSV'
$expectedRows = @(Import-Csv -LiteralPath $expectedPath)
$actualRows = @(Import-Csv -LiteralPath $actualPath)
$expectedColumns = @(Get-CsvColumns $expectedRows $expectedPath)
$actualColumns = @(Get-CsvColumns $actualRows $actualPath)

foreach ($keyColumn in $KeyColumns) {
  if ($expectedColumns -notcontains $keyColumn) {
    throw "Expected CSV is missing key column '$keyColumn': $expectedPath"
  }
  if ($actualColumns -notcontains $keyColumn) {
    throw "Actual CSV is missing key column '$keyColumn': $actualPath"
  }
}

if ($Metrics.Count -eq 0) {
  $metricSet = New-Object System.Collections.Generic.List[string]
  foreach ($col in $expectedColumns) {
    if (($actualColumns -contains $col) -and ($KeyColumns -notcontains $col) -and ($ExcludeColumns -notcontains $col)) {
      $metricSet.Add($col)
    }
  }
  $Metrics = @($metricSet)
} else {
  foreach ($metric in $Metrics) {
    if ($expectedColumns -notcontains $metric) {
      throw "Expected CSV is missing metric '$metric': $expectedPath"
    }
    if ($actualColumns -notcontains $metric) {
      throw "Actual CSV is missing metric '$metric': $actualPath"
    }
  }
}

$expectedMapResult = New-RowMap $expectedRows $KeyColumns $DuplicateKeyMode
$actualMapResult = New-RowMap $actualRows $KeyColumns $DuplicateKeyMode
$duplicateProblems = @()
if ($DuplicateKeyMode -eq 'Fail') {
  foreach ($item in $expectedMapResult.duplicates.GetEnumerator()) {
    $duplicateProblems += [pscustomobject][ordered]@{ source = 'expected'; key = Format-KeyForOutput $item.Key; count = $item.Value }
  }
  foreach ($item in $actualMapResult.duplicates.GetEnumerator()) {
    $duplicateProblems += [pscustomobject][ordered]@{ source = 'actual'; key = Format-KeyForOutput $item.Key; count = $item.Value }
  }
}

$expectedMap = $expectedMapResult.map
$actualMap = $actualMapResult.map
$missingKeys = @()
$extraKeys = @()
$diffs = @()
$duplicateKeyGroups = @()
$exactRows = 0
$matchedRows = 0
$maxAbsDiff = 0.0
$maxRelDiff = 0.0
$nonzeroDiffCells = 0

if ($DuplicateKeyMode -eq 'BestMatch' -and $duplicateProblems.Count -eq 0) {
  $expectedGroups = $expectedMapResult.groups
  $actualGroups = $actualMapResult.groups

  foreach ($key in $expectedGroups.Keys) {
    $expectedEntries = @($expectedGroups[$key])
    $actualEntries = if ($actualGroups.ContainsKey($key)) { @($actualGroups[$key]) } else { @() }

    if ($expectedEntries.Count -gt 1 -or $actualEntries.Count -gt 1) {
      $duplicateKeyGroups += [pscustomobject][ordered]@{
        key = Format-KeyForOutput $key
        expected_count = $expectedEntries.Count
        actual_count = $actualEntries.Count
      }
    }

    if ($actualEntries.Count -eq 0) {
      $missingKeys += (Format-KeyForOutput $key)
      continue
    }

    foreach ($actualEntry in $actualEntries) {
      $matchedRows += 1
      $best = $null
      foreach ($expectedEntry in $expectedEntries) {
        $candidate = Compare-FeatureRows $expectedEntry.row $actualEntry.row $Metrics $Tolerance $RelativeTolerance (Format-KeyForOutput $key)
        if (
          $null -eq $best -or
          $candidate.diff_count -lt $best.diff_count -or
          ($candidate.diff_count -eq $best.diff_count -and $candidate.abs_diff_sum -lt $best.abs_diff_sum)
        ) {
          $best = $candidate
        }
      }

      if ($best.exact) {
        $exactRows += 1
      } else {
        $nonzeroDiffCells += $best.diff_count
        $maxAbsDiff = [Math]::Max($maxAbsDiff, [double]$best.max_abs_diff)
        $maxRelDiff = [Math]::Max($maxRelDiff, [double]$best.max_rel_diff)
        foreach ($diff in $best.diffs) {
          if ($diffs.Count -lt $MaxDiffRows) {
            $diffs += $diff
          }
        }
      }
    }
  }

  foreach ($key in $actualGroups.Keys) {
    if (-not $expectedGroups.ContainsKey($key)) {
      $extraKeys += (Format-KeyForOutput $key)
    }
  }
} elseif ($duplicateProblems.Count -eq 0) {
  foreach ($key in $expectedMap.Keys) {
    if (-not $actualMap.ContainsKey($key)) {
      $missingKeys += (Format-KeyForOutput $key)
      continue
    }

    $matchedRows += 1
    $rowExact = $true
    $expectedRow = $expectedMap[$key].row
    $actualRow = $actualMap[$key].row

    foreach ($metric in $Metrics) {
      $comparison = Test-ValueEqual $expectedRow.$metric $actualRow.$metric $Tolerance $RelativeTolerance
      if (-not $comparison.equal) {
        $rowExact = $false
        if ($comparison.abs_diff -ne $null -and -not [double]::IsInfinity($comparison.abs_diff)) {
          $maxAbsDiff = [Math]::Max($maxAbsDiff, [double]$comparison.abs_diff)
        }
        if ($comparison.rel_diff -ne $null -and -not [double]::IsInfinity($comparison.rel_diff)) {
          $maxRelDiff = [Math]::Max($maxRelDiff, [double]$comparison.rel_diff)
        }
        if ($diffs.Count -lt $MaxDiffRows) {
          $diffs += [pscustomobject][ordered]@{
            key = Format-KeyForOutput $key
            metric = $metric
            expected = $expectedRow.$metric
            actual = $actualRow.$metric
            abs_diff = $comparison.abs_diff
            rel_diff = $comparison.rel_diff
            mode = $comparison.mode
          }
        }
      }
    }

    if ($rowExact) {
      $exactRows += 1
    }
  }

  foreach ($key in $actualMap.Keys) {
    if (-not $expectedMap.ContainsKey($key)) {
      $extraKeys += (Format-KeyForOutput $key)
    }
  }
}

$totalComparedCells = $matchedRows * $Metrics.Count
if ($DuplicateKeyMode -ne 'BestMatch') {
  $nonzeroDiffCells = $diffs.Count
}
$truncatedDiffs = $false
if ($DuplicateKeyMode -eq 'BestMatch') {
  $truncatedDiffs = $nonzeroDiffCells -gt $diffs.Count
} elseif ($duplicateProblems.Count -eq 0 -and $matchedRows -gt 0) {
  $allDiffCount = 0
  foreach ($key in $expectedMap.Keys) {
    if (-not $actualMap.ContainsKey($key)) {
      continue
    }
    $expectedRow = $expectedMap[$key].row
    $actualRow = $actualMap[$key].row
    foreach ($metric in $Metrics) {
      $comparison = Test-ValueEqual $expectedRow.$metric $actualRow.$metric $Tolerance $RelativeTolerance
      if (-not $comparison.equal) {
        $allDiffCount += 1
      }
    }
  }
  $nonzeroDiffCells = $allDiffCount
  $truncatedDiffs = $allDiffCount -gt $diffs.Count
}

$status = 'exact'
if ($duplicateProblems.Count -gt 0) {
  $status = 'duplicate-key-error'
} elseif ($missingKeys.Count -gt 0 -or $extraKeys.Count -gt 0 -or $nonzeroDiffCells -gt 0) {
  $status = 'different'
}

$summary = [ordered]@{
  status = $status
  expected_csv = $expectedPath
  actual_csv = $actualPath
  expected_sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $expectedPath).Hash
  actual_sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $actualPath).Hash
  key_columns = @($KeyColumns)
  duplicate_key_mode = $DuplicateKeyMode
  tolerance = $Tolerance
  relative_tolerance = $RelativeTolerance
  excluded_columns = @($ExcludeColumns)
  compared_metrics = @($Metrics)
  expected_rows = $expectedRows.Count
  actual_rows = $actualRows.Count
  matched_rows = $matchedRows
  exact_rows = $exactRows
  missing_rows = $missingKeys.Count
  extra_rows = $extraKeys.Count
  compared_cells = $totalComparedCells
  nonzero_diff_cells = $nonzeroDiffCells
  max_abs_diff = $maxAbsDiff
  max_rel_diff = $maxRelDiff
  duplicate_key_errors = @($duplicateProblems)
  duplicate_key_groups = @($duplicateKeyGroups)
  missing_keys_sample = @($missingKeys | Select-Object -First 20)
  extra_keys_sample = @($extraKeys | Select-Object -First 20)
  diff_rows_returned = $diffs.Count
  diff_rows_truncated = $truncatedDiffs
  diff_sample = @($diffs)
}

if (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) {
  $out = [System.IO.Path]::GetFullPath($OutputDirectory)
  New-Item -ItemType Directory -Force -Path $out | Out-Null
  $summaryPath = Join-Path $out 'compare-summary.json'
  $diffPath = Join-Path $out 'compare-diffs.csv'
  $summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8
  if ($diffs.Count -gt 0) {
    $diffs | Export-Csv -LiteralPath $diffPath -NoTypeInformation -Encoding UTF8
  } else {
    'key,metric,expected,actual,abs_diff,rel_diff,mode' | Set-Content -LiteralPath $diffPath -Encoding UTF8
  }
  $summary['artifacts'] = [ordered]@{
    summary_json = $summaryPath
    diffs_csv = $diffPath
  }
}

$summary | ConvertTo-Json -Depth 8

if ($status -eq 'exact') {
  exit 0
}
if ($status -eq 'duplicate-key-error') {
  exit 2
}
exit 1
