# Paper-v2 composition gate report — 2026-09-27

The predeclared Gate-B composition screen was run on the 15 V2 development scenarios only. The three candidates were evaluated with the same data, FE budget and paper-core semantics:

| Composition | Add feasible recovery | Penalized FE-to-feasibility | Mean add lateness | Meaning |
|---|---:|---:|---:|---|
| 3 historical / 2 insertion / 1 immigrant | 0.456 | 11.278 | 28.648 | v1 composition |
| 2 historical / 3 insertion / 1 immigrant | 0.511 | 10.333 | 21.200 | candidate selected |
| 2 historical / 2 insertion / 2 immigrant | 0.500 | 10.500 | 23.960 | close second |

Selection rule was fixed before looking at the three outcomes:

```text
Recovery > penalized FE-to-feasibility > lateness > response time
```

Therefore V2 paper-core freezes the **2/3/1** composition. This is a development decision, not holdout evidence. The 15 V2 development scenarios remain development data; V2H01–V2H30 remain sealed.

The 2/3/1 composition increases insertion candidates and reduces redundant historical copies. It should not be described as a universally optimal population ratio. The final paper can report it as a fixed development-selected configuration and include the other two ratios as a small sensitivity/ablation table if useful.
