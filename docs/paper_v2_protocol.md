# Paper-v2 development protocol

## Data separation

- `data/paper_v2_dev_seeds.csv`: 15 fresh development scenarios. Allowed during v2 mechanism tuning and reconstruction audits.
- `data/paper_v2_holdout_seeds.csv`: 30 fresh holdout scenarios. Do not read or execute before v2 is frozen.
- H01–H30 from paper-v1 are historical observed data and may be used for diagnosis, but they are no longer an unseen holdout for v2.

The v2 manifests use disjoint seed ranges from calibration, severity audit, v1 development, v1 holdout and the v1 reserved manifest.

## Restricted mechanism scope

V2 may change only the internal implementation of multi-source reconstruction:

1. canonical random-key guide representation;
2. source composition / route uniqueness;
3. duplicate-route rejection before full FE.

Do not add local search, ALNS operators to EAT, severity tuning, new disturbance types, new window selection, or extra swarm mechanisms. Warm-ALNS remains an external comparator.

## Frozen candidate variants

- `paper-core`: reconstruction ON, guide weight 0.5.
- `paper-no-reconstruction`: reconstruction OFF, guide weight 0.5.
- `adaptive-transfer`: exploratory only; no primary claim.

## V2 success criteria

On the untouched v2 holdout, evaluate at scenario-run level:

1. EAT recovery > Restart PSO, preferably with paired significance;
2. EAT recovery and penalized FE-to-feasibility show a stable improvement over Warm-PSO;
3. paper-core > paper-no-reconstruction on recovery or penalized FE;
4. Warm-ALNS remains an independent comparator, not a method to tune against.

EAT does not need to dominate Warm-ALNS on every endpoint. If Warm-ALNS remains better in final lateness while EAT recovers feasibility earlier, report the trade-off.
