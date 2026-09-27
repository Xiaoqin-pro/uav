# Paper-v2 development screen report — 2026-09-27

## Scope

V2D01–V2D15 were run on the `paper-v2-development` branch using the new paper-core semantics. This is development evidence only; V2H01–V2H30 remain untouched. Five policies were run: Restart PSO, Warm-PSO, Warm-ALNS, paper-core EAT-PSO and paper-no-reconstruction EAT.

## Run-level summary

| Method | Add feasible recovery | Penalized FE-to-feasibility | Mean add lateness | Response time |
|---|---:|---:|---:|---:|
| Restart PSO | 0.078 | 18.122 | 104.23 | 1.388 |
| Warm-PSO | 0.322 | 14.033 | 44.76 | 1.338 |
| Warm-ALNS | 0.489 | 10.278 | 11.83 | 1.333 |
| EAT-PSO paper-core | 0.456 | 11.278 | 28.65 | 1.315 |
| EAT-NoReconstruction | 0.178 | 17.211 | 58.46 | 1.360 |

The paired development tests show paper-core improves over Restart PSO, Warm-PSO and NoReconstruction on add recovery and penalized FE after Holm correction. Paper-core is not better than Warm-ALNS on recovery or penalized FE and is worse on lateness. This supports the reconstruction mechanism but not universal routing dominance.

## Decision

The V2 core direction is provisionally supported:

- multi-source reconstruction is materially better than the matched no-reconstruction variant;
- canonical guide/unique decoded initialization is retained for the next stage;
- Warm-ALNS remains a strong independent baseline;
- no local search or severity module will be added to EAT.

Before V2 holdout, inspect the per-run source diagnostics and retry wall-time overhead. The current uniqueness guard can perform many pre-FE retries; that CPU cost is correctly included in response time, but it should be reported as an implementation trade-off. Do not tune the retry limit on V2 holdout.

Generated outputs use the `paper_v2_dev` prefix and are development diagnostics only. V2H01–V2H30 remain sealed.
