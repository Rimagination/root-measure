# Usage Guide / 使用指南

Root Measure is designed to be driven by Codex in natural language, with a CLI
available when you want exact commands.

Root Measure 设计上优先由 Codex 用自然语言驱动；当你需要精确命令时，也可以直接使用
CLI。

## Choose a Workflow / 选择流程

Use one of these starting points:

可以从下面几个入口开始：

- New user data: `measure`
- 新数据分析：`measure`
- Unsure settings: `wizard`
- 不确定参数：`wizard`
- Existing run folder: `inspect`
- 已有结果目录：`inspect`
- Recent output folders: `runs`
- 最近结果目录：`runs`
- Toolchain health: `doctor`
- 工具链健康检查：`doctor`
- Full RhizoVision Explorer CLI control: `raw --`
- 完整 RhizoVision Explorer CLI 参数控制：`raw --`

## Guided Workflow / 分析向导

```powershell
<plugin-root>\bin\root-measure.cmd wizard
```

The wizard asks for:

向导会询问：

- input image file or folder / 输入图像或文件夹
- broken-root vs whole-root/crown style / broken-root 或 whole-root/crown 类型
- physical scale: `DPI` or `pixels/mm` / 物理尺度：`DPI` 或 `pixels/mm`
- whether to keep intermediate images and viewer artifacts / 是否保留中间图和
  viewer 产物

## Analyze New Data / 分析新数据

Broken-root scans:

broken-root 扫描图：

```powershell
<plugin-root>\bin\root-measure.cmd measure --input D:\data\scans --dpi 600 --preset broken-roots
```

Whole-root or crown style images:

whole-root 或 crown 类型图像：

```powershell
<plugin-root>\bin\root-measure.cmd measure --input D:\data\roots --pixels-per-mm 13.27 --preset whole-root
```

When scale is missing, Root Measure can still create pixel-based outputs, but
you should not interpret mm, mm2, or mm3 metrics as physical measurements.

缺少尺度时，Root Measure 仍可生成像素层面的结果，但不要把 mm、mm2、mm3 等指标解释为
真实物理测量。

## Inspect Results / 查看结果

List recent runs:

列出最近结果：

```powershell
<plugin-root>\bin\root-measure.cmd runs --limit 10
```

Inspect one run:

检查某个结果目录：

```powershell
<plugin-root>\bin\root-measure.cmd inspect --run D:\path\to\run-folder
```

Look for:

重点查看：

- `features.csv` row count / `features.csv` 行数
- `viewer.html` exists / 是否生成 `viewer.html`
- `run_manifest.json` records inputs and command arguments / `run_manifest.json`
  是否记录输入和命令参数
- segmentation and feature overlay images / 分割图和特征叠加图
- warnings or failures in logs / 日志中的 warning 或 failure

## Full CLI Passthrough / 完整 CLI 透传

Use `raw --` when the high-level `measure` command does not expose the exact
RhizoVision Explorer option you need.

当高层 `measure` 命令没有暴露你需要的 RhizoVision Explorer 参数时，使用 `raw --`。

```powershell
<plugin-root>\bin\root-measure.cmd raw -- -r -v -na --segment --feature --convert --factordpi 600 -op D:\out -o features.csv D:\data\scans
```

Common advanced needs:

常见高级需求：

- ROI paths / ROI 路径
- metadata CSV / metadata CSV
- recursive mode / 递归模式
- append or noappend behavior / append 或 noappend 行为
- distance map, topology, convex hull, medial axis / distance map、topology、
  convex hull、medial axis
- custom thresholds, pruning, filtering, or diameter ranges / 自定义 threshold、
  pruning、filtering 或 diameter ranges

## How To Report Results / 结果汇报建议

For a normal user-data run, report:

普通用户数据分析建议汇报：

- output directory / 输出目录
- viewer path / viewer 路径
- `features.csv` path / `features.csv` 路径
- preset and scale / preset 和尺度
- input image count and result row count / 输入图像数和结果行数
- key metric columns / 关键指标列
- warnings or missing artifacts / warning 或缺失产物

For failed or partial runs, report the exit code, failure reason, and the most
useful log excerpt first.

如果运行失败或只完成部分图像，先汇报 exit code、失败原因和最有用的日志摘录。
