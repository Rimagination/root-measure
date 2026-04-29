---
layout: page
title: Getting Started
permalink: /getting-started/
---

<a id="chinese"></a>

中文 | [English](#english)

# 1. 入门与使用

这一页面向主要通过 Codex 对话来使用 Root Measure 的用户。

## 1.1 最简单的开始方式

通常不需要先学 CLI，直接告诉 Codex 你的需求即可：

```text
用 Root Measure 分析 D:\data\scans，扫描精度是 600 DPI。
```

如果你不确定模式或参数，可以直接说：

```text
Start the Root Measure guided workflow.
```

## 1.2 推荐工作顺序

对多数用户，推荐这样做：

1. 告诉 Codex 你要分析哪个文件夹或文件
2. 如果模式或尺度不明确，让 Codex 启动引导流程
3. 跑完后先看 `viewer.html` 和 `features.csv`
4. 如果结果可疑，再回头检查模式、尺度和关键参数

## 1.3 默认输出位置

默认情况下，结果会写到输入路径旁边的：

```text
root-measure-results\root-measure-<timestamp>
```

如果输入是：

```text
D:\data\scans
```

那么常见输出会是：

```text
D:\data\scans\root-measure-results\root-measure-20260429-140500\
```

## 1.4 运行后先看什么

第一次看结果时，优先检查：

- `viewer.html` 是否成功生成
- `features.csv` 行数是否大致对应输入图像数
- segmentation 是否明显过粗、过细，或漏掉大量根段
- `run_manifest.json` 记录的尺度和参数是否符合预期

## 1.5 普通分析和公开复现的区别

分析自己的新数据时，通常没有官方 `expected CSV`。这时重点是：

- 模式是否合适
- 尺度是否可信
- viewer 和中间图像是否合理
- 结果表是否完整

只有在你已经有 `expected CSV` 或历史 baseline 时，才进入真正的复现对比流程。

## 1.6 常见下一步

- 只想拿到可用结果：继续看 `viewer.html` 和 `features.csv`
- 想找最近结果：用 `runs --path <input-folder>`
- 想细查某次运行：用 `inspect --run <run-folder>`
- 想证明和公开结果一致：进入“复现与验证”，不要只依赖 smoke test

---

<a id="english"></a>

[中文](#chinese) | English

# 1. Getting Started

This page is for people who mainly use Root Measure through Codex chat.

## 1.1 The Simplest Way to Begin

You usually do not need to learn the CLI first. Just tell Codex what you want:

```text
Use Root Measure to analyze D:\data\scans. The scan scale is 600 DPI.
```

If you are unsure about mode or parameters, you can simply say:

```text
Start the Root Measure guided workflow.
```

## 1.2 Recommended Workflow

For most users, the best order is:

1. tell Codex which folder or file you want to analyze
2. if mode or scale is unclear, let Codex start the guided workflow
3. after the run, review `viewer.html` and `features.csv` first
4. if the result looks suspicious, go back and check mode, scale, and key parameters

## 1.3 Default Output Location

By default, results are written next to the input path under:

```text
root-measure-results\root-measure-<timestamp>
```

If your input is:

```text
D:\data\scans
```

then a common output path looks like:

```text
D:\data\scans\root-measure-results\root-measure-20260429-140500\
```

## 1.4 What to Check First After a Run

On a first pass, focus on:

- whether `viewer.html` was generated
- whether the `features.csv` row count roughly matches the number of input images
- whether segmentation looks obviously too thick, too thin, or misses major root segments
- whether `run_manifest.json` recorded the scale and parameters you expected

## 1.5 Ordinary Analysis vs Public Reproduction

When you analyze your own new data, you usually do not have an official `expected CSV`.

For those runs, the priority is:

- whether the chosen mode makes sense
- whether the scale is trustworthy
- whether the viewer and intermediate images look reasonable
- whether the output table is complete

You only move into a true reproduction / comparison workflow when you already have an official `expected CSV` or a prior baseline.

## 1.6 Common Next Steps

- if you only need usable results: review `viewer.html` and `features.csv`
- if you want to find recent runs: use `runs --path <input-folder>`
- if you want to inspect one run carefully: use `inspect --run <run-folder>`
- if you want to prove agreement with public results: move into `Reproducibility` rather than relying on a smoke test
