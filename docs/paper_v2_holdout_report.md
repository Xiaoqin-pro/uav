# Paper-v2 holdout report — 2026-09-28

## Execution

The V2 holdout protocol was run once on V2H01–V2H30 after the `paper-experiment-v2` freeze tag. Main comparison: Restart PSO, Warm-PSO, Warm-ALNS and paper-core EAT-PSO. A separate matched ablation run evaluated EAT-PSO, EAT-NoReconstruction and EAT-NoInsertion. No algorithm or scenario changes were made after the freeze.

## Main holdout results

| Method | Add feasible recovery | Penalized FE-to-feasibility | Mean add lateness | Response time |
|---|---:|---:|---:|---:|
| Restart PSO | 0.128 | 17.761 | 151.726 | 1.629 |
| Warm-PSO | 0.350 | 13.567 | 36.180 | 1.472 |
| Warm-ALNS | 0.544 | 9.272 | 13.942 | 1.427 |
| EAT-PSO | 0.589 | 8.872 | 17.828 | 1.460 |

The main holdout supports the core dynamic-recovery claim:

- EAT-PSO is better than Restart PSO on recovery, FE-to-feasibility and lateness.
- EAT-PSO is better than Warm-PSO on recovery, FE-to-feasibility and lateness.
- EAT-PSO has slightly higher recovery and lower penalized FE than Warm-ALNS, but Warm-ALNS has lower final lateness.
- Response time is between Warm-PSO and Warm-ALNS; this is a trade-off, not universal runtime dominance.

## Paired tests

The main paired statistics are in `results/paper_v2_holdout_stats.csv`. The intended interpretation is:

- EAT-PSO versus Restart PSO: strong improvement on the primary recovery endpoints.
- EAT-PSO versus Warm-PSO: strong improvement on recovery, penalized FE and lateness in the frozen output.
- EAT-PSO versus Warm-ALNS: recovery/FE advantage is descriptive and not a universal dominance claim; lateness favors Warm-ALNS and should be reported honestly.

## Matched ablation holdout

| Variant | Add feasible recovery | Penalized FE-to-feasibility | Mean add lateness |
|---|---:|---:|---:|
| EAT-PSO | 0.589 | 8.872 | 17.828 |
| EAT-NoReconstruction | 0.222 | 16.878 | 84.799 |
| EAT-NoInsertion | 0.344 | 13.606 | 36.935 |

The ablation supports both mechanism layers: removing reconstruction is substantially worse, and replacing event-insertion candidates with immigrants also degrades recovery, FE and lateness. This is the strongest evidence for the paper's mechanism claim.

## Artifact hashes

- `results/paper_v2_holdout.csv`: `76EA99BEAB1E178CE5C3E93688B7F610DE7C6357DFFC7CDF65E2FB79628C7835`
- `results/paper_v2_holdout_add_summary.csv`: `590CB5E800AC32520A3B4962D066D536B88BE1EF37D1CED18A7F8EDFEC10807E`
- `results/paper_v2_holdout_stats.csv`: `81EDEB9879377E4475F9BFDA1CAD9497261667A0A109035CBEC5983A6D689ABD`
- `results/paper_v2_holdout_ablation.csv`: `8B74302848A7F68AF43452144DE5A92F7A34DA51E5B7ECD86AB9C6C5ED2828E7`
- `results/paper_v2_holdout_ablation_add_summary.csv`: `49FA33FA6CFA2F39A81F9AD21082D5DB902C1A55D2A866E2CAC1D301F3035497`
- `results/paper_v2_holdout_ablation_stats.csv`: `2151CCF3A289142714F86FFDA1D08317DE5F544116007EFA5284ED93A29A0BDB`

The result CSVs are generated artifacts and remain outside Git. The code/configuration freeze is represented by the `paper-experiment-v2` tag; this report records the post-freeze results.

## Defensible paper conclusion

The paper should claim rapid feasibility recovery under a strict full-route FE budget, not universal dominance. The strongest defensible sentence is:

> EAT-PSO improves post-event feasibility recovery over restart and conventional warm-start PSO, while Warm-ALNS remains stronger in final lateness; matched ablations show that multi-source reconstruction and event-aware insertion both contribute to the recovery behavior.
