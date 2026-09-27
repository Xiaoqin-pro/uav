# Related-work near-neighbor audit

This file is a writing aid and novelty-risk register. Every bibliographic item must be independently checked from its publisher page/PDF before manuscript submission; the pasted external evaluation is not itself a citable source.

| Near neighbor | Problem | Dynamic order/task set? | Historical transfer? | Population reconstruction? | Insertion-informed population? | Difference to our v1 claim |
|---|---|---:|---:|---:|---:|---|
| HeteroDRIME-Lite (2026) | Dynamic routing / replanning | Yes | Yes | Warm-start mixture | Verify exact operator | We do not claim generic warm-start novelty; our claim is the UAV 3-D order-routing evaluation contract and route-sequence multi-source reconstruction under the stated FE budget. |
| DNSGA-II-ALNS (2026) | Dynamic order-set optimization | Yes | Projection/transfer | Algorithm-specific | Yes/verify | We use Random-key PSO with a fixed locked-prefix execution semantics and a separate routing baseline; no first-in-field claim. |
| PPL-ACO (2022) | Dynamic optimization | Yes/verify | Verify | Verify | Verify | Different application and representation; compare mechanism, not novelty by name. |
| Dual-archive PSO (2019) | Dynamic/multiobjective optimization | Yes/verify | Archive memory | Archive-based | Verify | Our paper-core does not claim archive novelty or adaptive severity superiority. |
| Dynamic VRP immigrant methods | Dynamic vehicle routing | Yes | Often | Often | Sometimes | Our contribution is limited to the defined UAV 3-D evaluator, order-set route mapping and paired recovery experiment. |
| Dynamic UAV + PSO studies | UAV task allocation/path planning | Often | Often | Often | Verify | We avoid “first dynamic UAV PSO” wording and compare against an independent routing baseline. |

## Required comparison questions for the literature review

For each final cited paper, record:

1. What changes after an event: order set, task set, graph, objective, or environment?
2. Is the old plan transferred, repaired, projected, archived, or discarded?
3. Is the population reconstructed from multiple sources?
4. Are new orders inserted using route/time-window information?
5. Is the evaluation budget counted by complete objective evaluations?
6. What exactly is different from the paper-core EAT-PSO claim?

## Writing rule

The manuscript must state the boundary of novelty and acknowledge close transfer/warm-start literature. Do not use “novel” as a substitute for a mechanism-level difference.
