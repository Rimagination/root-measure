param()

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$resolver = Join-Path $repoRoot 'scripts\Resolve-DefaultOutputRoot.ps1'
$sandbox = Join-Path $repoRoot '.tmp\test-default-output-root'
$inputDir = Join-Path $sandbox 'input-folder'
$inputFile = Join-Path $inputDir 'scan1.png'

New-Item -ItemType Directory -Force -Path $inputDir | Out-Null
if (-not (Test-Path -LiteralPath $inputFile)) {
  New-Item -ItemType File -Path $inputFile | Out-Null
}

$folderResult = & powershell -NoProfile -ExecutionPolicy Bypass -File $resolver -InputPath $inputDir -RunName 'case-folder' | ConvertFrom-Json
$expectedFolderRoot = Join-Path $inputDir 'root-measure-results'
$expectedFolderOutput = Join-Path $expectedFolderRoot 'case-folder'
if ($folderResult.output_root -ne $expectedFolderOutput) {
  Write-Error "Expected folder output '$expectedFolderOutput' but got '$($folderResult.output_root)'."
}

$fileResult = & powershell -NoProfile -ExecutionPolicy Bypass -File $resolver -InputPath $inputFile -RunName 'case-file' | ConvertFrom-Json
$expectedFileRoot = Join-Path $inputDir 'root-measure-results'
$expectedFileOutput = Join-Path $expectedFileRoot 'case-file'
if ($fileResult.output_root -ne $expectedFileOutput) {
  Write-Error "Expected file output '$expectedFileOutput' but got '$($fileResult.output_root)'."
}

Write-Host 'PASS: default output roots resolve next to the input path.'
