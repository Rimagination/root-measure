param(
  [Parameter(Position = 0, Mandatory = $true)]
  [ValidateSet('measure')]
  [string]$Command,

  [Parameter(Mandatory = $true)]
  [string]$InputPath,

  [Parameter(Mandatory = $true)]
  [string]$OutputRoot,

  [ValidateSet('broken-roots-exact', 'whole-root-exact', 'custom')]
  [string]$Preset = 'broken-roots-exact',

  [double]$Dpi = 0,
  [double]$PixelsPerMm = 0,

  [switch]$NoViewer,
  [switch]$NoSegmentImages,
  [switch]$NoFeatureImages
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$rv = Join-Path $projectRoot 'tools\rve-toolchain\rv.exe'
$cvutil = Join-Path $projectRoot 'tools\rve-toolchain\cvutil.dll'
$toolchainRecord = Join-Path $projectRoot 'tools\rve-toolchain\root-measure-toolchain.json'
$startedAt = Get-Date
$segmentSuffix = '_seg'
$featureSuffix = '_features'
$featuresCsv = Join-Path $OutputRoot 'features.csv'
$stdoutPath = Join-Path $OutputRoot 'rv.stdout.txt'
$stderrPath = Join-Path $OutputRoot 'rv.stderr.txt'
$manifestPath = Join-Path $OutputRoot 'run_manifest.json'
$viewerDataPath = Join-Path $OutputRoot 'viewer-data.json'
$viewerHtmlPath = Join-Path $OutputRoot 'viewer.html'
$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$rvExitCode = $null
$rvArgs = @()

function Convert-ToFileUrl {
  param([AllowNull()][string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) {
    return $null
  }
  try {
    $full = [System.IO.Path]::GetFullPath($Path)
    return ([System.Uri]::new($full)).AbsoluteUri
  } catch {
    return $null
  }
}

function Convert-ToProcessArgumentString {
  param([string[]]$Arguments)
  $quoted = foreach ($arg in $Arguments) {
    if ($null -eq $arg) {
      '""'
    } else {
      '"' + (($arg -replace '\\$', '\\') -replace '"', '\"') + '"'
    }
  }
  return ($quoted -join ' ')
}

function Get-SupportedImageFiles {
  param([string]$Path)

  $supported = @{
    '.png' = $true
    '.jpg' = $true
    '.jpeg' = $true
    '.bmp' = $true
    '.tif' = $true
    '.tiff' = $true
  }

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Input path not found: $Path"
  }

  $resolved = (Resolve-Path -LiteralPath $Path).Path
  $item = Get-Item -LiteralPath $resolved
  if (-not $item.PSIsContainer) {
    if ($supported.ContainsKey($item.Extension.ToLowerInvariant())) {
      return @($item)
    }
    throw "Input file is not a supported image: $resolved"
  }

  $files = @(Get-ChildItem -LiteralPath $resolved -File | Where-Object {
      $supported.ContainsKey($_.Extension.ToLowerInvariant())
    } | Sort-Object Name)

  if ($files.Count -eq 0) {
    throw "No supported image files found in: $resolved"
  }

  return $files
}

function Get-PresetDefinition {
  param([string]$PresetName)

  switch ($PresetName) {
    'broken-roots-exact' {
      return [ordered]@{
        name = 'broken-roots-exact'
        root_type = 'broken roots'
        roottype_arg = '1'
        threshold = 220
        invert = $false
        bgnoise = $false
        bgsize = $null
        fgnoise = $false
        fgsize = $null
        smooth = $false
        smooththreshold = $null
        prune = $false
        prunethreshold = $null
        dranges = $null
        validation_status = 'validated'
        trust_note = '断根测量使用已验证的私有 RhizoVision Explorer CLI 后端。该 preset 的官方一致性证据来自 copper-wire 官方表和 multispecies 官方表；本次运行若未加载 expected CSV，则 viewer 展示的是测量结果和预设验证依据，不等同于对本次输入逐行做官方对比。'
        evidence = @(
          [ordered]@{
            label = 'Copper-wire 官方复现'
            report = 'runs\rv-official-reproduction-copper-wire\official-comparison-report.md'
            result = '28 张本地 600 dpi TIFF 图像，在 threshold 191 和 222 下与官方表逐项一致；最大绝对差 0'
          },
          [ordered]@{
            label = 'Multispecies 官方复现'
            report = 'runs\rv-official-reproduction-multispecies\official-multispecies-comparison-report.md'
            result = '588 张可用根系扫描图；所有匹配的唯一行完全一致，maize 重复行另行审计'
          }
        )
      }
    }
    'whole-root-exact' {
      return [ordered]@{
        name = 'whole-root-exact'
        root_type = 'whole root'
        roottype_arg = '0'
        threshold = 235
        invert = $true
        bgnoise = $true
        bgsize = 0.5
        fgnoise = $false
        fgsize = $null
        smooth = $false
        smooththreshold = $null
        prune = $true
        prunethreshold = 50
        dranges = '0.3,0.5,1.3'
        validation_status = 'validated'
        trust_note = 'Whole-root/crown 测量使用已验证的私有 CLI 路径，并包含解析式 2D PCA orientation 修正。该 preset 的官方一致性证据来自 Zenodo 8083525 whole-root 验证；本次运行若未加载 expected CSV，则 viewer 展示的是测量结果和预设验证依据，不等同于对本次输入逐行做官方对比。'
        evidence = @(
          [ordered]@{
            label = 'Zenodo 8083525 Phenology CrownRoots 官方复现'
            report = 'runs\rv-zenodo-8083525-whole-root-validation\report.md'
            result = '100/100 条 Explorer-origin whole-root 结果完全一致，最大绝对差 0；100/100 张 feature 图像逐像素一致'
          }
        )
      }
    }
    default {
      return [ordered]@{
        name = 'custom'
        root_type = 'broken roots'
        roottype_arg = '1'
        threshold = 200
        invert = $false
        bgnoise = $false
        bgsize = $null
        fgnoise = $false
        fgsize = $null
        smooth = $false
        smooththreshold = $null
        prune = $false
        prunethreshold = $null
        dranges = $null
        validation_status = 'unvalidated'
        trust_note = '自定义参数不是官方 exact-reproduction preset。请先检查 manifest、日志、中间图和指标，再决定是否把结果视为可信。'
        evidence = @()
      }
    }
  }
}

function Read-CsvRowsByFileName {
  param([string]$CsvPath)
  $map = @{}
  if (-not (Test-Path -LiteralPath $CsvPath)) {
    return $map
  }
  foreach ($row in @(Import-Csv -LiteralPath $CsvPath)) {
    $name = [string]$row.'File.Name'
    if ([string]::IsNullOrWhiteSpace($name)) {
      continue
    }
    if (-not $map.ContainsKey($name)) {
      $map[$name] = @()
    }
    $map[$name] += $row
  }
  return $map
}

function Convert-ObjectToOrderedHash {
  param($Object)
  $hash = [ordered]@{}
  if ($null -eq $Object) {
    return $hash
  }
  foreach ($prop in $Object.PSObject.Properties) {
    $hash[$prop.Name] = $prop.Value
  }
  return $hash
}

function Find-OutputImage {
  param(
    [string]$Directory,
    [string]$InputFileName,
    [string]$Suffix
  )
  if (-not (Test-Path -LiteralPath $Directory)) {
    return $null
  }
  $base = [System.IO.Path]::GetFileNameWithoutExtension($InputFileName)
  $matches = @(Get-ChildItem -LiteralPath $Directory -File -ErrorAction SilentlyContinue | Where-Object {
      $_.BaseName -eq ($base + $Suffix)
    } | Sort-Object Name)
  if ($matches.Count -gt 0) {
    return $matches[0].FullName
  }
  return $null
}

function New-ViewerData {
  param(
    [string]$Status,
    [object[]]$InputFiles,
    [hashtable]$CsvRows,
    [object]$PresetDefinition,
    [object]$Manifest,
    [string[]]$LogLines
  )

  $records = New-Object System.Collections.Generic.List[object]
  foreach ($file in $InputFiles) {
    $csvMatches = @()
    if ($CsvRows.ContainsKey($file.Name)) {
      $csvMatches = @($CsvRows[$file.Name])
    }
    $metrics = [ordered]@{}
    if ($csvMatches.Count -gt 0) {
      $metrics = Convert-ObjectToOrderedHash $csvMatches[0]
    }

    $segmentPath = Find-OutputImage -Directory $OutputRoot -InputFileName $file.Name -Suffix $segmentSuffix
    $featurePath = Find-OutputImage -Directory $OutputRoot -InputFileName $file.Name -Suffix $featureSuffix

    $records.Add([ordered]@{
        file_name = $file.Name
        original_path = $file.FullName
        original_url = Convert-ToFileUrl $file.FullName
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
        segment_image = $segmentPath
        segment_url = Convert-ToFileUrl $segmentPath
        feature_image = $featurePath
        feature_url = Convert-ToFileUrl $featurePath
        metrics = $metrics
        status = if ($csvMatches.Count -gt 0) { 'measured' } else { 'not-measured' }
      }) | Out-Null
  }

  return [ordered]@{
    schema_version = 1
    title = 'Root Measure 证据查看器'
    locale = 'zh-CN'
    status = $Status
    generated_at = (Get-Date).ToString('o')
    preset = $PresetDefinition
    comparison = [ordered]@{
      mode = 'measurement-only'
      status = 'not_compared_to_official_expected_rows'
      note = '本次运行未加载官方 expected CSV，因此 viewer 不做逐行官方对比；它展示本次测量结果、参数、工具链 hash 和该 preset 的外部验证证据。若要证明某个官方样本集逐行一致，需要运行官方复现/对比流程或后续的 expected CSV 对比模式。'
    }
    manifest = $Manifest
    warnings = @($warnings.ToArray())
    errors = @($errors.ToArray())
    images = @($records.ToArray())
    log_excerpt = @($LogLines | Select-Object -Last 80)
  }
}

function Write-JsonFile {
  param(
    [string]$Path,
    [object]$Value,
    [int]$Depth = 8
  )
  $Value | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Write-ViewerHtml {
  param(
    [string]$Path,
    [object]$ViewerData
  )
  $json = ($ViewerData | ConvertTo-Json -Depth 10) -replace '</', '<\/'
  $html = @'
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Root Measure 证据查看器</title>
  <style>
    :root {
      --paper: #f7f4ec;
      --ink: #17211c;
      --muted: #617066;
      --line: #d8d0c3;
      --panel: #fffdf7;
      --green: #1f6b52;
      --gold: #ad7b2a;
      --red: #9d332b;
      --shadow: rgba(23, 33, 28, 0.12);
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      color: var(--ink);
      background: var(--paper);
      font-family: "Aptos", "Segoe UI", sans-serif;
    }
    header {
      min-height: 104px;
      display: grid;
      grid-template-columns: minmax(0, 1fr) auto;
      gap: 24px;
      align-items: end;
      padding: 28px 32px 22px;
      border-bottom: 1px solid var(--line);
      background: linear-gradient(180deg, #fffdf7, #f2ecdf);
    }
    h1 {
      margin: 0 0 8px;
      font-family: Georgia, "Times New Roman", serif;
      font-size: clamp(28px, 4vw, 52px);
      font-weight: 700;
      letter-spacing: 0;
      line-height: 1.02;
    }
    .subtitle {
      color: var(--muted);
      max-width: 880px;
      line-height: 1.45;
    }
    .status {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 8px 12px;
      border: 1px solid var(--line);
      background: var(--panel);
      color: var(--green);
      font-weight: 700;
      white-space: nowrap;
    }
    .status.failed { color: var(--red); }
    main {
      height: calc(100vh - 105px);
      min-height: 620px;
      display: grid;
      grid-template-columns: 300px minmax(420px, 1fr) 360px;
    }
    aside, section {
      min-width: 0;
      min-height: 0;
    }
    .sample-list {
      border-right: 1px solid var(--line);
      background: #eee6d8;
      overflow: auto;
      padding: 16px;
    }
    .sample-button {
      width: 100%;
      display: grid;
      grid-template-columns: 1fr auto;
      gap: 8px;
      align-items: center;
      padding: 11px 10px;
      margin: 0 0 8px;
      border: 1px solid transparent;
      background: transparent;
      color: var(--ink);
      text-align: left;
      cursor: pointer;
      font: inherit;
    }
    .sample-button:hover, .sample-button.active {
      background: var(--panel);
      border-color: var(--line);
      box-shadow: 0 8px 18px var(--shadow);
    }
    .sample-name { overflow-wrap: anywhere; font-weight: 700; }
    .sample-state { color: var(--green); font-size: 12px; }
    .stage {
      display: grid;
      grid-template-rows: auto minmax(0, 1fr);
      background: var(--panel);
    }
    .tabs {
      display: flex;
      gap: 8px;
      padding: 14px 18px;
      border-bottom: 1px solid var(--line);
      overflow-x: auto;
    }
    .tab {
      padding: 9px 12px;
      border: 1px solid var(--line);
      background: #f5efe3;
      color: var(--ink);
      cursor: pointer;
      font-weight: 700;
      white-space: nowrap;
    }
    .tab.active {
      color: #fff;
      background: var(--green);
      border-color: var(--green);
    }
    .view {
      overflow: auto;
      padding: 20px;
    }
    .image-frame {
      width: 100%;
      min-height: 420px;
      display: grid;
      place-items: center;
      border: 1px solid var(--line);
      background:
        linear-gradient(45deg, rgba(23,33,28,.035) 25%, transparent 25%),
        linear-gradient(-45deg, rgba(23,33,28,.035) 25%, transparent 25%),
        linear-gradient(45deg, transparent 75%, rgba(23,33,28,.035) 75%),
        linear-gradient(-45deg, transparent 75%, rgba(23,33,28,.035) 75%);
      background-size: 22px 22px;
      background-position: 0 0, 0 11px, 11px -11px, -11px 0;
    }
    .image-frame img {
      max-width: 100%;
      max-height: calc(100vh - 230px);
      object-fit: contain;
    }
    .missing {
      padding: 24px;
      color: var(--muted);
      text-align: center;
      max-width: 460px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
    }
    th, td {
      padding: 8px 10px;
      border-bottom: 1px solid var(--line);
      vertical-align: top;
    }
    th {
      text-align: left;
      color: var(--muted);
      font-weight: 700;
      width: 44%;
    }
    .evidence {
      border-left: 1px solid var(--line);
      background: #f4eddf;
      overflow: auto;
      padding: 18px;
    }
    .panel {
      border: 1px solid var(--line);
      background: var(--panel);
      padding: 14px;
      margin: 0 0 14px;
    }
    .panel h2 {
      margin: 0 0 10px;
      font-size: 15px;
      letter-spacing: 0;
    }
    .kv {
      display: grid;
      grid-template-columns: 110px minmax(0, 1fr);
      gap: 8px;
      font-size: 12px;
      line-height: 1.35;
    }
    .kv div:nth-child(odd) {
      color: var(--muted);
      font-weight: 700;
    }
    code, .mono {
      font-family: "Cascadia Mono", Consolas, monospace;
      font-size: 12px;
      overflow-wrap: anywhere;
    }
    .warning {
      color: var(--gold);
      font-weight: 700;
    }
    .error {
      color: var(--red);
      font-weight: 700;
    }
    pre {
      margin: 0;
      white-space: pre-wrap;
      overflow-wrap: anywhere;
      font: 12px/1.45 "Cascadia Mono", Consolas, monospace;
      color: #2c352f;
    }
    @media (max-width: 1050px) {
      main {
        height: auto;
        grid-template-columns: 1fr;
      }
      .sample-list, .evidence {
        border: 0;
        border-bottom: 1px solid var(--line);
      }
      .sample-list {
        max-height: 260px;
      }
      header {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>
<body>
  <header>
    <div>
      <h1>Root Measure 证据查看器</h1>
      <div class="subtitle" id="subtitle">透明测量运行：原图、中间图、指标、参数和验证证据放在同一处。</div>
    </div>
    <div class="status" id="runStatus">正在加载</div>
  </header>
  <main>
    <aside class="sample-list" id="sampleList"></aside>
    <section class="stage">
      <nav class="tabs" id="tabs"></nav>
      <div class="view" id="view"></div>
    </section>
    <aside class="evidence" id="evidence"></aside>
  </main>
  <script id="embedded-viewer-data" type="application/json">__VIEWER_DATA__</script>
  <script>
    const embeddedData = JSON.parse(document.getElementById('embedded-viewer-data').textContent);
    const state = { data: embeddedData, index: 0, tab: 'original' };
    const tabs = [
      ['original', '原图'],
      ['segment', '分割图'],
      ['feature', '特征叠加图'],
      ['metrics', '指标']
    ];
    fetch('viewer-data.json')
      .then(response => response.ok ? response.json() : embeddedData)
      .then(data => { state.data = data; render(); })
      .catch(() => render());

    function render() {
      const data = state.data;
      document.getElementById('runStatus').textContent = data.status === 'success' ? '运行完成' : '需要检查';
      document.getElementById('runStatus').className = 'status ' + (data.status === 'success' ? '' : 'failed');
      document.getElementById('subtitle').textContent = (data.preset && data.preset.trust_note) || '透明根系测量运行。';
      renderList();
      renderTabs();
      renderView();
      renderEvidence();
    }

    function renderList() {
      const list = document.getElementById('sampleList');
      list.innerHTML = '';
      const images = state.data.images || [];
      if (!images.length) {
        list.innerHTML = '<div class="missing">没有生成图片记录。请查看右侧运行证据和错误信息。</div>';
        return;
      }
      images.forEach((image, index) => {
        const button = document.createElement('button');
        button.className = 'sample-button' + (index === state.index ? ' active' : '');
        button.innerHTML = '<span class="sample-name"></span><span class="sample-state"></span>';
        button.querySelector('.sample-name').textContent = image.file_name || '图像';
        button.querySelector('.sample-state').textContent = imageStatusLabel(image.status);
        button.addEventListener('click', () => { state.index = index; render(); });
        list.appendChild(button);
      });
    }

    function renderTabs() {
      const tabBar = document.getElementById('tabs');
      tabBar.innerHTML = '';
      tabs.forEach(([key, label]) => {
        const button = document.createElement('button');
        button.className = 'tab' + (key === state.tab ? ' active' : '');
        button.textContent = label;
        button.addEventListener('click', () => { state.tab = key; renderView(); renderTabs(); });
        tabBar.appendChild(button);
      });
    }

    function currentImage() {
      const images = state.data.images || [];
      return images[state.index] || null;
    }

    function renderView() {
      const view = document.getElementById('view');
      const image = currentImage();
      if (!image) {
        view.innerHTML = '<div class="missing">尚未选择图像。</div>';
        return;
      }
      if (state.tab === 'metrics') {
        renderMetrics(view, image.metrics || {});
        return;
      }
      const url = state.tab === 'segment' ? image.segment_url : state.tab === 'feature' ? image.feature_url : image.original_url;
      const label = state.tab === 'segment' ? '分割图' : state.tab === 'feature' ? '特征叠加图' : '原图';
      if (!url) {
        view.innerHTML = '<div class="image-frame"><div class="missing">这个样本没有生成' + label + '。</div></div>';
        return;
      }
      view.innerHTML = '<div class="image-frame"><img alt=""></div><p class="mono"></p>';
      const img = view.querySelector('img');
      img.alt = image.file_name + ' ' + label;
      img.src = url;
      view.querySelector('p').textContent = state.tab === 'segment' ? image.segment_image : state.tab === 'feature' ? image.feature_image : image.original_path;
    }

    function renderMetrics(container, metrics) {
      const preferred = [
        'File.Name', 'Region.of.Interest', 'Number.of.Root.Tips', 'Number.of.Branch.Points',
        'Total.Root.Length.mm', 'Depth.mm', 'Maximum.Width.mm', 'Network.Area.mm2',
        'Average.Diameter.mm', 'Median.Diameter.mm', 'Maximum.Diameter.mm',
        'Average.Root.Orientation.deg', 'Shallow.Angle.Frequency',
        'Medium.Angle.Frequency', 'Steep.Angle.Frequency', 'Computation.Time.s'
      ];
      const keys = Object.keys(metrics);
      const ordered = preferred.filter(k => keys.includes(k)).concat(keys.filter(k => !preferred.includes(k)));
      if (!ordered.length) {
        container.innerHTML = '<div class="missing">这个样本没有找到指标行。</div>';
        return;
      }
      const table = document.createElement('table');
      const body = document.createElement('tbody');
      ordered.forEach(key => {
        const row = document.createElement('tr');
        const th = document.createElement('th');
        const td = document.createElement('td');
        th.textContent = key;
        td.textContent = metrics[key];
        row.appendChild(th);
        row.appendChild(td);
        body.appendChild(row);
      });
      table.appendChild(body);
      container.innerHTML = '';
      container.appendChild(table);
    }

    function renderEvidence() {
      const data = state.data;
      const manifest = data.manifest || {};
      const preset = data.preset || {};
      const comparison = data.comparison || {};
      const evidence = document.getElementById('evidence');
      const validation = (preset.evidence || []).map(item =>
        '<p><strong>' + escapeHtml(item.label || '证据') + '</strong><br><span>' +
        escapeHtml(item.result || '') + '</span><br><code>' + escapeHtml(item.report || '') + '</code></p>'
      ).join('');
      const warnings = (data.warnings || []).map(w => '<p class="warning">' + escapeHtml(w) + '</p>').join('');
      const errors = (data.errors || []).map(e => '<p class="error">' + escapeHtml(e) + '</p>').join('');
      evidence.innerHTML =
        '<div class="panel"><h2>运行证据</h2><div class="kv">' +
        kv('状态', statusLabel(data.status)) +
        kv('Preset', preset.name) +
        kv('验证状态', validationLabel(preset.validation_status)) +
        kv('开始时间', manifest.started_at) +
        kv('结束时间', manifest.finished_at) +
        kv('退出码', manifest.exit_code) +
        '</div></div>' +
        '<div class="panel"><h2>工具链</h2><div class="kv">' +
        kv('rv.exe', manifest.toolchain && manifest.toolchain.rv ? manifest.toolchain.rv.sha256 : '') +
        kv('cvutil.dll', manifest.toolchain && manifest.toolchain.cvutil ? manifest.toolchain.cvutil.sha256 : '') +
        '</div></div>' +
        '<div class="panel"><h2>官方一致性说明</h2><div class="kv">' +
        kv('模式', comparison.mode || '') +
        kv('对比状态', comparisonStatusLabel(comparison.status)) +
        '</div><p>' + escapeHtml(comparison.note || '本次运行没有记录官方 expected 表对比信息。') + '</p></div>' +
        '<div class="panel"><h2>参数</h2><pre>' + escapeHtml(JSON.stringify(manifest.parameters || {}, null, 2)) + '</pre></div>' +
        '<div class="panel"><h2>验证证据</h2>' + (validation || '<p>这个 preset 没有关联的官方验证证据。</p>') + '</div>' +
        '<div class="panel"><h2>警告和错误</h2>' + (warnings || '') + (errors || '<p>没有记录运行错误。</p>') + '</div>' +
        '<div class="panel"><h2>日志摘录</h2><pre>' + escapeHtml((data.log_excerpt || []).join('\\n')) + '</pre></div>';
    }

    function kv(label, value) {
      return '<div>' + escapeHtml(label) + '</div><div class="mono">' + escapeHtml(value == null ? '' : String(value)) + '</div>';
    }

    function statusLabel(value) {
      return value === 'success' ? '成功' : value === 'failed' ? '失败' : (value || '');
    }

    function validationLabel(value) {
      return value === 'validated' ? '已验证 preset' : value === 'unvalidated' ? '未验证参数组合' : (value || '');
    }

    function imageStatusLabel(value) {
      return value === 'measured' ? '已测量' : value === 'not-measured' ? '未测量' : (value || '');
    }

    function comparisonStatusLabel(value) {
      return value === 'not_compared_to_official_expected_rows' ? '未加载官方 expected 表逐行对比' : (value || '');
    }

    function escapeHtml(value) {
      return String(value == null ? '' : value)
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
    }
  </script>
</body>
</html>
'@
  $html = $html.Replace('__VIEWER_DATA__', $json)
  Set-Content -LiteralPath $Path -Value $html -Encoding UTF8
}

function New-RunManifest {
  param(
    [string]$Status,
    [object[]]$InputFiles,
    [object]$PresetDefinition,
    [string[]]$Arguments,
    [int]$ExitCode
  )

  $inputRecords = foreach ($file in $InputFiles) {
    [ordered]@{
      name = $file.Name
      path = $file.FullName
      sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
      size_bytes = $file.Length
    }
  }

  $rvHash = if (Test-Path -LiteralPath $rv) { (Get-FileHash -Algorithm SHA256 -LiteralPath $rv).Hash } else { $null }
  $cvutilHash = if (Test-Path -LiteralPath $cvutil) { (Get-FileHash -Algorithm SHA256 -LiteralPath $cvutil).Hash } else { $null }

  return [ordered]@{
    schema_version = 1
    command = 'measure'
    status = $Status
    started_at = $startedAt.ToString('o')
    finished_at = (Get-Date).ToString('o')
    exit_code = $ExitCode
    project_root = $projectRoot
    input = [ordered]@{
      path = $InputPath
      files = @($inputRecords)
    }
    output_root = [System.IO.Path]::GetFullPath($OutputRoot)
    preset = $PresetDefinition.name
    parameters = [ordered]@{
      preset = $PresetDefinition.name
      root_type = $PresetDefinition.root_type
      threshold = $PresetDefinition.threshold
      invert = $PresetDefinition.invert
      bgnoise = $PresetDefinition.bgnoise
      bgsize = $PresetDefinition.bgsize
      fgnoise = $PresetDefinition.fgnoise
      fgsize = $PresetDefinition.fgsize
      smooth = $PresetDefinition.smooth
      smooththreshold = $PresetDefinition.smooththreshold
      prune = $PresetDefinition.prune
      prunethreshold = $PresetDefinition.prunethreshold
      dranges = $PresetDefinition.dranges
      dpi = if ($Dpi -gt 0) { $Dpi } else { $null }
      pixels_per_mm = if ($PixelsPerMm -gt 0) { $PixelsPerMm } else { $null }
      segment_images = -not $NoSegmentImages.IsPresent
      feature_images = -not $NoFeatureImages.IsPresent
      segment_suffix = $segmentSuffix
      feature_suffix = $featureSuffix
      rv_args = @($Arguments)
    }
    toolchain = [ordered]@{
      rv = [ordered]@{
        path = $rv
        sha256 = $rvHash
      }
      cvutil = [ordered]@{
        path = $cvutil
        sha256 = $cvutilHash
      }
      record = $toolchainRecord
    }
    artifacts = [ordered]@{
      features_csv = $featuresCsv
      stdout = $stdoutPath
      stderr = $stderrPath
      rv_log = Join-Path $OutputRoot 'rv.log'
      viewer_data = $viewerDataPath
      viewer_html = if ($NoViewer.IsPresent) { $null } else { $viewerHtmlPath }
    }
    comparison = [ordered]@{
      mode = 'measurement-only'
      status = 'not_compared_to_official_expected_rows'
      note = '本次运行未加载官方 expected CSV，因此不做逐行官方对比；官方一致性证据见 validation_evidence。'
    }
    validation_evidence = @($PresetDefinition.evidence)
    warnings = @($warnings.ToArray())
    errors = @($errors.ToArray())
  }
}

if ($Dpi -gt 0 -and $PixelsPerMm -gt 0) {
  throw 'Specify either -Dpi or -PixelsPerMm, not both.'
}

$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
New-Item -ItemType Directory -Force -Path $resolvedOutputRoot | Out-Null
$OutputRoot = $resolvedOutputRoot
$featuresCsv = Join-Path $OutputRoot 'features.csv'
$stdoutPath = Join-Path $OutputRoot 'rv.stdout.txt'
$stderrPath = Join-Path $OutputRoot 'rv.stderr.txt'
$manifestPath = Join-Path $OutputRoot 'run_manifest.json'
$viewerDataPath = Join-Path $OutputRoot 'viewer-data.json'
$viewerHtmlPath = Join-Path $OutputRoot 'viewer.html'

$inputFiles = @()
$presetDefinition = Get-PresetDefinition $Preset
if ($Preset -eq 'custom') {
  $warnings.Add('自定义 preset 不是已验证的官方 exact-reproduction preset。') | Out-Null
}

try {
  if (-not (Test-Path -LiteralPath $rv)) {
    throw "Private rv executable not found: $rv"
  }
  $inputFiles = @(Get-SupportedImageFiles $InputPath)
  $resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path

  $rvArgs = @(
    '-na',
    '-v',
    '-op', $OutputRoot,
    '-o', 'features.csv',
    '-rt', $presetDefinition.roottype_arg,
    '-t', ([string]$presetDefinition.threshold)
  )
  if ($presetDefinition.invert) {
    $rvArgs += '-i'
  }
  if ($presetDefinition.bgnoise) {
    $rvArgs += '--bgnoise'
  }
  if ($null -ne $presetDefinition.bgsize) {
    $rvArgs += @('--bgsize', ([string]$presetDefinition.bgsize))
  }
  if ($presetDefinition.fgnoise) {
    $rvArgs += '--fgnoise'
  }
  if ($null -ne $presetDefinition.fgsize) {
    $rvArgs += @('--fgsize', ([string]$presetDefinition.fgsize))
  }
  if ($presetDefinition.smooth) {
    $rvArgs += '-s'
  }
  if ($null -ne $presetDefinition.smooththreshold) {
    $rvArgs += @('-st', ([string]$presetDefinition.smooththreshold))
  }
  if ($presetDefinition.prune) {
    $rvArgs += '--prune'
  }
  if ($null -ne $presetDefinition.prunethreshold) {
    $rvArgs += @('-pt', ([string]$presetDefinition.prunethreshold))
  }
  if (-not $NoSegmentImages.IsPresent) {
    $rvArgs += @('--segment', '--ssuffix', $segmentSuffix)
  }
  if (-not $NoFeatureImages.IsPresent) {
    $rvArgs += @('--feature', '--fsuffix', $featureSuffix)
  }
  if ($Dpi -gt 0) {
    $rvArgs += @('--convert', '--factordpi', ([string]$Dpi))
  } elseif ($PixelsPerMm -gt 0) {
    $rvArgs += @('--convert', '--factorpixels', ([string]$PixelsPerMm))
  }
  if ($presetDefinition.dranges) {
    $rvArgs += @('--dranges', $presetDefinition.dranges)
  }
  $rvArgs += $resolvedInput

  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $rv
  $psi.Arguments = Convert-ToProcessArgumentString $rvArgs
  $psi.WorkingDirectory = $projectRoot
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true

  $proc = [System.Diagnostics.Process]::new()
  $proc.StartInfo = $psi
  [void]$proc.Start()
  $stdout = $proc.StandardOutput.ReadToEnd()
  $stderr = $proc.StandardError.ReadToEnd()
  $proc.WaitForExit()
  $rvExitCode = $proc.ExitCode
  Set-Content -LiteralPath $stdoutPath -Value $stdout -Encoding UTF8
  Set-Content -LiteralPath $stderrPath -Value $stderr -Encoding UTF8
  if ($rvExitCode -ne 0) {
    $errors.Add("rv.exe exited with code $rvExitCode") | Out-Null
  }
} catch {
  $rvExitCode = 1
  $errors.Add($_.Exception.Message) | Out-Null
  if (-not (Test-Path -LiteralPath $stdoutPath)) {
    Set-Content -LiteralPath $stdoutPath -Value '' -Encoding UTF8
  }
  if (-not (Test-Path -LiteralPath $stderrPath)) {
    Set-Content -LiteralPath $stderrPath -Value ($_.Exception.Message) -Encoding UTF8
  }
}

$status = if ($rvExitCode -eq 0 -and $errors.Count -eq 0) { 'success' } else { 'failed' }
$csvRows = Read-CsvRowsByFileName $featuresCsv
$stdoutLines = if (Test-Path -LiteralPath $stdoutPath) { @(Get-Content -LiteralPath $stdoutPath -ErrorAction SilentlyContinue) } else { @() }
$stderrLines = if (Test-Path -LiteralPath $stderrPath) { @(Get-Content -LiteralPath $stderrPath -ErrorAction SilentlyContinue) } else { @() }
$rvLogPath = Join-Path $OutputRoot 'rv.log'
$rvLogLines = if (Test-Path -LiteralPath $rvLogPath) { @(Get-Content -LiteralPath $rvLogPath -ErrorAction SilentlyContinue) } else { @() }
$logLines = @($stdoutLines + $stderrLines + $rvLogLines)

$manifest = New-RunManifest -Status $status -InputFiles $inputFiles -PresetDefinition $presetDefinition -Arguments $rvArgs -ExitCode $rvExitCode
$viewerData = New-ViewerData -Status $status -InputFiles $inputFiles -CsvRows $csvRows -PresetDefinition $presetDefinition -Manifest $manifest -LogLines $logLines

Write-JsonFile -Path $manifestPath -Value $manifest -Depth 10
Write-JsonFile -Path $viewerDataPath -Value $viewerData -Depth 12
if (-not $NoViewer.IsPresent) {
  Write-ViewerHtml -Path $viewerHtmlPath -ViewerData $viewerData
}

if ($status -eq 'success') {
  Write-Host "features=$featuresCsv"
  Write-Host "manifest=$manifestPath"
  Write-Host "viewer_data=$viewerDataPath"
  if (-not $NoViewer.IsPresent) {
    Write-Host "viewer=$viewerHtmlPath"
  }
  exit 0
}

Write-Error (($errors | Select-Object -First 1) -join "`n")
exit 1
