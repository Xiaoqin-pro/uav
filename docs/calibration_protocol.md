# Blind calibration protocol — registered before the multi-seed screen

Status: development protocol, **not** a manuscript benchmark definition. This protocol was written before the multi-seed baseline screen and is committed before interpreting any EAT-PSO results under the new data contract.

## Data contract

1. Fix one static 3-D terrain seed per scenario realization. Construct initial orders and a deterministic nearest-neighbor reference route. Use the same `Plan3DLeg` evaluator to derive initial time windows from reference service arrivals plus a level-specific slack (mild 100, moderate 65, severe 35 time units). Re-evaluate and assert the reference is feasible. This only proves *existence* of an initial feasible route, not that PSO will find an optimum.
2. All methods start from the identical reference-seeded PSO initial plan and use the same exogenous event schedule, optimizer seed, initial population and FE cap. Subsequent online UAV states may diverge naturally.
3. Future-order due times are `release + 10 + windowLengthOverride`; release timing and window width are exogenous factors, not algorithm output. All orders, maps and events are synthetic.
4. Cancellation requests can fail because the order was already served or is locked. Retain the rejected event in output; report cancellation application separately. Never convert a rejected event into an applied event post hoc.

## Blind pilot screen

Only `PSO` and `Warm-PSO` may be run. Candidate severe future-order windows are **135, 155, 175** time units, with 8 initial + 6 future orders, release times starting at 45 separated by 15, population 6, 18 full evaluations per replan, safety sampling 8, and 4 fixed seed triples generated in `RunBlindWindowScreen.m`. These values test whether the static-window defaults were too easy; they were specified before seeing EAT results under the reference-feasible initial data contract.

The pilot is acceptable for *further confirmation* when all of the following hold across run-level summaries:

- Every constructed initial reference and every reference-seeded initial plan is feasible.
- All add events apply; at least half of cancellation requests apply on average across baselines.
- The pooled, **per-run** mean applied-event feasible rate of PSO/Warm-PSO is between 0.15 and 0.85 inclusive, avoiding trivial all-feasible/all-infeasible data.
- No single method is used to pick the candidate based on EAT performance. If multiple windows pass, use the smallest window; if none pass, report failure and revise the data model explicitly before another screen.

Four seeds are only a pilot. A passing window is a candidate, **not a frozen paper dataset**. Repeat with an independent, larger *baseline-only* seed set and review per-event trajectories before freezing a final protocol. The eventual 30 evaluation seed triples must be separate from pilot/confirmation triples.

## Outputs and interpretation

`RunBlindWindowScreen` writes a per-window run-level CSV, an event-level CSV and a screen summary CSV under `results/`. These are machine-generated diagnostics. Event rows within one run are correlated; do not treat them as independent statistical replicates. The core effect must be evaluated at the run/scenario level. Dynamic response time includes optimization and severity/insertion computation but excludes offline scenario generation and reference construction.

## Provisional outcome and reserved seeds

The candidate selected by the predeclared smallest-passing-window rule is **135** (severe future orders); the six-seed independent baseline confirmation also meets the nondegeneracy checks. This is a *development candidate*, not an accepted manuscript benchmark. The 30 scenario/algorithm seed tuples in `data/reserved_holdout_seeds.csv` are reserved and have not been used in any calibration or EAT development run. They should only be consumed once the algorithm and dataset definitions have been reviewed and frozen.
