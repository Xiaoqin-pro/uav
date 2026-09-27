# paper-experiment-v1 manifest

## Freeze record

- Freeze date: 2026-09-27
- Git commit before this manifest: `bee16e1abcf81a90566dd32efd4d406f582e9dfc`
- Tag: `paper-experiment-v1` (created after this manifest commit)
- Main algorithms: `PSO`, `Warm-PSO`, `Warm-ALNS`, `EAT-PSO`
- EAT paper-core: multi-source reconstruction ON; guide weight fixed at 0.5.
- EAT reconstruction ablation: `EAT-NoReconstruction`, fixed guide weight 0.5.
- Adaptive severity: `EAT-Adaptive`, exploratory only; not a primary claim.
- Primary dynamic disturbance: externally scheduled add events.
- Secondary policy outcome: cancellation application rate.
- Scenario configuration: severe, window length 135, 8 initial orders, 6 future orders, release start 45, release interval 15.
- Population: 6.
- Maximum full-route evaluations per replanning event: 18.
- Safety samples per leg: 8.
- Primary endpoints: add-event feasible recovery fraction, penalized FE-to-feasibility (`maxFE+1` for no recovery), post-add lateness, response wall time.
- Statistical replicate: one scenario-run; event rows within a run are correlated.
- Planned holdout: 30 paired unseen scenario-runs from `data/reserved_holdout_seeds.csv`.

## Hashes

- `PaperExperimentConfig.m`: `2501195DCF2CF680092B4EDA1AC0F2B181976DC12766728FD8F568F11F9AABDD`
- `data/reserved_holdout_seeds.csv`: `AA87FD5689E0ADC0223C9D88BFDC1B2B22AECBADB6BA86E6BFF9C5C5B1B0FDBD`
- `data/pipeline_dryrun_v1_seeds.csv`: `489E29EA77EF3A32BD4A901467B576001789EAEF97024EE077B2D650578EA1C5`

## Pipeline dry run

The 8 fresh scenarios D01–D08 completed before this freeze using the same manifest runner, algorithms, full FE budget and post-run scripts. The automatic output sequence completed:

```text
RunCoreTests
RunPipelineDryRun
SummarizeAddRecovery
RunPaperStatistics
PlotPaperRecovery
```

The dry run is a pipeline validation, not evidence for the paper. It did not consume H01–H30. The exploratory dry-run table showed Warm-ALNS and EAT-PSO were close; this is a reason to preserve the independent baseline, not a reason to retune the algorithm.

## Holdout rule

After the tag is pushed, do not alter algorithms, scenario generation, evaluation budgets, endpoint definitions or seeds. Run H01–H30 once, then generate the main table, ablation table, recovery curves and paired run-level statistics. Do not add local search or tune a parameter based on holdout outcomes.
