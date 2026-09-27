# Paper-v2 NoInsertion ablation report — 2026-09-27

The 15 V2 development scenarios were rerun with the matched reconstruction ablations:

- `EAT-PSO`: 2 historical + 3 event-insertion + 1 immigrant;
- `EAT-NoReconstruction`: reconstruction disabled, fixed guide 0.5;
- `EAT-NoInsertion`: 2 historical + 0 insertion + 4 immigrants, fixed guide 0.5.

| Method | Add feasible recovery | Penalized FE-to-feasibility | Mean add lateness |
|---|---:|---:|---:|
| EAT-PSO | 0.511 | 10.333 | 21.20 |
| EAT-NoReconstruction | 0.178 | 17.211 | 58.46 |
| EAT-NoInsertion | 0.300 | 14.344 | 32.07 |

This development result supports both layers of the reconstruction story: removing the whole reconstruction package is worst, and removing the event-insertion source also degrades recovery, FE and lateness. It is still development evidence, not V2 holdout evidence. The output prefix is `paper_v2_eat_ablation`.

The runner now records source composition, target/actual unique decoded route counts, duplicate retry count and exhaustion flag in event rows. Retry CPU remains part of response wall time; no full-route FE is spent on rejected duplicate candidates.
