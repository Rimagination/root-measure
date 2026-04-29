# Root Measure 0.2.0-beta Release Notes

## Summary

This beta makes `root-measure` behave much more like a self-contained public
plugin instead of a wrapper around a private sibling workspace.

## Highlights

- Bundled `rve-toolchain` is now included for the default plugin path.
- The bundled transparent runner is restored through `scripts/Invoke-RootMeasure.ps1`.
- `doctor` and `release-check` now pass on the default bundled path.
- Default output behavior is aligned across CLI help, README, and tutorial docs.
- Recent-run discovery now follows input-adjacent output with `runs --path`.

## User-facing Changes

- Normal bundled installs should no longer require `--root-measure-root`.
- Default output folders are written next to the input path under
  `root-measure-results\root-measure-<timestamp>`.
- The GitHub Pages tutorial now matches the current CLI behavior.

## Validation

Verified on April 29, 2026 with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-root-resolution.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-bundled-default-doctor.ps1
.\bin\root-measure.cmd doctor
.\bin\root-measure.cmd release-check
```

Expected result for all four checks: pass.

## Notes

- `--root-measure-root` remains available as an advanced override for custom
  backends or development checkouts.
- Internal planning material under `docs/superpowers/` is not part of the
  public release scope.
