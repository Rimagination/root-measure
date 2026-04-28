# Reproducibility Guide / 复现指南

Most user datasets do not have an expected CSV. In that common case, Root
Measure should focus on measurement and quality control. Use the reproduction
workflow only when the user has an official result table, a previous baseline,
or explicitly asks for comparison.

大多数用户自己的数据没有 expected CSV。这种常见情况下，Root Measure 应该专注于测量
和质控。只有当用户有官方结果表、历史 baseline，或明确要求对比时，才进入复现流程。

## Required Inputs / 必要输入

For public-data reproduction, collect:

公开数据复现需要收集：

- images / 图像
- expected CSV or previous baseline CSV / expected CSV 或历史 baseline CSV
- parameter source: paper, settings CSV, metadata, official command, or previous
  verified run / 参数来源：论文、settings CSV、metadata、官方命令或之前验证过的运行
- scale: `DPI` or `pixels/mm` / 尺度：`DPI` 或 `pixels/mm`
- intended duplicate-key policy / 重复 key 处理策略

Before comparing, run:

对比前先运行：

```powershell
<plugin-root>\bin\root-measure.cmd doctor
<plugin-root>\bin\root-measure.cmd profile
```

`doctor` verifies the local toolchain. `profile` exposes the validation history
and known pitfalls.

`doctor` 验证本地工具链。`profile` 输出历史验证记录和已知坑点。

## Compare / 对比

Basic comparison:

基础对比：

```powershell
<plugin-root>\bin\root-measure.cmd compare --actual <features.csv> --expected <expected.csv> --key File.Name
```

Duplicate expected keys:

expected 表存在重复 key：

```powershell
<plugin-root>\bin\root-measure.cmd compare --actual <features.csv> --expected <expected.csv> --key File.Name --duplicate-key-mode BestMatch
```

Tolerance-based comparison:

容差对比：

```powershell
<plugin-root>\bin\root-measure.cmd compare --actual <features.csv> --expected <expected.csv> --key File.Name --tolerance 0.001
```

Only claim exact agreement when `compare` reports:

只有当 `compare` 报告以下状态时，才声明 exact agreement：

```text
status: exact
```

If tolerance was used, report it as tolerance-based agreement.

如果使用了容差，应明确写成 tolerance-based agreement。

## Common Pitfalls / 常见坑

- GitHub `imageexamples` are smoke tests, not numeric oracles.
- GitHub `imageexamples` 是 smoke test，不是数值标准答案。
- Do not silently assume DPI.
- 不要静默假设 DPI。
- Toolchain hash changes create a new baseline until re-compared.
- 工具链 hash 变化后，在重新对比前应视为新 baseline。
- `Computation.Time.s` is volatile and should normally be excluded from exact
  numeric claims.
- `Computation.Time.s` 是运行耗时，通常不应纳入 exact 数值声明。
- Duplicate `File.Name` rows require an explicit duplicate policy.
- 重复 `File.Name` 行需要明确的重复处理策略。
- Paper-visible settings may not contain every saved GUI or CLI option.
- 论文中可见的设置不一定包含所有 GUI 或 CLI 选项。
- Analyzer or Crown tables are not automatically RhizoVision Explorer expected
  tables.
- Analyzer 或 Crown 表不自动等同于 RhizoVision Explorer 的 expected 表。

Detailed notes live in
[reproducibility-gotchas.md](reproducibility-gotchas.md).

更详细记录见 [reproducibility-gotchas.md](reproducibility-gotchas.md)。

## Reporting Template / 汇报模板

For public-data comparison, report:

公开数据对比建议汇报：

- actual CSV path / actual CSV 路径
- expected CSV path / expected CSV 路径
- key columns / key 列
- duplicate policy / 重复处理策略
- rows matched / 匹配行数
- exact rows / exact 行数
- nonzero diff cell count / 非零差异单元格数量
- maximum absolute differences / 最大绝对差异
- tolerance, if used / 使用的容差
- diff artifact folder / 差异产物目录
- toolchain hashes / 工具链 hash

## References / 参考资料

- RhizoVision Explorer: https://www.rhizovision.com/
- RhizoVision Explorer GitHub:
  https://github.com/predictivephenomics/RhizoVisionExplorer
- RhizoVision Explorer image examples:
  https://github.com/predictivephenomics/RhizoVisionExplorer/tree/main/imageexamples
- Seethepalli, A., Dhakal, K., Griffiths, M., Guo, H., Freschet, G. T., &
  York, L. M. (2021). RhizoVision Explorer: open-source software for root image
  analysis and measurement standardization. AoB PLANTS, 13(6), plab056.
  https://doi.org/10.1093/aobpla/plab056
- RhizoVision Explorer Zenodo release: https://doi.org/10.5281/zenodo.3747697
- Copper wire ground truth dataset: https://doi.org/10.5281/zenodo.4677546
- Multispecies root scans and RVE / WinRhizo tables:
  https://doi.org/10.5281/zenodo.4677751
- RVE paper data and statistics code: https://doi.org/10.5281/zenodo.4677553
- Multi-scan concatenation test data: https://doi.org/10.5281/zenodo.12667584
- Whole-root reference dataset: https://doi.org/10.5281/zenodo.8083525
