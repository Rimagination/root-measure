param(
  [string]$RootMeasureRoot = ''
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$root = & (Join-Path $PSScriptRoot 'Resolve-RootMeasureRoot.ps1') -RootMeasureRoot $RootMeasureRoot

[ordered]@{
  profile_version = 1
  root_measure_root = $root
  purpose = 'Codified root-measure validation history and reproducibility pitfalls for generic user workflows.'
  validated_toolchain = [ordered]@{
    rv_sha256 = '666021070EC31B6599086D35CB8E6EACB7416B85A2CBAA032BCFBDCAB90080D4'
    cvutil_sha256 = 'AB6E1BEAAD64DDC02FCA9CF1952F7B5A526FEE702B33E4A2BACCAD30086AA39B'
    rv_version_text = 'RhizoVision Explorer CLI Version 2.5.0 Beta'
    note = 'This is a private compatibility toolchain validated against public Explorer-origin outputs. A hash change creates a new baseline until re-compared.'
  }
  exact_validation_evidence = @(
    [ordered]@{
      label = 'Broken roots copper-wire official CSV'
      evidence = 'Zenodo 4677546 images plus Zenodo 4677553 official paper table'
      result = 'threshold 191: 28/28 exact; threshold 222: 28/28 exact; max_abs_diff 0'
      local_report = Join-Path $root 'runs\rv-official-reproduction-copper-wire\official-comparison-report.md'
    },
    [ordered]@{
      label = 'Broken roots multispecies official CSVs'
      evidence = 'Zenodo 4677751 images and official RhizoVision Explorer outputs'
      result = 'herbaceous 318/318, maize 90/90 plus duplicate best 10/10, trees 70/70, wheat 100/100; max_abs_diff 0'
      local_report = Join-Path $root 'runs\rv-official-reproduction-multispecies\official-multispecies-comparison-report.md'
    },
    [ordered]@{
      label = 'Whole root CrownRoots Explorer-origin CSVs'
      evidence = 'Zenodo 8083525 Phenology CrownRoots processed features.csv tables'
      result = '2023_02_06 50/50, 2023_03_13 25/25, 2023_04_24 25/25 exact across 39 metrics; max_abs_diff 0'
      local_report = Join-Path $root 'runs\rv-zenodo-8083525-whole-root-validation\report.md'
    },
    [ordered]@{
      label = '2024 multi-scan concatenation official CSVs'
      evidence = 'Zenodo 12667584 images plus Zenodo 12668178 official RVE CSV outputs'
      result = '6 CSV groups, 311/311 rows exact, 4665 compared cells, nonzero_diff_cells 0'
      local_report = Join-Path $root 'runs\rv-concatenation-2024-official-csv-reproduction\official-concatenation-2024-report.md'
    }
  )
  generic_reproducibility_workflow = @(
    'Run doctor.ps1 and require validated toolchain hashes for claims tied to previous public-data validation.',
    'Collect the user-downloaded images, official expected CSV, and parameter source before claiming official agreement.',
    'Run rv.exe with explicit flags. Do not rely on implicit defaults for threshold, root type, scale, filters, pruning, or diameter ranges.',
    'Preserve run_manifest.json, stdout/stderr, rv.log, input hashes, toolchain hashes, and generated intermediate images.',
    'Compare generated features.csv to the expected CSV with compare-features.ps1.',
    'Report exact only when compare-features.ps1 returns status exact. Tolerance-based comparisons must be named as tolerance-based.'
  )
  pitfalls = @(
    [ordered]@{
      id = 'smoke-is-not-oracle'
      severity = 'high'
      rule = 'GitHub imageexamples scans/crowns only prove the tool runs and emits the expected schema; they are not numeric expected-output oracles.'
    },
    [ordered]@{
      id = 'official-gui-is-not-cli'
      severity = 'high'
      rule = 'The official Windows GUI package is useful for manual reference but should not be treated as an automated backend.'
    },
    [ordered]@{
      id = 'hashes-before-claims'
      severity = 'critical'
      rule = 'Always check rv.exe and cvutil.dll SHA256 before reusing previous validation claims.'
    },
    [ordered]@{
      id = 'cvutil-compatibility'
      severity = 'critical'
      rule = 'Do not replace the installed cvutil.dll with upstream 2.5.0 boundary behavior or a naive 1px patch; exact multispecies reproduction depends on current ABI plus official 2.0.2 skeleton/distance-transform behavior.'
    },
    [ordered]@{
      id = 'length-compatibility'
      severity = 'critical'
      rule = 'Copper-wire exactness depends on the private compatibility behavior that avoids the upstream 2.5.0 getrootlength_new overwrite of histogram-derived length.'
    },
    [ordered]@{
      id = 'metafile-not-automation-contract'
      severity = 'high'
      rule = 'Do not rely on --metafile for exact reproduction. Translate public metadata/settings CSVs into explicit CLI flags.'
    },
    [ordered]@{
      id = 'dpi-not-implicit'
      severity = 'high'
      rule = 'Do not silently assume DPI. If image metadata is absent, require user-supplied --factordpi or intentional pixel-unit output.'
    },
    [ordered]@{
      id = 'paper-text-not-complete-config'
      severity = 'high'
      rule = 'Paper-visible settings may omit saved RVE toggles. The 2024 concatenation dataset required --bgnoise --bgsize 1 in addition to visible threshold, DPI, and pruning settings.'
    },
    [ordered]@{
      id = 'duplicates-need-audit'
      severity = 'medium'
      rule = 'Official expected CSVs can contain duplicate File.Name rows, as seen in multispecies maize. Use compare-features.ps1 -DuplicateKeyMode BestMatch when the expected oracle has duplicate keys.'
    },
    [ordered]@{
      id = 'computation-time-volatile'
      severity = 'medium'
      rule = 'Exclude Computation.Time.s from exact numeric reproduction comparisons unless the user explicitly wants runtime comparison.'
    },
    [ordered]@{
      id = 'analyzer-is-not-explorer-oracle'
      severity = 'high'
      rule = 'Do not use RhizoVision Crown or Analyzer expected tables as RhizoVision Explorer numeric validation. Use Explorer-origin tables such as Zenodo 8083525 for whole-root exactness.'
    },
    [ordered]@{
      id = 'whole-root-orientation-regression'
      severity = 'critical'
      rule = 'Whole-root exactness depends on the closed-form 2D covariance PCA orientation behavior; OpenCV cv::eigen axis selection caused previous angle-frequency residuals.'
    },
    [ordered]@{
      id = 'large-image-memory'
      severity = 'medium'
      rule = 'Large concatenated PNGs can hit OpenCV allocation failures in batch mode. Retry per image in a fresh process before declaring the image unusable.'
    },
    [ordered]@{
      id = 'r-paper-stats-not-direct-cli-oracle'
      severity = 'medium'
      rule = 'Zenodo 4677553 reproduces paper statistics and figures; it is not by itself a direct image-to-features CLI oracle for arbitrary user images.'
    }
  )
} | ConvertTo-Json -Depth 8

