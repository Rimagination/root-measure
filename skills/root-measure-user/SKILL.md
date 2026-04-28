---
name: root-measure-user
description: Use when the user asks to analyze root images, run Root Measure, launch a guided workflow, choose scale or presets, inspect outputs, troubleshoot rv.exe logs, compare features.csv, or verify the local Root Measure release.
---

# Root Measure User

## Core Rule

This plugin is a user-facing product, not a script scavenger hunt. Prefer the single front door:

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd <command>
```

Do not ask normal users to open plugin scripts, edit code, or choose between internal `.ps1` files. Use internal scripts only as implementation details or when debugging the plugin itself.

Default response language: Chinese, unless the user asks otherwise. Preserve exact paths, command names, presets, CSV columns, flags, and hashes.

## Product Shape

Use fast routing when the user goal is clear:

- Analyze new data: run `measure`.
- Need help choosing settings: run or describe `wizard`.
- Existing result folder: run `inspect`.
- Where are results: run `runs`.
- Toolchain health: run `doctor`.
- Full RVE control: run `raw -- <rv.exe args>`.
- Public/previous expected CSV comparison: run `compare`.
- Release readiness: run `release-check`.

Use question-style guidance only when the user's goal is unclear. Ask for the minimum missing information: input path, root type/preset, scale (`DPI` or `pixels/mm`) if physical metrics are expected, and whether they need full raw `rv.exe` options.

## Commands

Health check:

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd doctor
```

Guided workflow:

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd wizard
```

Analyze user data:

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd measure --input <path> --dpi 600 --preset broken-roots
```

Whole-root/crown style run:

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd measure --input <path> --pixels-per-mm 13.27 --preset whole-root
```

Inspect a result:

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd inspect --run <dir>
```

List recent runs:

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd runs --limit 10
```

Compare only when the user explicitly has an expected CSV:

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd compare --actual <features.csv> --expected <expected.csv> --key File.Name
```

Forward the full installed RVE CLI:

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd raw -- -r -v -na --segment --feature --convert --factordpi 600 -op <output-dir> -o features.csv <input-path>
```

Release readiness:

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd release-check
```

## User Data vs Reproduction

Most user-provided datasets do not have expected CSVs. For normal user data, do not ask whether they want expected-CSV comparison. Default to measurement and quality control:

- input image count
- preset, scale, and exact command args
- `features.csv` row count and key metric columns
- `viewer.html`, `run_manifest.json`, `viewer-data.json`
- segment and feature overlay images
- stdout/stderr/`rv.log`
- warnings, failures, and suspicious missing artifacts

Only enter comparison mode when the user explicitly says they have an expected CSV, official/public result table, previous baseline, or asks for reproduction/validation/comparison.

## Presets

- `broken-roots` / `broken-roots-exact`: routine broken-root scans.
- `whole-root` / `whole-root-exact`: whole-root/crown style images.
- `custom`: allowed, but report it as an unvalidated parameter combination.

The high-level preset layer is a convenience layer. It does not replace raw `rv.exe`.

## Full CLI Contract

Keep full raw capability available. Use `raw --` when the user needs flags not exposed by `measure`, including:

- `--roipath`, `--metafile`
- `--recursive`, `--noappend`
- `--distancemap`, `--topology`, `--convexhull`, `--holes`
- `--medialaxis`, `--medialaxiswidth`, `--contours`, `--contourwidth`
- custom `--dranges`
- explicit threshold/filtering/pruning combinations

Use `root-measure toolchain --include-help` when the exact installed `rv.exe --help` should be shown.

## Public-Data Reproduction

Before advising on public-data reproduction, read the codified validation-history profile:

```powershell
D:\VSP\plugins\root-measure-user\bin\root-measure.cmd profile
```

Then enforce this sequence:

1. Run `doctor`.
2. Confirm the user has downloaded images, an expected CSV, and a parameter source.
3. Run explicit parameters, using `raw --` when the public workflow needs flags outside `measure`.
4. Inspect the run artifacts.
5. Compare generated `features.csv` to expected CSV.
6. Only claim agreement when `compare` reports `status: exact`, or when the user explicitly requested and accepted tolerance-based comparison.

If `doctor` reports a toolchain hash mismatch, treat results as a new baseline until re-compared.

## Gotchas To Apply

Use `profile` or `docs\reproducibility-gotchas.md`; do not rely on memory alone. Key pitfalls:

- GitHub `imageexamples` are smoke tests, not numeric oracles.
- Do not silently assume DPI.
- Official GUI output is not automatically CLI output.
- `--metafile` is not a universal automation solution.
- Duplicate expected `File.Name` rows need `--duplicate-key-mode BestMatch` or another explicit policy.
- Exclude volatile `Computation.Time.s` unless the user intentionally compares it.
- Analyzer/Crown tables are not automatically Explorer numeric expected tables.
- Whole-root exactness depends on root type, threshold, inversion, scale, pruning, diameter ranges, and orientation behavior.
- Large concatenated images can be slow or memory-heavy; keep logs and partial artifacts.

## Answer Shape

For a successful user-data run, include:

- output directory
- `viewer.html`
- `features.csv`
- preset and scale
- number of input images and result rows
- key metric columns
- generated artifact inventory
- warnings or missing artifacts

For failed/partial runs, put exit code, failure reason, and log excerpt first.

For expected-CSV comparison, include status, expected/actual hashes, key columns, duplicate policy, rows matched, exact rows, diff cell count, max differences, and where diff artifacts were written.

For release checks, state pass/fail first and list only failed checks plus smoke output folder if useful.
