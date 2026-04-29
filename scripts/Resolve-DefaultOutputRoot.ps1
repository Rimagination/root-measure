param(
  [Parameter(Mandatory = $true)]
  [string]$InputPath,

  [string]$RunName = ''
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $InputPath)) {
  throw "Input path not found: $InputPath"
}

$resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path
$item = Get-Item -LiteralPath $resolvedInput
$anchorDirectory = if ($item.PSIsContainer) {
  $item.FullName
} else {
  $item.Directory.FullName
}

if ([string]::IsNullOrWhiteSpace($RunName)) {
  $RunName = 'root-measure-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
}

$resultsRoot = Join-Path $anchorDirectory 'root-measure-results'
$outputRoot = Join-Path $resultsRoot $RunName

[ordered]@{
  input_path = $resolvedInput
  anchor_directory = $anchorDirectory
  results_root = $resultsRoot
  output_root = $outputRoot
} | ConvertTo-Json -Depth 4
