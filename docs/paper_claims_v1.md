# Paper claims v1

## Working title

**Event-Triggered Multi-Source Population Reconstruction for Rapid Feasibility Recovery in Dynamic 3-D UAV Delivery Routing**

## Claims allowed in the manuscript

### C1 — Problem
Dynamic 3-D UAV delivery routing can lose feasibility after online order-set changes. Under a strict post-event full-route evaluation budget, the practical objective is rapid recovery of an executable route rather than universal final-cost dominance.

### C2 — Method
EAT-PSO uses event-triggered multi-source population reconstruction after the active order set changes. The new population combines:

1. historical-route transfer;
2. event-aware insertion candidates;
3. diversity immigrants.

The paper-core version uses a fixed guide weight of 0.5. Severity-adaptive transfer is retained only as an exploratory variant and is not a primary contribution.

### C3 — Evidence
The method is evaluated on paired, unseen scenario-runs against Restart PSO, Warm-PSO and Warm-ALNS under a common full-route evaluation budget. Primary evidence focuses on add-event feasibility recovery, penalized FE-to-feasibility, post-add lateness and response wall time.

## Exact terminology

Use:

- “30 paired unseen scenario-runs”;
- “reserved held-out dynamic scenarios”;
- “scenario-run is the statistical replicate”;
- “add-event recovery”;
- “penalized FE-to-feasibility”;
- “Warm-ALNS-inspired independent routing baseline” unless a published implementation is independently reproduced and verified.

## Do not claim

Do not claim that EAT-PSO is:

- the first dynamic PSO;
- the first warm-start PSO;
- the first historical-transfer PSO;
- the first random-immigrant method;
- the first dimension-changing transfer method;
- a universally superior optimizer;
- proven superior on all metrics to ALNS;
- theoretically convergent because of these mechanisms;
- validated as a severity-adaptive contribution;
- a real-world UAV deployment study.

Do not describe synthetic reference-feasible instances as field data. State that terrain, orders and events are controlled synthetic data designed for reproducible rolling-replanning experiments.

## Algorithm variants frozen for v1

- `EAT-PSO` → `paper-core`: reconstruction ON, guide weight 0.5.
- `EAT-NoReconstruction` → `paper-no-reconstruction`: reconstruction OFF, guide weight 0.5.
- `EAT-Adaptive` → `adaptive-transfer`: reconstruction ON, severity guide weight; exploratory/supplementary only.

The final primary table uses `EAT-PSO`, not `adaptive-transfer`.
