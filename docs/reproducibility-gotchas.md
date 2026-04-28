# Root Measure Reproducibility Gotchas

This file captures project history that should guide generic user workflows. It is not a dataset-specific validator.

## Rules To Preserve

- Small `imageexamples/scans` and `imageexamples/crowns` runs are smoke tests, not numeric oracles.
- Official/public agreement requires an expected CSV comparison for that run.
- Check `rv.exe` and `cvutil.dll` hashes before reusing previous validation claims.
- Do not silently assume DPI. Require explicit DPI or pixel units when metadata is absent.
- Do not trust paper-visible settings as a complete executable configuration. Saved RVE settings may include extra toggles.
- Do not rely on `--metafile` for exact automation. Translate metadata/settings CSV values to explicit CLI flags.
- Exclude `Computation.Time.s` from exact numeric comparisons unless runtime is the target.
- Use Explorer-origin expected CSVs for Explorer validation. Do not use RhizoVision Crown or Analyzer tables as Explorer numeric oracles.
- Treat hash changes as a new baseline until public expected CSVs have been re-compared.

## Known Historical Traps

- Copper-wire exactness required preserving official histogram-derived length behavior rather than upstream `getrootlength_new` overwrite behavior.
- Multispecies exactness required the current ABI plus official `cvutil` 2.0.2 skeleton/distance-transform behavior. A naive boundary-size patch crashed and is not a safe route.
- Multispecies maize official rows include duplicate `File.Name` values. Use `compare-features.ps1 -DuplicateKeyMode BestMatch` when an expected CSV has duplicate keys.
- Zenodo `8083525` whole-root exactness depends on closed-form 2D covariance PCA orientation behavior. OpenCV `cv::eigen` axis selection produced previous residuals in orientation and angle-frequency metrics.
- Zenodo `12667584` / `12668178` exact reproduction required `--bgnoise --bgsize 1`; the visible paper settings alone were incomplete.
- Large concatenated images can fail from memory pressure in batch mode. Retry per image in a fresh process before treating an input as impossible.
- Zenodo `4677553` is a paper statistics workflow. It needs R compatibility fixes and reconstructed simulated-root data; it is not a generic direct CLI oracle.

## Generic Reproduction Flow

1. Run `doctor.ps1`.
2. Collect images, expected CSV, and parameter source.
3. Run `rv.exe` through `invoke-rv.ps1` with explicit flags, or use `measure.ps1` only when its preset covers the public workflow.
4. Inspect the output directory and preserve manifest/log/hash artifacts.
5. Run `compare-features.ps1` against the expected CSV.
6. Report `exact` only when the comparator reports `status: exact`.
