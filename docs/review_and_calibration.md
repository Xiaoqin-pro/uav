# 外部评价采纳与数据校准记录（2026-09-27）

## 采纳的判断

- 不继续堆叠多无人机、动态障碍、风场或多目标模块；先验证动态事件后的搜索状态迁移。
- `lockedOrderIDs` 的语义必须在优化编码中落实。已经将锁定目标固定为路线前缀，后续订单才允许由 PSO 排序；重复事件不会重置飞行到达或服务结束时刻。
- 原来的事件严重度只有订单变化比例，不足以称为事件影响度。现将订单集合变化、截止时间压力变化和旧路线绕行代理量归一化，作为 **待消融的假设**，不预称有效。
- 原 `RunScenarioAudit` 仅证明生成规则有区别。新增只用 PSO/Warm-PSO 的盲校准入口，报告实际事件接受率、可行率和迟到。
- `priority` 字段目前不参与选择，不能在论文中宣称“优先级优化”。
- 以同一场景、同一算法种子和同一 FE 预算比较 PSO、Warm-PSO、EAT 及两个消融版本。

## 暂不采纳或保留意见

- 附件所说的“已经进入论文证据生产阶段”过于乐观：下述初步校准发现默认数据过于容易。正式 30 次实验应等问题数据和审计规则冻结后运行。
- 简单地固定某个 30 组随机种子和做 Wilcoxon 并不能自动证明 SCI 二区质量；强基线、数据来源及机制新颖性仍需独立审查。
- 静态 CEC 函数不能直接检验订单增删的维数变化。先把动态 UAV 评价链打通，之后再决定是否需要通用动态 benchmark，不能以当前仿真代替标准算法测试。
- 附件中的不可解析引用标记不是可核验文献，本记录不据此声明查新结论。

## 盲校准观察（仅开发诊断，不可进论文）

使用两组配对场景、每等级 8 个初始订单、6 个未来订单、PSO/Warm-PSO、每次规划 48 FE：默认 mild/moderate/severe 的**事件后可行率均为 1.0**，迟到均为 0。尽管事件数量及时间窗不同，默认数据不足以证明不同难度。部分取消请求因目标已服务或锁定而未应用；现在显式记录 `eventApplied`，不可把“请求数”当成“实际订单变化数”。

另以单组种子、severe、8+6 订单、每次规划 18 FE、释放从 45 开始且间隔 15、不同时间窗长度做盲筛选（只运行 PSO/Warm-PSO）：

| 窗口长度 | PSO 事件后可行率 | Warm-PSO 事件后可行率 | 说明 |
|---:|---:|---:|---|
| 95 | 0 | 0 | 过难 |
| 115 | 0 | 0 | 过难 |
| 135 | 1/9 | 1/9 | 有过渡迹象 |
| 155 | 2/9 | 7/9 | 明显受策略影响 |

这些只是**单组种子、9 个相关事件**的诊断，不能视为独立样本或结论。下一轮应扩大仅基线的种子数、分实例汇总并预注册筛选规则；不允许根据 EAT 的胜负选择数据。

## 当前关键局限

1. 时间窗和未来订单仍为程序化合成数据，不是现实订单；工程背景必须诚实标注为仿真案例。
2. 航点设在地形最高点以上，三维安全航段通常均可行，主要难度来自订单时间窗，不应伪称地形碰撞是算法主要增益来源。
3. 各算法在线执行的历史不同，虽然外生订单事件表一致，但事件时 UAV 状态可能不同。严格解释为**同一事件流下的在线策略比较**，不把每个事件行当独立配对样本。
4. 当前 `RunFormalBenchmark` 是开发实验入口，默认 3 次运行不能用于论文；结果目录中的 pilot CSV 不应引用到稿件。

## Reference-feasible data contract and multi-seed follow-up

The earlier one-seed 95/115/135/155 screen above was generated **before** guaranteeing a feasible initial route. It is superseded for scenario selection. The new generator creates a deterministic nearest-neighbor initial reference, derives each initial due time using the actual `Plan3DLeg` flight time plus level-specific slack, and verifies that route. Every online algorithm receives the same reference-seeded initial PSO plan; later policies diverge naturally. Future orders remain exogenous. This synthetic construction must be declared in any eventual paper.

Under this new contract, the baseline-only 4-seed screen (8+6 orders, severe, 18 FE per replan, release 45+15k) produced the following **mean of per-run metrics**:

| Future window | Initial plans feasible | Mean add applied | Mean cancel applied | Mean applied-event feasible (PSO and Warm-PSO pooled) | Pilot rule |
|---:|---:|---:|---:|---:|---|
| 135 | all | 1.000 | 0.792 | 0.382 | pass |
| 155 | all | 1.000 | 0.833 | 0.481 | pass |
| 175 | all | 1.000 | 0.792 | 0.604 | pass |

The prespecified smallest-passing rule nominates window **135**. An independent baseline-only six-seed confirmation (different terrain/order/event/algorithm seed bases) produced initial feasible rate 1 for both methods, add applied rate 1, mean cancellation applied rate 0.611, and pooled run-mean applied-event feasible rate approximately **0.314**. The individual means were **0.042** for Restart PSO and **0.586** for Warm-PSO; these are diagnostic, correlated-event measurements over six scenarios, not significance evidence. In this regime warm-start already provides a strong challenge, so no claim of EAT superiority is justified.

Generated raw CSVs remain in `results/` and are not versioned as publication evidence. SHA-256 of `blind_window_screen.csv`: `fb5cbc5958bbbefd56b97930f20153d6b03b426d5cd5da33f211b48b67c2478f`. SHA-256 of `confirm_w135_6seeds.csv`: `9a5651341dc97d7f6efe2bdc0328bc074cf259e984133be5d6302295412f10fb`. Both correspond to the code state before this log-only edit.

**Next gate:** review per-event online trajectories and a limited EAT development set with seeds disjoint from the 30 reserved holdout tuples. The candidate remains provisional; do not run the reserved tuples or write Results claims until the mechanism and evaluation contract are frozen.

## Disjoint EAT development pilot (not confirmatory)

After committing the blind-selection protocol, four new development seed triples (bases `20282000/20283000/20284000/20285000`, distinct from pilot, six-seed confirmation and reserved holdout) were run on the nominated severe / 135 candidate with 18 full route evaluations per replanning event. The following is the **mean of four per-run summaries**, not 36 independent samples:

| Method | Applied-event feasible fraction | Mean event lateness (all requested events) |
|---|---:|---:|
| Restart PSO | 0.031 | 139.54 |
| Warm-PSO | 0.313 | 36.41 |
| EAT without reconstruction | 0.250 | 41.37 |
| EAT with fixed severity | 0.442 | 17.90 |
| Full EAT-PSO | 0.442 | 14.95 |

The full method did **not** improve feasible fraction over the fixed-severity variant in these four development runs. Lateness differences are inconsistent run by run, so the pilot does not establish the adaptation mechanism. The reconstruction ablation looks more promising, but sample size is too small for a claim. The current paper story must remain conditional; do not add modules just to manufacture a win.

Machine-generated diagnostic summary: `results/candidate_w135_dev4_summary.csv`, SHA-256 `8640099dc9b6fa40d1dfa7c9b2edfc26fe6909e3f1b865769312848381f42727`. These data use synthetic orders and are **not** publication evidence. An independent single-seed smoke test now verifies recovery traces at FE checkpoints and `PlotRecoveryDiagnostic` creates an explicitly exploratory plot; its curves should not be interpreted as a multi-seed comparison.

The 30 reserved holdout scenarios remain unused. Before evaluating them: review the event-severity mechanism, preserve a non-PSO strong baseline plan, lock a full experiment configuration, and compute run-level paired statistics with honest FE and wall-time accounting.

## FE recovery instrumentation

After the four-seed development pilot, the runner was instrumented to record (a) the **exact evaluation index** at which a feasible route is first seen, (b) best-known feasibility/lateness at population/iteration FE checkpoints, and (c) the three severity components and actual guide weight. `SummarizeDynamicRuns` uses a scenario-run as its unit of replication. `PlotRecoveryDiagnostic` averages applied events *inside* each run before summarizing runs. Its single-seed smoke-test figure only verifies the pipeline; it is not a manuscript figure. The four-seed pilot table above predates these added diagnostic columns; the algorithmic decision rules were not changed by this instrumentation.

In the four development scenarios the mean number of active orders at an applied event ranged from roughly 7.1 (EAT-PSO) to 7.8 (Restart-PSO); these online state differences are part of each strategy's trajectory. Every applied event in this small pilot occurred with one locked target, validating that the fixed-prefix rule is exercised. These observations do not substitute for an independent multi-seed mechanism analysis.
