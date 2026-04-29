# Usage Guide / 使用指南

Root Measure is designed to be driven by Codex in natural language, with a CLI
available when you want exact commands.

Root Measure 优先面向通过 Codex 的自然语言工作流，同时也保留了适合高级用户的 CLI。

## Choose a Workflow / 选择流程

Use one of these starting points:

你可以从这些入口开始：

- New user data: `measure`
- Unsure settings: `wizard`
- Existing run folder: `inspect`
- Recent output folders: `runs`
- Toolchain health: `doctor`
- Full RhizoVision Explorer CLI control: `raw --`

对应中文：

- 新数据分析：`measure`
- 不确定参数：`wizard`
- 已有结果目录：`inspect`
- 查最近结果：`runs`
- 检查工具链：`doctor`
- 完整 RVE CLI 控制：`raw --`

## Guided Workflow / 引导流程

```powershell
<plugin-root>\bin\root-measure.cmd wizard
```

The wizard asks for:

引导流程会询问：

- input image file or folder
- broken-root vs whole-root/crown style
- physical scale: `DPI` or `pixels/mm`
- whether to keep intermediate images and viewer artifacts

## Analyze New Data / 分析新数据

Broken-root scans:

```powershell
<plugin-root>\bin\root-measure.cmd measure --input D:\data\scans --dpi 600 --preset broken-roots
```

Whole-root or crown style images:

```powershell
<plugin-root>\bin\root-measure.cmd measure --input D:\data\roots --pixels-per-mm 13.27 --preset whole-root
```

If you are using Root Measure through Codex chat, you normally do not need to
choose an output directory yourself. Each run is written next to the input path
under `root-measure-results\root-measure-<timestamp>`, and Codex can report
that path after the run.

如果你是通过 Codex 对话使用 Root Measure，通常不需要自己指定输出目录。
每次运行都会默认写到输入路径旁边的
`root-measure-results\root-measure-<timestamp>`，完成后 Codex 可以直接把路径告诉你。

When scale is missing, Root Measure can still create pixel-based outputs, but
you should not interpret `mm`, `mm2`, or `mm3` as physical measurements.

缺少尺度时，Root Measure 仍可生成基于像素的结果，但不应把 `mm`、`mm2`、`mm3`
当成真实物理测量。

## Inspect Results / 查看结果

List recent runs near an input folder:

```powershell
<plugin-root>\bin\root-measure.cmd runs --path D:\data\scans --limit 10
```

Inspect one run:

```powershell
<plugin-root>\bin\root-measure.cmd inspect --run D:\path\to\run-folder
```

Look for:

- `features.csv` row count
- whether `viewer.html` exists
- whether `run_manifest.json` recorded inputs and command arguments
- segmentation and feature overlay images
- warnings or failures in logs

重点对应中文：

- `features.csv` 行数
- 是否生成 `viewer.html`
- `run_manifest.json` 是否记录输入与命令参数
- segmentation 与 feature overlay 图像
- 日志里的 warning 或 failure

## Full CLI Passthrough / 完整 CLI 透传

Use `raw --` when the high-level `measure` command does not expose the exact
RhizoVision Explorer option you need.

当高层 `measure` 没有暴露你需要的具体 RhizoVision Explorer 参数时，用 `raw --`。

```powershell
<plugin-root>\bin\root-measure.cmd raw -- -r -v -na --segment --feature --convert --factordpi 600 -op D:\out -o features.csv D:\data\scans
```

Common advanced needs:

- ROI paths
- metadata CSV
- recursive mode
- append or noappend behavior
- distance map, topology, convex hull, medial axis
- custom thresholds, pruning, filtering, or diameter ranges

## How To Report Results / 结果汇报建议

For a normal user-data run, report:

- output directory
- viewer path
- `features.csv` path
- preset and scale
- input image count and result row count
- key metric columns
- warnings or missing artifacts

对普通用户数据运行，中文建议至少汇报：

- 输出目录
- viewer 路径
- `features.csv` 路径
- preset 与尺度
- 输入图像数与结果行数
- 关键指标列
- warning 或缺失产物

For failed or partial runs, report the exit code, failure reason, and the most
useful log excerpt first.

如果运行失败或只完成了部分图像，优先汇报 exit code、失败原因和最有用的日志摘录。
