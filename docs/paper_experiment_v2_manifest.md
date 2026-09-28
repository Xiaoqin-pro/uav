# paper-experiment-v2 freeze manifest

- Freeze date: 2026-09-28
- Branch: `paper-v2-development`
- Main paper-core: `EAT-PSO`, source composition `[2 3 1]`.
- Matched ablations: `EAT-NoReconstruction`, `EAT-NoInsertion` `[2 0 4]`.
- Exploratory only: `EAT-Adaptive`.
- Main algorithms: Restart PSO, Warm-PSO, Warm-ALNS, EAT-PSO.
- Scenario: severe, future window 135, 8 initial + 6 future orders, release start 45, interval 15.
- Population: 6; max full-route evaluations per event: 18; safety samples: 8.
- Primary endpoints: add-event recovery fraction, penalized FE-to-feasibility (19 if censored), post-add lateness, response time.
- Statistical unit: scenario-run; event rows inside a run are correlated.
- V2 development: V2D01–V2D15, composition gate, NoInsertion ablation, and V2P01–V2P05 pipeline-only dry run completed.
- V2 holdout: V2H01–V2H30 remains sealed at this freeze point.

## Required checks completed

- `RunCoreTests` passed.
- Source composition is passed from `PaperExperimentConfig` through `RunManifestBenchmark` and `RunDynamicEpisode`; no hidden hard-coded paper-core composition remains.
- Alias check: 321, 231 and 222 map to their declared compositions.
- `paper-no-reconstruction` and `paper-no-insertion` use fixed guide weight 0.5.
- Decoded-route uniqueness and retry metadata are recorded.
- Main and ablation output families are separated for statistics.
- V2 pipeline-only manifest completed all 5 scenarios and all configured policies.

## Hashes

Record the final hashes with PowerShell immediately before creating the tag:

```powershell
Get-FileHash .\PaperExperimentConfig.m -Algorithm SHA256
Get-FileHash .\data\paper_v2_holdout_seeds.csv -Algorithm SHA256
Get-FileHash .\data\pipeline_dryrun_v2_seeds.csv -Algorithm SHA256
```

No V2 holdout results may be generated before this manifest and the freeze tag are committed and pushed.
