# Severity audit decision — 2026-09-27

This decision uses the predeclared five new development seed triples in `docs/severity_audit_protocol.md`. It does **not** open the reserved 30 holdout scenarios.

## Observed support (applied add events only)

Across 5 scenario runs and 30 applied add events, Full EAT severity was min **0.0567**, median **0.0727**, max **0.2040**, SD **0.0376**. The fixed diagnostic bands contained **29 low**, **1 medium**, **0 high** events. Component ranges were: order-set change **0.111–0.167**, deadline-pressure change **0–0.0449**, route impact **0.00026–0.479**. This confirms that single-order events in the selected data barely exercise the adaptive guide-weight range.

Descriptive event counts (not independent replicates): Full EAT was feasible on 11/30 applied add events, Fixed-0.5 on 15/30, Warm-PSO on 5/30. Mean lateness over those events was about 22.87, 23.49, and 39.36 respectively. No inferential test is claimed at event level; online trajectories and cancellation application can differ by policy.

The machine-generated distribution file is `results/severity_newdev5_distribution.csv`, SHA-256 `b9260af5b4c462e9a3d204a81de1280fde2f85c88f8c98272592e4ed4cecd53a`. The event-level and run-band CSVs share the same `severity_newdev5` prefix; these are development diagnostics, not manuscript evidence.

## Decision

**Do not claim that severity adaptation is independently effective.** Keep the score only as an explicitly exploratory implementation heuristic. The main contribution under test is *event-triggered multi-source population reconstruction and route transfer*. The fixed-weight ablation remains as a control; there is no justification to tune `{0.25,0.5,0.75}` for an adaptive-superiority claim under this narrow event distribution.

Do not alter the event generator or pick a new future window after inspecting EAT outcomes. A future burst-event investigation would be a separately designed problem/data study with baseline-only recalibration and separate holdout; it must not be retroactively folded into this candidate.

Next priority: independently implemented, fairly counted routing baseline, followed by run-level primary-endpoint agreement. The 30 reserved holdout tuples remain unused.
