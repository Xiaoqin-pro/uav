# V2 reconstruction audit

Date: 2026-09-27. Branch: `paper-v2-development`.

The pre-change audit used 15 fresh v2 development scenarios and reproduced the current v1 paper-core initialization composition (6 particles: 3 historical, 2 insertion, 1 immigrant) without spending full route-evaluation FE on candidate initialization.

Observed across add events:

- Historical route duplicate rate: exactly 0.667 in the current composition; the three historical particles usually decode to one route.
- Mean unique routes among all six initial particles: approximately 3.4 rather than 6.
- All-route duplicate rate: approximately 0.36–0.50 depending on the scenario.
- The canonical rank representation and the raw jittered key vectors can therefore spend multiple early full FE on the same decoded route.

This confirms a concrete v2 implementation target: route uniqueness before full FE and canonicalization of the current global-best route before guide mixing. It does not prove that the revised method will improve the holdout metrics.

The v2 branch now implements the candidate changes only:

1. `paper-core` and `adaptive-transfer` enforce unique decoded initialization routes with a bounded pre-FE retry; retry CPU time remains in response wall time.
2. Guide mixing uses `RouteToPosition(GlobalBest.Route,...)` rather than the arbitrary raw key vector.
3. `paper-no-reconstruction` remains the matched ablation with fixed guide weight and no multi-source reconstruction.

No v2 holdout was opened. The 15 v2 development and 30 v2 holdout manifests are disjoint and remain unconsumed by this audit.

## V2 implementation smoke check

On V2D01 at an applied post-event state, the v2 paper-core initializer decoded **6 unique routes for 6 particles**. It used 64 pre-FE duplicate retries; those retries invoked no full `EvaluateRoute` and therefore did not consume the 18-route FE budget, but their CPU cost belongs in response wall time. This confirms that the uniqueness guard is active. The high retry count is an explicit diagnostic for the next v2 development screen, not a hidden cost.
