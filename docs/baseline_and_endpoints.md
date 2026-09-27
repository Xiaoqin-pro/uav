# Independent routing baseline and primary endpoints — development protocol

Recorded before the five-new-seed dry run. The reserved 30 holdout tuples remain untouched.

## Independent baseline contract

`Warm_ALNS.m` is a **self-implemented, compact ALNS-inspired baseline**, not a verified reproduction of a particular published ALNS codebase. It carries forward the prior route, samples one of two removal operators (random or high-marginal/late), and one of two repair operators (greedy or regret-2 insertion). Operator weights update from accepted improvement. It calls the same `EvaluateRoute` exactly once per completed candidate. Surrogate route scoring and operator choice do not call that full evaluator; their cost is included in response wall time. The same locked-prefix and no-cancel-in-progress rules apply. Its initial reference-seeded PSO plan and FE cap are shared with every other online policy.

Before calling it a *strong* baseline in a paper, independently inspect route/evaluator semantics and see whether it is competitive over multiple scenarios. A clean-room compact implementation is not the same thing as fidelity to a published method.

## Primary end points to freeze before holdout

The main mechanism analysis uses **add events only**, because the externally scheduled add requests apply to every policy. For each scenario run and algorithm, average across that run's add events, then treat runs (not event rows) as independent replicates:

1. Add-event feasible recovery fraction (primary).
2. Mean exact first-feasible FE after add; non-recovery is explicitly censored to `maxFE + 1`, always reported alongside feasible fraction (primary).
3. Mean post-add total lateness (primary quality).
4. Mean post-add optimizer wall time (engineering metric; offline map/reference generation excluded).

Distance is secondary. Safety violations verify constraints rather than serve as the headline gain. Cancellation application rate is a separate policy-level outcome; it is **not** pooled into the primary paired add-event denominator. All rows are retained in raw output.

`SummarizeAddRecovery.m` implements these definitions. `PlotRecoveryDiagnostic.m` now filters to applied add events and aggregates event checkpoint values within each run before summarizing across runs. The descriptive curve alone is not a significance test.

## Five-new-seed dry run

Same severe candidate and budget as calibration: future window 135, 8+6 orders, release start 45 and interval 15, safety samples 8, population 6, maxFE 18. Algorithms are Restart PSO, Warm-PSO, Warm-ALNS and Full EAT-PSO. New seed bases are `20350000 / 20351000 / 20352000 / 20353000`, runs 1..5; none is a reserved holdout tuple. Output prefix `independent_baseline_dev5`.

This dry run checks baseline competitiveness and output/metric integrity. It is **not** a basis for choosing a different time-window setting, adding algorithm modules, or making SCI claims. If EAT fails against ALNS, record that result and revisit the paper hypothesis before using the reserved holdout.
