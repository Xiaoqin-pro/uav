# Severity mechanism audit — development-only protocol

Written before the new-seed diagnostic run. The reserved 30 holdout tuples must not be used here. No algorithm or scenario generator change is permitted between this protocol and the audit result.

- Scenario: the baseline-only-selected **severe / future-window 135**, 8 initial and 6 future orders, release `45 + 15k`, 6 particles, 18 full route evaluations per event, safety sample count 8.
- New development seed bases: terrain `20286500`, order `20286600`, event `20286700`, optimizer `20286800`, runs `1..5`. These do not overlap the screen, confirmation, earlier EAT development set, or reserved holdout manifest.
- Policies: Warm-PSO, EAT-FixedSeverity (weight 0.5), Full EAT-PSO. The initial reference-seeded plan and exogenous events are shared.
- Audit only *applied add* events. Cancellation requests are policy-dependent and remain secondary. Match `(run,eventIndex)` across policies.
- Three fixed severity bands: low `<0.20`, medium `[0.20,0.50)`, high `>=0.50`. These are diagnostic bins, **not** additional dataset-selection criteria.
- Inspect min/median/max/std of severity, component ranges, and run-aggregated feasible rate, mean lateness, and capped first feasible FE (`maxFE+1` for no recovery) by band. A bin with few events or runs cannot support a conditional conclusion.
- Decision: if the severity support is narrow or bands poorly represented, do not claim an adaptive advantage. Do **not** alter weights or add burst events after viewing EAT results. A future burst-event study would require a separately documented baseline-only calibration and a distinct experiment protocol, not reusing this selected scenario as if prospectively chosen.
