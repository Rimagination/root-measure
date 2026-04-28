# Root Measure

Root Measure is a Codex plugin for root image measurement. It wraps a validated
RhizoVision Explorer CLI workflow with guided setup, install checks, transparent
run artifacts, and optional expected-CSV comparison.

Root Measure 是一个用于根系图像测量的 Codex 插件。它把经过验证的
RhizoVision Explorer CLI 工作流包装成更容易使用的安装检查、分析向导、结果证据包和
可选的 expected CSV 对比流程。

![Root Measure product workflow](assets/root-measure-product-infographic.png)

## What It Does / 它能做什么

- Measures broken-root scans and whole-root/crown style images through
  RhizoVision Explorer CLI.
- 通过 RhizoVision Explorer CLI 测量 broken-root 扫描图和 whole-root/crown
  类型图像。
- Keeps the evidence: `features.csv`, `viewer.html`, `run_manifest.json`,
  logs, segmentation images, and feature overlays.
- 保留可追溯证据：`features.csv`、`viewer.html`、`run_manifest.json`、日志、
  分割图和 feature overlay。
- Helps Codex ask for the minimum required inputs: image path, root type, and
  scale (`DPI` or `pixels/mm`) when physical units are needed.
- 帮 Codex 只询问必要信息：图像路径、根系类型，以及需要物理单位时的尺度
  (`DPI` 或 `pixels/mm`)。
- Supports public-data reproduction when you provide images, parameters, and an
  official or previous expected CSV.
- 在你提供图像、参数和官方或历史 expected CSV 时，支持公开数据集复现。
- Preserves full advanced control through `root-measure raw -- <rv.exe args>`.
- 通过 `root-measure raw -- <rv.exe args>` 保留完整高级参数能力。

## Install / 安装

For most Codex Desktop users, the simplest path is to ask Codex:

对大多数 Codex Desktop 用户，最简单的方式是直接告诉 Codex：

```text
Install this Codex plugin and verify it with release-check:
https://github.com/Rimagination/root-measure
```

```text
请安装这个 Codex 插件，并用 release-check 验证：
https://github.com/Rimagination/root-measure
```

After installation, ask Codex to run:

安装后，让 Codex 运行：

```powershell
<plugin-root>\bin\root-measure.cmd release-check
```

A good install reports `status: pass`.

安装成功时应看到 `status: pass`。

Installation is the most technical part of this plugin. If Codex Desktop shows a
generic "plugin install failed" toast, see
[docs/installation.md](docs/installation.md). That guide covers local marketplace
layout, the real Codex plugin cache path, strict UTF-8 manifest files, and the
BOM issue that can make a valid-looking `plugin.json` fail inside Codex.

安装是这个插件最容易踩坑的部分。如果 Codex Desktop 只弹出笼统的“插件安装失败”，
请看 [docs/installation.md](docs/installation.md)。那里写了 local marketplace
目录、Codex 真实插件缓存路径、严格 UTF-8 manifest，以及会导致 `plugin.json`
看起来正常但 Codex 解析失败的 BOM 问题。

## First Run / 第一次运行

Natural language is the preferred interface:

推荐直接用自然语言：

```text
Use Root Measure to analyze D:\data\scans. The scan scale is 600 DPI.
```

```text
帮我用 Root Measure 分析 D:\data\scans，扫描尺度是 600 DPI。
```

If you are unsure which settings to use:

如果不确定参数：

```text
Start the Root Measure guided workflow.
```

```text
启动 Root Measure 分析向导。
```

Command-line equivalents:

等价命令：

```powershell
<plugin-root>\bin\root-measure.cmd wizard
<plugin-root>\bin\root-measure.cmd measure --input D:\data\scans --dpi 600 --preset broken-roots
<plugin-root>\bin\root-measure.cmd measure --input D:\data\roots --pixels-per-mm 13.27 --preset whole-root
```

For your own new data, you usually do not have an expected CSV. Root Measure will
focus on measurement and quality control: image count, scale, exact command
arguments, output rows, generated viewer, intermediate images, and logs.

分析自己的新数据时，通常没有 expected CSV。Root Measure 默认做测量和质控：
图像数量、尺度、真实命令参数、结果行数、viewer、中间图和日志。

## Outputs / 输出

Each high-level run writes a run folder, usually under the Root Measure backend
project's `runs` directory.

每次高层分析都会生成一个结果目录，通常位于 Root Measure 后端项目的 `runs` 目录。

Important files:

重要文件：

- `features.csv`: measurement table / 测量结果表
- `viewer.html`: local review page / 本地结果查看页
- `viewer-data.json`: data used by the viewer / viewer 使用的数据
- `run_manifest.json`: inputs, parameters, tool hashes, and artifacts / 输入、参数、
  工具 hash 和产物记录
- `rv.stdout.txt`, `rv.stderr.txt`, `rv.log`: execution logs / 运行日志
- segmentation and feature overlay images / 分割图和特征叠加图

Useful commands:

常用命令：

```powershell
<plugin-root>\bin\root-measure.cmd runs --limit 10
<plugin-root>\bin\root-measure.cmd inspect --run <run-folder>
<plugin-root>\bin\root-measure.cmd doctor
```

## Public Reproduction / 公开数据复现

Use reproduction mode only when you have an expected CSV or a previous baseline.
Root Measure can compare generated `features.csv` to expected results and report
exact matches or differences.

只有在你有 expected CSV 或历史 baseline 时，才进入复现/对比流程。Root Measure 可以把
生成的 `features.csv` 和 expected 结果对比，并报告 exact 或差异。

```powershell
<plugin-root>\bin\root-measure.cmd compare --actual <features.csv> --expected <expected.csv> --key File.Name
```

If expected rows contain duplicate `File.Name` values:

如果 expected 表里有重复的 `File.Name`：

```powershell
<plugin-root>\bin\root-measure.cmd compare --actual <features.csv> --expected <expected.csv> --key File.Name --duplicate-key-mode BestMatch
```

The GitHub `imageexamples` are smoke tests, not numeric oracles. Do not claim
official agreement unless `compare` has checked the generated table against the
expected CSV.

GitHub `imageexamples` 适合 smoke test，不是数值标准答案。只有 `compare`
真正对比过 expected CSV 后，才应声明“和官方结果一致”。

More details: [docs/reproducibility.md](docs/reproducibility.md).

更多说明见：[docs/reproducibility.md](docs/reproducibility.md)。

## Troubleshooting / 排错

Start with:

先运行：

```powershell
<plugin-root>\bin\root-measure.cmd doctor
<plugin-root>\bin\root-measure.cmd release-check
```

Common problems:

常见问题：

- Missing scale: provide `DPI` or `pixels/mm` before interpreting mm, mm2, or mm3.
- 缺少尺度：解释 mm、mm2、mm3 等物理单位前，必须提供 `DPI` 或 `pixels/mm`。
- Install failure: check strict UTF-8 without BOM and the Codex cache layout in
  [docs/installation.md](docs/installation.md).
- 安装失败：检查无 BOM 的严格 UTF-8，以及 [docs/installation.md](docs/installation.md)
  中的 Codex cache 结构。
- Toolchain hash mismatch: treat results as a new baseline until re-compared.
- 工具链 hash 不一致：在重新对比前，不要沿用旧验证结论。
- Unexpected row count: check input folder, recursion, failed images, and append
  settings.
- 行数不对：检查输入目录、递归、失败图像和 append 设置。
- Public result mismatch: check parameters, scale, threshold, duplicate keys, and
  volatile columns such as `Computation.Time.s`.
- 公开结果不一致：检查参数、尺度、threshold、重复 key，以及
  `Computation.Time.s` 这类易变列。

## Documentation / 文档

- [docs/installation.md](docs/installation.md): Codex installation and known
  install pitfalls / Codex 安装与常见安装坑
- [docs/usage.md](docs/usage.md): everyday measurement workflow / 日常分析流程
- [docs/reproducibility.md](docs/reproducibility.md): expected CSV comparison and
  public-data reproduction / expected CSV 对比与公开数据复现
- [docs/reproducibility-gotchas.md](docs/reproducibility-gotchas.md): detailed
  validation pitfalls / 详细验证踩坑记录

## References / 参考资料

- RhizoVision Explorer: https://www.rhizovision.com/
- RhizoVision Explorer GitHub:
  https://github.com/predictivephenomics/RhizoVisionExplorer
- Seethepalli, A. et al. (2021). RhizoVision Explorer: open-source software for
  root image analysis and measurement standardization. AoB PLANTS, 13(6), plab056.
  https://doi.org/10.1093/aobpla/plab056
- RhizoVision Explorer Zenodo release: https://doi.org/10.5281/zenodo.3747697
