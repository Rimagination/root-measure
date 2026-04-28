$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

function Split-CommandLine {
  param([AllowNull()][string]$Line)

  if ([string]::IsNullOrWhiteSpace($Line)) {
    return @()
  }

  $result = New-Object System.Collections.Generic.List[string]
  $current = New-Object System.Text.StringBuilder
  $inQuotes = $false
  $chars = $Line.ToCharArray()
  for ($i = 0; $i -lt $chars.Length; $i++) {
    $ch = $chars[$i]
    if ($ch -eq '"') {
      $inQuotes = -not $inQuotes
      continue
    }
    if ([char]::IsWhiteSpace($ch) -and -not $inQuotes) {
      if ($current.Length -gt 0) {
        $result.Add($current.ToString()) | Out-Null
        [void]$current.Clear()
      }
      continue
    }
    [void]$current.Append($ch)
  }
  if ($current.Length -gt 0) {
    $result.Add($current.ToString()) | Out-Null
  }
  return @($result.ToArray())
}

[string[]]$InputArguments = @()
if (-not [string]::IsNullOrWhiteSpace($env:ROOT_MEASURE_CLI_ARGS)) {
  $InputArguments = @(Split-CommandLine $env:ROOT_MEASURE_CLI_ARGS)
} else {
  $InputArguments = @($args)
}
if ($InputArguments.Count -gt 0) {
  $Command = [string]$InputArguments[0]
  [string[]]$Rest = @($InputArguments | Select-Object -Skip 1)
} else {
  $Command = 'help'
  [string[]]$Rest = @()
}

function Show-Help {
  @'
Root Measure CLI

Usage:
  root-measure doctor
  root-measure measure --input <path> [--output <dir>] [--preset broken-roots|whole-root|custom] [--dpi <n>|--pixels-per-mm <n>]
  root-measure wizard
  root-measure inspect --run <dir>
  root-measure runs [--limit <n>]
  root-measure compare --actual <features.csv> --expected <expected.csv> [--key File.Name]
  root-measure raw -- <rv.exe arguments>
  root-measure release-check
  root-measure toolchain [--include-help]
  root-measure profile

Examples:
  root-measure measure --input D:\data\scans --dpi 600 --preset broken-roots
  root-measure measure --input D:\data\whole-root --pixels-per-mm 13.27 --preset whole-root
  root-measure inspect --run D:\root-measure\runs\root-measure-20260428
  root-measure raw -- -r -v -na --segment --feature --convert --factordpi 600 -op D:\out -o features.csv D:\images

Notes:
  User data usually does not have an expected CSV. Use compare only when you explicitly have a public, official, or previous expected table.
  The raw command preserves the full installed rv.exe CLI. Everything after "raw --" is forwarded unchanged.
'@
}

function Fail-Usage {
  param([string]$Message)
  [Console]::Error.WriteLine($Message)
  [Console]::Error.WriteLine('')
  Show-Help
  exit 64
}

function Convert-ArgsToOptions {
  param([string[]]$CliArgs)

  $options = @{}
  $positionals = New-Object System.Collections.Generic.List[string]
  $i = 0
  while ($i -lt $CliArgs.Count) {
    $arg = [string]$CliArgs[$i]
    if ($arg -eq '--') {
      for ($j = $i + 1; $j -lt $CliArgs.Count; $j++) {
        $positionals.Add([string]$CliArgs[$j]) | Out-Null
      }
      break
    }

    if ($arg.StartsWith('--')) {
      $name = $arg.Substring(2)
      $value = $true
      $eq = $name.IndexOf('=')
      if ($eq -ge 0) {
        $value = $name.Substring($eq + 1)
        $name = $name.Substring(0, $eq)
      } elseif (($i + 1) -lt $CliArgs.Count -and -not ([string]$CliArgs[$i + 1]).StartsWith('--')) {
        $i += 1
        $value = [string]$CliArgs[$i]
      }
      $options[$name.ToLowerInvariant()] = $value
    } else {
      $positionals.Add($arg) | Out-Null
    }
    $i += 1
  }

  [pscustomobject]@{
    options = $options
    positionals = @($positionals.ToArray())
  }
}

function Get-Option {
  param(
    [hashtable]$Options,
    [string[]]$Names,
    [AllowNull()]$Default = $null
  )

  foreach ($name in $Names) {
    $key = $name.ToLowerInvariant()
    if ($Options.ContainsKey($key)) {
      return $Options[$key]
    }
  }
  return $Default
}

function Test-Flag {
  param(
    [hashtable]$Options,
    [string[]]$Names
  )
  foreach ($name in $Names) {
    if ($Options.ContainsKey($name.ToLowerInvariant())) {
      return [bool]$Options[$name.ToLowerInvariant()]
    }
  }
  return $false
}

function Split-ListValue {
  param([AllowNull()]$Value)
  if ($null -eq $Value -or $Value -eq $true) {
    return @()
  }
  @(([string]$Value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  )
}

function Resolve-PresetName {
  param([AllowNull()][string]$Preset)
  if ([string]::IsNullOrWhiteSpace($Preset)) {
    return 'broken-roots-exact'
  }
  switch ($Preset.ToLowerInvariant()) {
    'broken-roots' { 'broken-roots-exact'; return }
    'broken-root' { 'broken-roots-exact'; return }
    'broken-roots-exact' { 'broken-roots-exact'; return }
    'whole-root' { 'whole-root-exact'; return }
    'whole-roots' { 'whole-root-exact'; return }
    'crown' { 'whole-root-exact'; return }
    'whole-root-exact' { 'whole-root-exact'; return }
    'custom' { 'custom'; return }
    default { Fail-Usage "Unknown preset: $Preset" }
  }
}

function Invoke-PluginScript {
  param(
    [string]$Name,
    [string[]]$Arguments = @()
  )

  $script = Join-Path $PSScriptRoot $Name
  if (-not (Test-Path -LiteralPath $script)) {
    throw "Plugin script not found: $script"
  }

  & powershell -NoProfile -ExecutionPolicy Bypass -File $script @Arguments
  exit $LASTEXITCODE
}

function Invoke-Measure {
  param([string[]]$CliArgs)
  $parsed = Convert-ArgsToOptions $CliArgs
  $options = $parsed.options
  $inputPath = Get-Option $options @('input', 'input-path', 'i')
  if ([string]::IsNullOrWhiteSpace([string]$inputPath)) {
    Fail-Usage 'measure requires --input <path>.'
  }

  $scriptArgs = @('-InputPath', [string]$inputPath)
  $outputRoot = Get-Option $options @('output', 'output-root', 'out', 'o')
  if (-not [string]::IsNullOrWhiteSpace([string]$outputRoot)) {
    $scriptArgs += @('-OutputRoot', [string]$outputRoot)
  }
  $scriptArgs += @('-Preset', (Resolve-PresetName ([string](Get-Option $options @('preset', 'p') 'broken-roots-exact'))))

  $dpi = Get-Option $options @('dpi')
  $pixelsPerMm = Get-Option $options @('pixels-per-mm', 'pixels-permm', 'ppm')
  if ($dpi -and $pixelsPerMm) {
    Fail-Usage 'Use either --dpi or --pixels-per-mm, not both.'
  }
  if ($dpi) {
    $scriptArgs += @('-Dpi', [string]$dpi)
  }
  if ($pixelsPerMm) {
    $scriptArgs += @('-PixelsPerMm', [string]$pixelsPerMm)
  }
  if (Test-Flag $options @('no-viewer')) {
    $scriptArgs += '-NoViewer'
  }
  if (Test-Flag $options @('no-segment-images')) {
    $scriptArgs += '-NoSegmentImages'
  }
  if (Test-Flag $options @('no-feature-images')) {
    $scriptArgs += '-NoFeatureImages'
  }
  $root = Get-Option $options @('root-measure-root')
  if ($root) {
    $scriptArgs += @('-RootMeasureRoot', [string]$root)
  }

  Invoke-PluginScript 'measure.ps1' $scriptArgs
}

function Invoke-Inspect {
  param([string[]]$CliArgs)
  $parsed = Convert-ArgsToOptions $CliArgs
  $run = Get-Option $parsed.options @('run', 'run-directory', 'dir')
  if ([string]::IsNullOrWhiteSpace([string]$run)) {
    if ($parsed.positionals.Count -gt 0) {
      $run = $parsed.positionals[0]
    } else {
      Fail-Usage 'inspect requires --run <dir>.'
    }
  }
  Invoke-PluginScript 'inspect-run.ps1' @('-RunDirectory', [string]$run)
}

function Invoke-Runs {
  param([string[]]$CliArgs)
  $parsed = Convert-ArgsToOptions $CliArgs
  $limit = Get-Option $parsed.options @('limit', 'n') 10
  $scriptArgs = @('-Limit', [string]$limit)
  $root = Get-Option $parsed.options @('root-measure-root')
  if ($root) {
    $scriptArgs += @('-RootMeasureRoot', [string]$root)
  }
  Invoke-PluginScript 'list-runs.ps1' $scriptArgs
}

function Invoke-Compare {
  param([string[]]$CliArgs)
  $parsed = Convert-ArgsToOptions $CliArgs
  $options = $parsed.options
  $actual = Get-Option $options @('actual', 'actual-csv')
  $expected = Get-Option $options @('expected', 'expected-csv')
  if ([string]::IsNullOrWhiteSpace([string]$actual) -or [string]::IsNullOrWhiteSpace([string]$expected)) {
    Fail-Usage 'compare requires --actual <features.csv> and --expected <expected.csv>.'
  }

  $scriptArgs = @('-ActualCsv', [string]$actual, '-ExpectedCsv', [string]$expected)
  $keys = Split-ListValue (Get-Option $options @('key', 'keys', 'key-columns') 'File.Name')
  if ($keys.Count -gt 0) {
    $scriptArgs += '-KeyColumns'
    $scriptArgs += $keys
  }
  $metrics = Split-ListValue (Get-Option $options @('metrics') $null)
  if ($metrics.Count -gt 0) {
    $scriptArgs += '-Metrics'
    $scriptArgs += $metrics
  }
  $exclude = Split-ListValue (Get-Option $options @('exclude', 'exclude-columns') $null)
  if ($exclude.Count -gt 0) {
    $scriptArgs += '-ExcludeColumns'
    $scriptArgs += $exclude
  }
  $dupMode = Get-Option $options @('duplicate-key-mode', 'duplicates') $null
  if ($dupMode) {
    $scriptArgs += @('-DuplicateKeyMode', [string]$dupMode)
  }
  $tolerance = Get-Option $options @('tolerance', 'abs-tolerance') $null
  if ($tolerance) {
    $scriptArgs += @('-Tolerance', [string]$tolerance)
  }
  $relativeTolerance = Get-Option $options @('relative-tolerance', 'rel-tolerance') $null
  if ($relativeTolerance) {
    $scriptArgs += @('-RelativeTolerance', [string]$relativeTolerance)
  }
  $out = Get-Option $options @('output', 'output-dir', 'out')
  if ($out) {
    $scriptArgs += @('-OutputDirectory', [string]$out)
  }

  Invoke-PluginScript 'compare-features.ps1' $scriptArgs
}

function Invoke-Doctor {
  param([string[]]$CliArgs)
  $parsed = Convert-ArgsToOptions $CliArgs
  $scriptArgs = @()
  $root = Get-Option $parsed.options @('root-measure-root')
  if ($root) {
    $scriptArgs += @('-RootMeasureRoot', [string]$root)
  }
  if (Test-Flag $parsed.options @('include-help')) {
    $scriptArgs += '-IncludeHelp'
  }
  Invoke-PluginScript 'doctor.ps1' $scriptArgs
}

function Invoke-Toolchain {
  param([string[]]$CliArgs)
  $parsed = Convert-ArgsToOptions $CliArgs
  $scriptArgs = @()
  $root = Get-Option $parsed.options @('root-measure-root')
  if ($root) {
    $scriptArgs += @('-RootMeasureRoot', [string]$root)
  }
  if (Test-Flag $parsed.options @('include-help')) {
    $scriptArgs += '-IncludeHelp'
  }
  Invoke-PluginScript 'toolchain.ps1' $scriptArgs
}

function Invoke-Wizard {
  param([string[]]$CliArgs)
  $parsed = Convert-ArgsToOptions $CliArgs
  $scriptArgs = @()
  $root = Get-Option $parsed.options @('root-measure-root')
  if ($root) {
    $scriptArgs += @('-RootMeasureRoot', [string]$root)
  }
  Invoke-PluginScript 'start-analysis.ps1' $scriptArgs
}

function Invoke-ReleaseCheck {
  param([string[]]$CliArgs)
  $parsed = Convert-ArgsToOptions $CliArgs
  $scriptArgs = @()
  $root = Get-Option $parsed.options @('root-measure-root')
  if ($root) {
    $scriptArgs += @('-RootMeasureRoot', [string]$root)
  }
  if (Test-Flag $parsed.options @('skip-smoke')) {
    $scriptArgs += '-SkipSmoke'
  }
  Invoke-PluginScript 'release-check.ps1' $scriptArgs
}

function Invoke-Raw {
  param([string[]]$CliArgs)
  $rvArgs = @($CliArgs)
  if ($rvArgs.Count -gt 0 -and $rvArgs[0] -eq '--') {
    $rvArgs = @($rvArgs | Select-Object -Skip 1)
  }
  if ($rvArgs.Count -eq 0) {
    Fail-Usage 'raw requires rv.exe arguments, usually after "raw --".'
  }
  Invoke-PluginScript 'invoke-rv.ps1' $rvArgs
}

$normalizedCommand = if ([string]::IsNullOrWhiteSpace($Command)) { 'help' } else { $Command.ToLowerInvariant() }
switch ($normalizedCommand) {
  'help' { Show-Help; exit 0 }
  '-h' { Show-Help; exit 0 }
  '--help' { Show-Help; exit 0 }
  'measure' { Invoke-Measure $Rest }
  'doctor' { Invoke-Doctor $Rest }
  'toolchain' { Invoke-Toolchain $Rest }
  'profile' { Invoke-PluginScript 'reproducibility-profile.ps1' @() }
  'wizard' { Invoke-Wizard $Rest }
  'start' { Invoke-Wizard $Rest }
  'inspect' { Invoke-Inspect $Rest }
  'runs' { Invoke-Runs $Rest }
  'list-runs' { Invoke-Runs $Rest }
  'compare' { Invoke-Compare $Rest }
  'raw' { Invoke-Raw $Rest }
  'release-check' { Invoke-ReleaseCheck $Rest }
  default { Fail-Usage "Unknown command: $Command" }
}

