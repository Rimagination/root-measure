---
name: root-measure
description: Use when the user asks to install or troubleshoot Root Measure, analyze root images, launch a guided workflow, choose scale or presets, inspect outputs, compare features.csv, forward rv.exe arguments, or verify the local Root Measure release.
---

# Root Measure

## Core Rule

Root Measure is a productized Codex plugin, not a folder of scripts for users to
search manually. Prefer the single front door:

```powershell
<plugin-root>\bin\root-measure.cmd <command>
```

Resolve `<plugin-root>` from the loaded skill path when possible:
`skills/root-measure/SKILL.md` lives inside the plugin, so the plugin root is two
directories above `skills/root-measure`.

Default response language: Chinese, unless the user asks otherwise. Preserve
exact paths, command names, presets, CSV columns, flags, and hashes.

## Install And Troubleshooting Route

When the user says the plugin is missing, not visible, or install failed, do not
guess. Check the installation layers in this order:

1. Source plugin exists and contains `.codex-plugin/plugin.json`.
2. `plugin.json` is strict UTF-8 without BOM. A leading `EF BB BF` can cause
   Codex to log `expected value at line 1 column 1`.
3. The active marketplace has an entry for `root-measure` with
   `source.path: "./plugins/root-measure"`.
4. The installed cache path exists under:
   `<CODEX_HOME>\plugins\cache\<marketplace>\root-measure\<version>`.
5. `config.toml` enables the matching plugin id, for example
   `root-measure@local-plugins`.
6. `doctor` passes.
7. `release-check` passes.

Use `docs/installation.md` as the install reference. Do not tell users that
`<CODEX_HOME>\plugins\root-measure` is the official installed location; Codex
Desktop resolves installed plugins through `plugins/cache/<marketplace>/<plugin>/<version>`.

## Product Routes

Use fast routing when the user goal is clear:

- Analyze new data: run `measure`.
- Need help choosing settings: run or describe `wizard`.
- Existing result folder: run `inspect`.
- Where are results: run `runs`.
- Toolchain health: run `doctor`.
- Full RVE control: run `raw -- <rv.exe args>`.
- Public/previous expected CSV comparison: run `compare`.
- Release readiness or install verification: run `release-check`.

Ask only for missing information that blocks the next step: input path, root
type/preset, scale (`DPI` or `pixels/mm`) if physical units are expected, and
whether the user has an expected CSV.

## Commands

Health check:

```powershell
<plugin-root>\bin\root-measure.cmd doctor
```

Guided workflow:

```powershell
<plugin-root>\bin\root-measure.cmd wizard
```

Analyze broken-root scans:

```powershell
<plugin-root>\bin\root-measure.cmd measure --input <path> --dpi 600 --preset broken-roots
```

Analyze whole-root or crown style images:

```powershell
<plugin-root>\bin\root-measure.cmd measure --input <path> --pixels-per-mm 13.27 --preset whole-root
```

Inspect a run:

```powershell
<plugin-root>\bin\root-measure.cmd inspect --run <dir>
```

List recent runs:

```powershell
<plugin-root>\bin\root-measure.cmd runs --limit 10
```

Compare only when the user has an expected CSV:

```powershell
<plugin-root>\bin\root-measure.cmd compare --actual <features.csv> --expected <expected.csv> --key File.Name
```

Forward the installed RVE CLI:

```powershell
<plugin-root>\bin\root-measure.cmd raw -- -r -v -na --segment --feature --convert --factordpi 600 -op <output-dir> -o features.csv <input-path>
```

Release readiness:

```powershell
<plugin-root>\bin\root-measure.cmd release-check
```

## User Data vs Reproduction

Most user datasets do not have expected CSVs. For normal user data, default to
measurement and quality control:

- input image count
- preset, scale, and exact command args
- `features.csv` row count and key metric columns
- `viewer.html`, `run_manifest.json`, `viewer-data.json`
- segment and feature overlay images
- stdout/stderr/`rv.log`
- warnings, failures, and suspicious missing artifacts

Only enter comparison mode when the user explicitly has an expected CSV,
official/public result table, previous baseline, or asks for
reproduction/validation/comparison.

## Full CLI Contract

Keep full raw capability available. Use `raw --` when the user needs flags not
exposed by `measure`, including:

- `--roipath`, `--metafile`
- `--recursive`, `--noappend`
- `--distancemap`, `--topology`, `--convexhull`, `--holes`
- `--medialaxis`, `--medialaxiswidth`, `--contours`, `--contourwidth`
- custom `--dranges`
- explicit threshold/filtering/pruning combinations

Use `toolchain --include-help` when the exact installed `rv.exe --help` should
be shown.

## Public-Data Reproduction

Before advising on public-data reproduction, read:

```powershell
<plugin-root>\bin\root-measure.cmd profile
```

Then enforce this sequence:

1. Run `doctor`.
2. Confirm the user has downloaded images, an expected CSV, and a parameter
   source.
3. Run explicit parameters, using `raw --` when public settings require flags
   outside `measure`.
4. Inspect run artifacts.
5. Compare generated `features.csv` to expected CSV.
6. Only claim agreement when `compare` reports `status: exact`, or when the user
   explicitly requested and accepted tolerance-based comparison.

If `doctor` reports a toolchain hash mismatch, treat results as a new baseline
until re-compared.

## Answer Shape

For a successful user-data run, include:

- output directory
- `viewer.html`
- `features.csv`
- preset and scale
- number of input images and result rows
- key metric columns
- warnings or missing artifacts

For failed or partial runs, put exit code, failure reason, and log excerpt first.

For expected-CSV comparison, include status, expected/actual paths or hashes, key
columns, duplicate policy, rows matched, exact rows, diff cell count, maximum
differences, and where diff artifacts were written.

For release checks, state pass/fail first and list only failed checks plus smoke
output folder if useful.
