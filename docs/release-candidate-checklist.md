# Release Candidate Checklist

This checklist is for deciding whether `root-measure` is ready to publish as a
new public beta or release candidate.

## Product Gate

- The default install path is self-contained for normal users.
- A normal user does not need `--root-measure-root` or `ROOT_MEASURE_ROOT`.
- The plugin does not depend on a private sibling workspace such as
  `D:\VSP\root-measure`.
- README, install docs, usage docs, and GitHub Pages tutorials describe the
  same default behavior.
- Default output paths are documented consistently as
  `root-measure-results\root-measure-<timestamp>`.

## Toolchain Gate

- `tools\rve-toolchain\rv.exe` is present in the plugin repo or release bundle.
- `tools\rve-toolchain\cvutil.dll` is present in the plugin repo or release bundle.
- Expected validated SHA256 hashes still match in `doctor` and `release-check`.
- `Invoke-RootMeasure.ps1` exists in the plugin repo and is the active bundled
  transparent measurement path.
- `invoke-rv.ps1` can forward `--version` without an external root override.

## Verification Gate

Run these commands from the plugin repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-root-resolution.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-bundled-default-doctor.ps1
.\bin\root-measure.cmd doctor
.\bin\root-measure.cmd release-check
```

Expected results:

- both tests print `PASS`
- `doctor` returns JSON with `"status": "pass"`
- `release-check` returns JSON with `"status": "pass"`
- smoke-run artifacts are created under the plugin repo `runs\` directory

## Documentation Gate

- `README.md` includes the GitHub Pages tutorial link in both Chinese and English sections.
- `docs/installation.md` explains the difference between a bundled release and
  an advanced custom backend override.
- `docs/usage.md` matches current CLI behavior for output paths and run lookup.
- `docs/index.md` does not contain broken local links for GitHub Pages readers.
- `docs/getting-started/index.md` examples match the real output directory shape.

## Packaging Gate

- `.gitignore` excludes runtime output and static-site build output.
- No accidental private-path references remain in user-facing docs except as
  negative examples or troubleshooting context.
- No smoke-run output, local cache, or temporary release bundle is staged.
- `git status --short` shows only intentional release changes.

## Decision

Publish only when every gate above is satisfied. If one fails, keep the build in
beta hardening and fix the mismatch before release.
