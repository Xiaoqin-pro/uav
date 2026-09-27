# Deterministic rejection of unsafe synthetic initial instances

On September 27, 2026, the independent-baseline dry run encountered an initial reference route with a genuine 3-D safety violation (`totalViolation = 0.0127124`, lateness 0). Previously `BuildScenario` correctly aborted but could not advance past that seed. Relabeling this path feasible or removing the offending obstacle would be invalid.

`BuildScenario` now applies a bounded **whole-order-realization rejection** procedure under `initialWindowMode='reference'`:

1. Keep the terrain seed and event seed fixed.
2. Attempt order seed `requestedOrderSeed + (attempt-1)*1000003`, at most 32 attempts. This stride avoids overlapping consecutive requested order seeds in the screen and reserved manifest.
3. For each complete order realization, derive the initial nearest-neighbor reference time windows and re-evaluate the complete reference route with the same `EvaluateRoute` and `Plan3DLeg` used by all algorithms.
4. Accept only if the route meets both time and safety constraints; otherwise reject the whole order realization. Record `effectiveOrderSeed` and `orderGenerationAttempts` in scenario and machine-readable benchmark rows. If all attempts fail, error rather than silently relaxing constraints.

This is an **input data definition change**, not an algorithm result. The already completed blind screen (4 seeds), independent baseline confirmation (6 seeds), EAT development and severity diagnostics all used initial realizations that were accepted on attempt 1; regeneration confirmed the ten screen/confirmation seeds still use attempt 1. Their numerical results are unchanged by this rejection rule. The interrupted independent-baseline dry run must be rerun from scratch on the new version. Any future seed with attempt >1 is a different order realization and its effective seed must appear in every result manifest. Rejection frequency should be reported when a final dataset is frozen; exceptionally high rejection would require revisiting the physical scenario generator rather than hiding it.
