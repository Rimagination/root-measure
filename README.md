# root-measure

Root Measure 是一个面向 Codex 的根系图像测量插件。它把经过验证的
RhizoVision Explorer CLI 工作流包装成可由 agent 调用、可安装检查、可复现、
并且能保留完整运行证据的分析流程。

这个仓库包含 Codex 插件清单、Root Measure 技能、统一命令入口、安装诊断、
用户文档和发布检查脚本。当前版本：`0.2.0-beta`。

![Root Measure product workflow](assets/root-measure-product-infographic.png)

<a id="chinese"></a>

中文 | [English](#english)

---

## 中文

### 这是什么

`root-measure` 面向这样一句话请求：

```text
Use Root Measure to analyze this folder of root images. The scan scale is 600 DPI.
```

它保留 RhizoVision Explorer 的方法核心不变：

- RhizoVision Explorer CLI 仍然是测量引擎
- Codex 插件负责安装发现、参数引导、运行证据整理和排错
- 统一 CLI 让 agent 和高级用户都能稳定调用
- `raw --` 模式保留完整 `rv.exe` 原始参数能力

### 能测什么

Root Measure 会根据 RVE 输出生成 `features.csv`。实际列取决于图像类型、
尺度和 CLI 参数，常见指标包括：

- 根长、表面积、投影面积和体积
- 根尖数、分枝点数和分枝频率
- 平均直径、中位直径和最大直径
- 按直径范围分箱的长度、面积、表面积和体积
- 运行诊断信息，例如文件名、ROI 和计算耗时

注意：`Computation.Time.s` 是运行耗时，不是生物学性状。解释 mm、mm2、
mm3 等物理单位前，必须提供正确的 `DPI` 或 `pixels/mm`。

### 两种常用分析模式

- `Broken-root mode`
  - 用于洗净后铺开的断根、根段或散根扫描图
  - 适合高对比度白底扫描图
  - 重点输出长度、直径、面积、体积和拓扑指标
- `Crown mode`
  - 用于完整根系、根冠或 seedling crown 图像
  - 适合保留整体结构的样本
  - 重点保留根系构型相关输出和可视化证据

如果高层 `measure` 命令还没有覆盖某个 RVE 参数，可以使用：

```powershell
<plugin-root>\bin\root-measure.cmd raw -- <rv.exe arguments>
```

### 给 Agent 用户

如果你平时就是对 Codex 说一句话来完成安装和分析，推荐这样使用。

#### 最快路径：从 GitHub 安装插件

让 Codex 执行：

```text
Install this Codex plugin and verify it with release-check:
https://github.com/Rimagination/root-measure
```

安装后请运行：

```powershell
<plugin-root>\bin\root-measure.cmd release-check
```

通过时会看到 `status: pass`。

安装是这个插件最技术化、也最容易踩坑的部分。如果 Codex Desktop 只弹出笼统的
“插件安装失败”，请看 [docs/installation.md](docs/installation.md)。那里记录了
local marketplace 目录、真实 Codex 插件缓存路径、严格 UTF-8 manifest，以及会导致
`plugin.json` 看起来正常但 Codex 解析失败的 BOM 问题。

#### 第一次分析自己的数据

可以直接对 Codex 说：

```text
Use Root Measure to analyze D:\data\scans. The scan scale is 600 DPI.
```

或者：

```text
帮我用 Root Measure 分析 D:\data\scans，扫描尺度是 600 DPI。
```

如果不确定参数：

```text
Start the Root Measure guided workflow.
```

等价命令：

```powershell
<plugin-root>\bin\root-measure.cmd wizard
<plugin-root>\bin\root-measure.cmd measure --input D:\data\scans --dpi 600 --preset broken-roots
<plugin-root>\bin\root-measure.cmd measure --input D:\data\roots --pixels-per-mm 13.27 --preset whole-root
```

分析自己的新数据时，通常没有 expected CSV。Root Measure 默认做测量和质控：
图像数量、尺度、真实命令参数、结果行数、viewer、中间图和日志。

### 输出内容

每次高层分析都会生成一个结果目录，通常位于 Root Measure 后端项目的 `runs`
目录。重要文件包括：

- `features.csv`：测量结果表
- `viewer.html`：本地结果查看页
- `viewer-data.json`：viewer 使用的数据
- `run_manifest.json`：输入、参数、工具 hash 和产物记录
- `rv.stdout.txt`、`rv.stderr.txt`、`rv.log`：运行日志
- segmentation 和 feature overlay 图像

常用检查命令：

```powershell
<plugin-root>\bin\root-measure.cmd runs --limit 10
<plugin-root>\bin\root-measure.cmd inspect --run <run-folder>
<plugin-root>\bin\root-measure.cmd doctor
```

### 公开数据复现

只有在你有 expected CSV 或历史 baseline 时，才进入复现/对比流程。Root Measure
可以把生成的 `features.csv` 和 expected 结果对比，并报告 exact 或差异。

```powershell
<plugin-root>\bin\root-measure.cmd compare --actual <features.csv> --expected <expected.csv> --key File.Name
```

如果 expected 表里有重复的 `File.Name`：

```powershell
<plugin-root>\bin\root-measure.cmd compare --actual <features.csv> --expected <expected.csv> --key File.Name --duplicate-key-mode BestMatch
```

GitHub `imageexamples` 适合 smoke test，不是数值标准答案。只有 `compare` 真正对比过
expected CSV 后，才应声明“和官方结果一致”。

更多说明见 [docs/reproducibility.md](docs/reproducibility.md)。

### 文档

- [docs/installation.md](docs/installation.md)：Codex 安装与常见安装坑
- [docs/usage.md](docs/usage.md)：日常分析流程
- [docs/reproducibility.md](docs/reproducibility.md)：expected CSV 对比与公开数据复现
- [docs/reproducibility-gotchas.md](docs/reproducibility-gotchas.md)：详细验证踩坑记录

### 参考资料

- RhizoVision Explorer：https://www.rhizovision.com/
- RhizoVision Explorer GitHub：https://github.com/predictivephenomics/RhizoVisionExplorer
- Seethepalli, A. et al. (2021). RhizoVision Explorer: open-source software for
  root image analysis and measurement standardization. AoB PLANTS, 13(6), plab056.
  https://doi.org/10.1093/aobpla/plab056
- RhizoVision Explorer Zenodo release：https://doi.org/10.5281/zenodo.3747697

---

<a id="english"></a>

[中文](#chinese) | English

## English

### Overview

`root-measure` is built for a request like:

```text
Use Root Measure to analyze this folder of root images. The scan scale is 600 DPI.
```

It keeps the scientific core fixed:

- RhizoVision Explorer CLI remains the measurement engine
- the Codex plugin handles install discovery, parameter guidance, run evidence,
  and troubleshooting
- a unified CLI gives agents and advanced users a stable interface
- `raw --` preserves full passthrough access to `rv.exe` arguments

### Traits

Root Measure writes `features.csv` from the RVE output. The exact columns depend
on image type, scale, and CLI parameters. Common outputs include:

- root length, surface area, projected area, and volume
- root tips, branch points, and branching frequency
- average, median, and maximum diameter
- diameter-binned length, area, surface area, and volume
- run diagnostics such as file name, ROI, and computation time

Note: `Computation.Time.s` is runtime, not a biological trait. Provide correct
`DPI` or `pixels/mm` before interpreting mm, mm2, or mm3 as physical units.

### Common Analysis Modes

- `Broken-root mode`
  - for washed, separated broken roots or root fragments on scans
  - best for high-contrast white-background scanner images
  - focuses on length, diameter, area, volume, and topology traits
- `Crown mode`
  - for intact root systems, crowns, or seedling crown images
  - best when the whole architecture should stay visible
  - keeps architecture-oriented outputs and visual evidence

If the high-level `measure` command does not expose a specific RVE argument, use:

```powershell
<plugin-root>\bin\root-measure.cmd raw -- <rv.exe arguments>
```

### For Agent Users

If you normally install and use projects by telling Codex what to do, use this
repository that way.

#### Quick Install From GitHub

Ask Codex:

```text
Install this Codex plugin and verify it with release-check:
https://github.com/Rimagination/root-measure
```

After installation, run:

```powershell
<plugin-root>\bin\root-measure.cmd release-check
```

A good install reports `status: pass`.

Installation is the most technical part of this plugin. If Codex Desktop only
shows a generic "plugin install failed" toast, see
[docs/installation.md](docs/installation.md). It covers the local marketplace
layout, the real Codex plugin cache path, strict UTF-8 manifest files, and the
BOM issue that can make a valid-looking `plugin.json` fail inside Codex.

#### First Run On Your Own Data

You can ask Codex:

```text
Use Root Measure to analyze D:\data\scans. The scan scale is 600 DPI.
```

If you are unsure which settings to use:

```text
Start the Root Measure guided workflow.
```

Equivalent commands:

```powershell
<plugin-root>\bin\root-measure.cmd wizard
<plugin-root>\bin\root-measure.cmd measure --input D:\data\scans --dpi 600 --preset broken-roots
<plugin-root>\bin\root-measure.cmd measure --input D:\data\roots --pixels-per-mm 13.27 --preset whole-root
```

For new user data, you usually do not have an expected CSV. Root Measure focuses
on measurement and quality control: image count, scale, exact command arguments,
output rows, generated viewer, intermediate images, and logs.

### Outputs

Each high-level run writes a run folder, usually under the Root Measure backend
project's `runs` directory. Important files include:

- `features.csv`: measurement table
- `viewer.html`: local review page
- `viewer-data.json`: data used by the viewer
- `run_manifest.json`: inputs, parameters, tool hashes, and artifacts
- `rv.stdout.txt`, `rv.stderr.txt`, `rv.log`: execution logs
- segmentation and feature overlay images

Useful commands:

```powershell
<plugin-root>\bin\root-measure.cmd runs --limit 10
<plugin-root>\bin\root-measure.cmd inspect --run <run-folder>
<plugin-root>\bin\root-measure.cmd doctor
```

### Public Reproduction

Use reproduction mode only when you have an expected CSV or a previous baseline.
Root Measure can compare generated `features.csv` to expected results and report
exact matches or differences.

```powershell
<plugin-root>\bin\root-measure.cmd compare --actual <features.csv> --expected <expected.csv> --key File.Name
```

If expected rows contain duplicate `File.Name` values:

```powershell
<plugin-root>\bin\root-measure.cmd compare --actual <features.csv> --expected <expected.csv> --key File.Name --duplicate-key-mode BestMatch
```

The GitHub `imageexamples` are smoke tests, not numeric oracles. Do not claim
official agreement unless `compare` has checked the generated table against the
expected CSV.

More details: [docs/reproducibility.md](docs/reproducibility.md).

### Documentation

- [docs/installation.md](docs/installation.md): Codex installation and known
  install pitfalls
- [docs/usage.md](docs/usage.md): everyday measurement workflow
- [docs/reproducibility.md](docs/reproducibility.md): expected CSV comparison and
  public-data reproduction
- [docs/reproducibility-gotchas.md](docs/reproducibility-gotchas.md): detailed
  validation pitfalls

### References

- RhizoVision Explorer: https://www.rhizovision.com/
- RhizoVision Explorer GitHub:
  https://github.com/predictivephenomics/RhizoVisionExplorer
- Seethepalli, A. et al. (2021). RhizoVision Explorer: open-source software for
  root image analysis and measurement standardization. AoB PLANTS, 13(6), plab056.
  https://doi.org/10.1093/aobpla/plab056
- RhizoVision Explorer Zenodo release: https://doi.org/10.5281/zenodo.3747697
