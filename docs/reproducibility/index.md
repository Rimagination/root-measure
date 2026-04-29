---
layout: page
title: Reproducibility
permalink: /reproducibility/
---

<a id="chinese"></a>

中文 | [English](#english)

# 3. 复现与验证

这一页专门记录：

- 公开数据的 exact reproduction
- 各数据集对应的关键参数
- 哪些 exact 结果依赖固定工具链，而不只是 CLI 参数

## 3.1 验证数据集概览

### 3.1.1 `copper-wire`

- 类型：铜丝 ground truth，用于长度、直径、表面积、体积等基础指标验证
- 本地数据路径：`validation-data\zenodo-4677546-copper-wire-ground-truth`
- 官方表来源：Zenodo `4677553`
- 说明：当前本地检查覆盖 28 张可用 600 DPI TIFF；1200 DPI 官方行不在本地图像包里

### 3.1.2 `multispecies`

- 类型：真实 root-scan 图像，覆盖 herbaceous、maize、trees、wheat
- 本地数据路径：`validation-data\zenodo-4677751-multispecies-root-scans`
- 官方表来源：Zenodo `4677553`
- 说明：这是 broken-root 路线较大规模的 exact reproduction 验证

### 3.1.3 `whole-root CrownRoots (Zenodo 8083525)`

- 类型：Explorer-origin whole-root / crown 数值验证
- 说明：这是当前 `whole-root-exact` 的主要公开证据基础
- 重点：不仅验证数值表，也验证 feature 图像一致性

### 3.1.4 `2024 multi-scan official CSV`

- 类型：split-scan concatenation 与 sample-level aggregation 验证
- 图像数据：Zenodo `12667584`
- 官方输出与脚本：Zenodo `12668178`
- 说明：这是 `2024 multi-scan` 路线的 exact CSV reproduction 基线

## 3.2 已确认的主要验证线

### 3.2.1 `copper-wire`

- 本地 600 DPI TIFF 子集在 `threshold 191` 和 `threshold 222` 下都达到 exact
- 这说明它本身就不是“唯一阈值通吃”的例子

### 3.2.2 `multispecies`

- exact agreement 还依赖兼容版 `cvutil.dll`
- 差异主要集中在 skeleton / topology 路径，而不只是 threshold 或 DPI

### 3.2.3 `whole-root CrownRoots (Zenodo 8083525)`

当前高层 preset 记录为：

- `threshold 235`
- `invert on`
- `bgnoise on`
- `bgsize 0.5`
- `prune on`
- `prunethreshold 50`
- `dranges 0.3,0.5,1.3`

### 3.2.4 `2024 multi-scan official CSV`

当前确认的 exact 路径需要：

- `-rt 1`
- `-t 200`
- `--convert --factordpi <1400|1200|600>`
- `--prune -pt 5`
- `--bgnoise --bgsize 1`
- `--dranges ''`

其中最关键的恢复项是：

- `--bgnoise --bgsize 1`

## 3.3 已验证参数矩阵

| Dataset | Mode | Currently validated parameters | Scale | Validation scope | Toolchain dependency | Evidence source | Good public preset candidate |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `copper-wire` | `broken roots` | `threshold 191` or `222`, empty `--dranges` | `600 DPI` | 28 TIFF images, numeric exactness | Yes | `rv-official-reproduction-investigation.md` | No |
| `multispecies` | `broken roots` | follows the broken-root reproduction pathway; the key is compatibility-preserved skeleton / topology behavior | from official tables and scripts | 588 images, numeric exactness | Yes | `rv-multispecies-validation.md` | No |
| `whole-root CrownRoots (8083525)` | `whole root` | `threshold 235`, `invert on`, `bgnoise on`, `bgsize 0.5`, `prune on`, `prunethreshold 50`, `dranges 0.3,0.5,1.3` | metadata / explicit scale | 100 numeric rows plus 100 exact feature images | Yes | `rv-paper-mode-metric-coverage.md` | Yes |
| `2024 multi-scan official CSV` | `broken roots` | `-rt 1 -t 200 --convert --factordpi <1400|1200|600> --prune -pt 5 --bgnoise --bgsize 1 --dranges ''` | Peatland `1400`, Poplar `1200`, Switchgrass `600` | 311 official CSV rows, exact | Yes | `rv-concatenation-2024-official-csv-reproduction.md` | Yes |

说明：

- 这里的“已验证参数”指当前项目里已有 exact evidence 支撑的组合
- 它不等于“对任何新数据都推荐这样用”
- 多条验证线还依赖固定 `rv.exe` / `cvutil.dll` 工具链

## 3.4 当前验证结果摘要

| Dataset | Current result | Key numbers |
| --- | --- | --- |
| `copper-wire` | exact | `threshold 191`: `28/28` exact; `threshold 222`: `28/28` exact; max absolute difference `0` |
| `multispecies` | exact | `588` images; `9,070` compared metric cells; `0` nonzero differences |
| `whole-root CrownRoots (8083525)` | exact | `100/100` rows; max absolute difference `0`; feature images `100/100` identical |
| `2024 multi-scan official CSV` | exact | `311/311` rows; `4,665` numeric cells; `0` nonzero differences; `0` failures |

## 3.5 为什么 exact 不只是参数一致

项目已经显示，有些 exact match 不是只靠 CLI 参数得到的。

例如在 `multispecies` 路线上，关键因素还包括：

- 特定 `rv.exe`
- 固定 `cvutil.dll`
- 兼容补丁恢复的 skeleton / distance-transform 行为

所以“参数一样”并不自动等于“结果 exact”。

## 3.6 如何使用这张矩阵

- 如果目标是尽量贴近公开验证结果，从这里已经验证过的组合开始
- 如果是在分析新数据，把这张矩阵当作起点，而不是唯一答案
- 只要改动了关键参数，就不应再把运行称为同一个 validated preset

---

<a id="english"></a>

[中文](#chinese) | English

# 3. Reproducibility

This page is dedicated to:

- exact reproduction of public datasets
- key parameters for each validated dataset
- which exact matches depend on fixed toolchain behavior, not only on CLI parameters

## 3.1 Validation Dataset Overview

### 3.1.1 `copper-wire`

- Type: copper-wire ground truth for basic length, diameter, surface-area, and volume validation
- Local data path: `validation-data\zenodo-4677546-copper-wire-ground-truth`
- Official-table source: Zenodo `4677553`
- Note: the current local check covers 28 available 600 DPI TIFF images; the 1200 DPI official rows are not present in the local image ZIP

### 3.1.2 `multispecies`

- Type: real root-scan images covering herbaceous, maize, trees, and wheat
- Local data path: `validation-data\zenodo-4677751-multispecies-root-scans`
- Official-table source: Zenodo `4677553`
- Note: this is the larger exact-reproduction line for the broken-root scan pathway

### 3.1.3 `whole-root CrownRoots (Zenodo 8083525)`

- Type: Explorer-origin whole-root / crown numeric validation
- Note: this is the main public numeric evidence behind the current `whole-root-exact` path
- Focus: both numeric rows and feature-image agreement matter here

### 3.1.4 `2024 multi-scan official CSV`

- Type: split-scan concatenation and sample-level aggregation validation
- Image dataset: Zenodo `12667584`
- Official outputs and scripts: Zenodo `12668178`
- Note: this is the exact CSV reproduction line for the `2024 multi-scan` workflow

## 3.2 Main Validation Lines Already Confirmed

### 3.2.1 `copper-wire`

- the local 600 DPI TIFF subset reached exact agreement at both `threshold 191` and `threshold 222`
- so even this validation line is not an example of one universal threshold

### 3.2.2 `multispecies`

- exact agreement also depends on the compatibility `cvutil.dll`
- the main differences clustered in skeleton / topology pathways rather than simple threshold or DPI mistakes

### 3.2.3 `whole-root CrownRoots (Zenodo 8083525)`

The current high-level preset records:

- `threshold 235`
- `invert on`
- `bgnoise on`
- `bgsize 0.5`
- `prune on`
- `prunethreshold 50`
- `dranges 0.3,0.5,1.3`

### 3.2.4 `2024 multi-scan official CSV`

The currently confirmed exact path requires:

- `-rt 1`
- `-t 200`
- `--convert --factordpi <1400|1200|600>`
- `--prune -pt 5`
- `--bgnoise --bgsize 1`
- `--dranges ''`

The most important recovered setting was:

- `--bgnoise --bgsize 1`

## 3.3 Validated Parameter Matrix

| Dataset | Mode | Currently validated parameters | Scale | Validation scope | Toolchain dependency | Evidence source | Good public preset candidate |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `copper-wire` | `broken roots` | `threshold 191` or `222`, empty `--dranges` | `600 DPI` | 28 TIFF images, numeric exactness | Yes | `rv-official-reproduction-investigation.md` | No |
| `multispecies` | `broken roots` | follows the broken-root scan reproduction pathway; the key is compatibility-preserved skeleton / topology behavior | from official tables and scripts | 588 images, numeric exactness | Yes | `rv-multispecies-validation.md` | No |
| `whole-root CrownRoots (8083525)` | `whole root` | `threshold 235`, `invert on`, `bgnoise on`, `bgsize 0.5`, `prune on`, `prunethreshold 50`, `dranges 0.3,0.5,1.3` | metadata / explicit scale | 100 numeric rows plus 100 exact feature images | Yes | `rv-paper-mode-metric-coverage.md` | Yes |
| `2024 multi-scan official CSV` | `broken roots` | `-rt 1 -t 200 --convert --factordpi <1400|1200|600> --prune -pt 5 --bgnoise --bgsize 1 --dranges ''` | Peatland `1400`, Poplar `1200`, Switchgrass `600` | 311 official CSV rows, exact | Yes | `rv-concatenation-2024-official-csv-reproduction.md` | Yes |

Notes:

- “validated parameters” here means combinations already backed by exact evidence in the current project
- that is not the same as recommended defaults for any new user dataset
- several validation lines also depend on a fixed `rv.exe` / `cvutil.dll` compatibility toolchain

## 3.4 Current Validation Results Summary

| Dataset | Current result | Key numbers |
| --- | --- | --- |
| `copper-wire` | exact | `threshold 191`: `28/28` exact; `threshold 222`: `28/28` exact; max absolute difference `0` |
| `multispecies` | exact | `588` images; `9,070` compared metric cells; `0` nonzero differences |
| `whole-root CrownRoots (8083525)` | exact | `100/100` rows; max absolute difference `0`; feature images `100/100` identical |
| `2024 multi-scan official CSV` | exact | `311/311` rows; `4,665` numeric cells; `0` nonzero differences; `0` failures |

## 3.5 Why Exactness Is Not Only About Parameters

The project has already shown that some exact matches are not achieved by CLI parameters alone.

For example, in the `multispecies` line, the important factors also include:

- the private `rv.exe`
- the fixed `cvutil.dll`
- compatibility patches that restore the intended skeleton / distance-transform behavior

So “same parameters” does not automatically mean “exact reproduction”.

## 3.6 How to Use This Matrix

- If your goal is to stay close to a public validation result, start from one of the combinations already validated here.
- If you are analyzing a new dataset, treat this matrix as a starting point rather than a universal answer.
- Once you change one of the key parameters listed here, you should stop calling the run the same validated preset.
