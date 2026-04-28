# Root Measure User

Root Measure User 是一个 Codex 插件，用来分析根系图像并检查 Root Measure / RhizoVision Explorer CLI 的输出证据。它适合两类人：

- 只想分析自己数据的用户：告诉 Codex 图像在哪里、尺度是多少，Codex 帮你跑完并解释结果。
- 需要复现公开数据集的用户：提供图像、参数来源和 expected CSV，Codex 帮你检查工具链、运行、对比和排错。

这个插件不是一个阉割版 wrapper。它提供简单入口，也保留完整 `rv.exe` 原始参数能力。

## 最简单的安装方式

如果你是第一次使用，推荐直接把下面这句话发给 Codex：

```text
请帮我安装这个 Codex 插件：https://github.com/Rimagination/root-measure-user
```

更稳一点的说法是：

```text
请帮我安装这个 Codex 插件：https://github.com/Rimagination/root-measure-user。安装后请运行 Root Measure 的 doctor 和 release-check，确认插件入口、工具链 hash、示例 smoke test 都通过。
```

Codex 应该替你完成这些事：

1. 下载或复制插件到本机 Codex 可用的 plugin 目录。
2. 确认插件目录里有 `.codex-plugin/plugin.json`。
3. 把插件注册到 Codex marketplace / plugin 配置里。
4. 确认 Root Measure 后端存在，也就是能找到 `rv.exe` 和 `cvutil.dll`。
5. 运行 `root-measure doctor`。
6. 运行 `root-measure release-check`。
7. 告诉你安装是否成功，以及以后该怎么调用。

普通用户不需要自己改代码，也不需要进入插件目录挑脚本。

## 安装后如何确认可用

让 Codex 执行：

```text
请检查 Root Measure 插件是否安装成功，并运行 release-check。
```

或者在终端里运行：

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd release-check
```

如果通过，会看到：

```text
status: pass
```

`release-check` 会检查：

- 插件清单和 marketplace 注册
- 用户级 `root-measure` 入口
- PowerShell 脚本语法
- `rv.exe` 和 `cvutil.dll` hash
- raw `rv.exe` 参数透传
- 历史验证坑点和 exact validation evidence
- 3 张官方 scan 示例 smoke test
- `inspect` 是否能读到 viewer 和 3 行结果
- `compare` 自比较是否 exact

## 第一次分析自己的数据

你可以直接对 Codex 说：

```text
帮我用 Root Measure 分析这个文件夹里的根系图：D:\my-data\scans，扫描尺度是 600 DPI。
```

或者：

```text
帮我分析 D:\my-data\roots，尺度是 13.27 pixels/mm，我想看中间分割图和 feature overlay。
```

Codex 会自动选择合适命令，通常等价于：

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd measure --input D:\my-data\scans --dpi 600 --preset broken-roots
```

如果你不确定该怎么选参数，可以说：

```text
启动 Root Measure 分析向导。
```

或者运行：

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd wizard
```

向导会问你：

- 是分析自己的新数据，还是复现公开数据集？
- 图像文件或文件夹在哪里？
- 是 broken roots、whole root / crown，还是不确定？
- 是否知道 DPI 或 pixels/mm？
- 是否需要 viewer、中间图、日志和 manifest？

## 用户自己的数据没有 expected CSV

大多数用户自己的新数据没有 expected CSV，也不应该被要求和官方表格对比。

这种情况下，插件做的是测量和质控：

- 输入图像是否找到
- 每张图是否成功处理
- 是否提供了 DPI 或 pixels/mm
- 使用了哪个 preset 和哪些真实 CLI 参数
- `features.csv` 有多少行
- 关键指标列是否存在
- 是否生成了 `viewer.html`
- 是否生成了 segment 图和 feature overlay 图
- 日志里有没有 warning 或 error

只有当你明确说“我有 expected CSV”、“我要复现公开数据集”、“我要和之前结果对比”时，插件才会进入对比流程。

## 分析结果在哪里

每次高层测量通常会生成一个结果目录，里面包括：

- `features.csv`：测量指标表
- `viewer.html`：本地证据查看器
- `viewer-data.json`：viewer 使用的数据
- `run_manifest.json`：输入、参数、命令、hash、产物记录
- `rv.stdout.txt` / `rv.stderr.txt`：运行日志
- segment 图：分割结果
- feature overlay 图：特征叠加图

你可以问 Codex：

```text
Root Measure 最近的结果在哪里？
```

或者运行：

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd runs --limit 10
```

检查某个结果目录：

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd inspect --run <run-folder>
```

## 复现公开数据集

公开数据集复现和普通用户数据分析不一样。你需要提供：

- 下载好的图像
- 官方或论文提供的 expected CSV
- 参数来源，比如 settings CSV、metadata、论文方法、官方命令或之前验证记录

你可以对 Codex 说：

```text
我想复现这个公开数据集。图像在 D:\data\images，expected CSV 在 D:\data\expected.csv，请帮我检查工具链、运行并比较结果。
```

终端命令示例：

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd compare --actual <features.csv> --expected <expected.csv> --key File.Name
```

如果 expected CSV 里有重复 `File.Name`，使用：

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd compare --actual <features.csv> --expected <expected.csv> --key File.Name --duplicate-key-mode BestMatch
```

注意：GitHub `imageexamples` 适合 smoke test，不是数值 oracle。要声明“和官方一致”，必须真的对比过 expected CSV。

## 高级用户：完整 rv.exe 参数

如果你已经知道 RhizoVision Explorer CLI 参数，可以使用 raw 模式：

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd raw -- -r -v -na --segment --feature --distancemap --convert --factordpi 600 -op <output-dir> -o features.csv <input-path>
```

`raw --` 后面的内容会原样转发给安装的 `rv.exe`。

这用于：

- ROI
- metadata CSV
- recursive mode
- append / noappend
- distance map
- topology
- convex hull
- medial axis
- contour width
- 自定义 threshold、filtering、pruning、diameter ranges

## 常用命令

```powershell
root-measure doctor
root-measure wizard
root-measure measure --input <path> --dpi 600 --preset broken-roots
root-measure measure --input <path> --pixels-per-mm 13.27 --preset whole-root
root-measure runs --limit 10
root-measure inspect --run <dir>
root-measure compare --actual <features.csv> --expected <expected.csv> --key File.Name
root-measure raw -- <rv.exe arguments>
root-measure profile
root-measure release-check
```

## 排错

先让 Codex 运行：

```text
请帮我诊断 Root Measure 插件，先跑 doctor，再检查最近一次结果目录。
```

常见问题：

- 没有物理尺度：需要 DPI 或 pixels/mm，否则 mm、面积、体积指标不能当作物理测量解释。
- 工具链 hash 不一致：不要沿用旧的公开数据验证结论，先重新对比。
- 没有中间图：检查是否启用了 segment / feature overlay。
- 行数不对：检查输入目录、递归选项、失败图像、输出 append 设置。
- 官方结果不一致：检查参数、DPI、threshold、duplicate key、`Computation.Time.s`。
- whole-root 结果异常：检查 root type、反色、方向、scale、prune、diameter ranges。

插件内置了历史验证踩坑规则。Codex 在做公开数据复现或排错前应该读取：

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd profile
```

## 当前状态

当前版本：`0.2.0-beta`

这个版本已经适合小范围发布和真实用户试用：有统一 CLI、Codex 自然语言入口、问答向导、完整 raw CLI、透明产物、排错规则和 release check。正式 `1.0` 前建议继续补跨机器安装测试和更完整的用户示例。
