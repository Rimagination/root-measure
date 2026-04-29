---
layout: page
title: Parameters and Modes
permalink: /parameters-and-modes/
---

<a id="chinese"></a>

中文 | [English](#english)

# 2. 参数与模式

这一页解释最容易影响 Root Measure 结果的模式和关键参数。

## 2.1 模式

### 2.1.1 `broken roots`

更适合这些情况：

- 图里主要是分散的根段或断根
- 扫描背景相对干净
- 你更关心长度、直径、面积、体积和拓扑指标

### 2.1.2 `whole root / crown`

更适合这些情况：

- 图里保留了完整根系结构
- 你关心深度、宽度、方向或整体架构
- 整体结构比单段几何更重要

## 2.2 如何决定模式

先看图像本身，不要只看文件名。

如果不确定：

- 先让 Codex 启动引导流程
- 不要一开始就强行固定模式
- 先看少量样本的 segmentation 和 `viewer.html` 再决定

## 2.3 常见关键参数

最值得优先理解的是：

- `threshold`
- `invert`
- `prune`
- `prune threshold`
- `background noise filter`
- `diameter ranges`
- `DPI` / `pixels/mm`

## 2.4 这些参数各自影响什么

### 2.4.1 `threshold`

它首先影响分割结果，也是最容易连锁改变下游指标的参数。

- 太低：背景噪声、阴影或碎屑更容易被当成根
- 太高：细根和弱信号更容易丢失

### 2.4.2 `invert`

它决定前景和背景的亮暗方向是否被正确解释。

- 如果图像极性和模式假设不一致，整次运行都可能偏掉

### 2.4.3 `prune` / `prune threshold`

它们主要影响 skeleton / topology 相关指标。

- 开启或调高后，小分枝和噪声小枝更容易被删掉
- `Number.of.Root.Tips`、`Branch Points` 和长度类指标都会变化

### 2.4.4 `background noise filter`

它对某些公开数据的严格复现尤其敏感。

- 在 2024 multi-scan 官方 CSV 复现里，`--bgnoise --bgsize 1` 是关键恢复设置

### 2.4.5 `diameter ranges`

它不只是显示选项，确实会改变直径分箱相关输出列。

- 如果你关心分箱长度、面积、表面积或体积，这个参数必须明确

## 2.5 当前高层 preset 的边界

当前公开高层 preset 主要是：

- `broken-roots-exact`
- `whole-root-exact`
- `custom`

当前记录里：

- `broken-roots-exact` 使用 `threshold 220`、`prune off`、`bgnoise off`
- `whole-root-exact` 使用 `threshold 235`、`invert on`、`bgnoise on`、`bgsize 0.5`、`prune on`、`prunethreshold 50`、`dranges 0.3,0.5,1.3`
- `custom` 目前仍是未验证默认组合，不是完整自由参数面板

这意味着一旦需求超出高层接口暴露范围，就应退回 `raw --`。

---

<a id="english"></a>

[中文](#chinese) | English

# 2. Parameters and Modes

This page explains the modes and key parameters that most easily affect Root Measure results.

## 2.1 Modes

### 2.1.1 `broken roots`

This is a better fit when:

- the image mainly contains separated root fragments
- the scan background is relatively clean
- you mostly care about length, diameter, area, volume, and topology-style traits

### 2.1.2 `whole root / crown`

This is a better fit when:

- the full root architecture is preserved
- you care about depth, width, orientation, or overall architecture
- whole-plant structure matters more than fragment-level geometry

## 2.2 How to Decide Which Mode to Use

Look at the image itself first, not the filename.

If you are unsure:

- let Codex guide you through the workflow
- do not force a mode too early
- inspect a few sample segmentations and `viewer.html` before deciding whether to switch

## 2.3 Common Key Parameters

These are the parameters most worth understanding first:

- `threshold`
- `invert`
- `prune`
- `prune threshold`
- `background noise filter`
- `diameter ranges`
- `DPI` / `pixels/mm`

## 2.4 What Each Key Parameter Changes

### 2.4.1 `threshold`

This is the first major segmentation control and the easiest way to change nearly all downstream metrics.

- too low: background noise, shadows, or debris are more likely to be treated as roots
- too high: fine roots and weak signals are more likely to disappear

### 2.4.2 `invert`

This controls whether bright and dark regions are interpreted in the correct foreground/background direction.

- if the image polarity does not match the mode assumption, the whole run can be wrong

### 2.4.3 `prune` / `prune threshold`

These mainly affect skeleton / topology-derived traits.

- enabling or increasing them removes more small branches and noise twigs
- `Number.of.Root.Tips`, `Branch Points`, and length-style traits can all shift

### 2.4.4 `background noise filter`

This is especially sensitive for strict agreement with some public results.

- in the 2024 multi-scan official CSV reproduction, `--bgnoise --bgsize 1` was the key recovered setting

### 2.4.5 `diameter ranges`

This is not only a display preference. It really changes the diameter-binned output columns.

- if you care about binned length, area, surface area, or volume, this parameter must be explicit

## 2.5 Current Boundaries of the High-Level Presets

The current public high-level presets are mainly:

- `broken-roots-exact`
- `whole-root-exact`
- `custom`

The current records say:

- `broken-roots-exact` uses `threshold 220`, `prune off`, and `bgnoise off`
- `whole-root-exact` uses `threshold 235`, `invert on`, `bgnoise on`, `bgsize 0.5`, `prune on`, `prunethreshold 50`, and `dranges 0.3,0.5,1.3`
- `custom` is still an unvalidated default combination, not a full free-parameter panel

That means the high-level `measure` command still does not express every common parameter need. Once the request goes beyond those exposed controls, the workflow must fall back to `raw --`.
