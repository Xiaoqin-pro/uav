# Dynamic 3-D UAV Order Routing

本项目是“事件感知种群迁移粒子群优化算法（EAT-PSO）”的干净开发仓库。

## 当前研究问题

单架无人机在三维地形和建筑障碍物环境中执行带时间窗的订单配送。无人机执行过程中会发生：

- 新订单到达；
- 已有订单取消；
- 订单集合、时间窗和可行域随事件变化。

当前开发阶段先建立可信的问题数据定义、三维航段评价和 Random-key PSO 基线，再实现事件感知种群重构算法。

## 研究边界

第一版只研究：

- 单架无人机；
- 单仓库；
- 动态新增订单和订单取消；
- 三维地形与静态箱体障碍物；
- 时间窗、服务时间和订单优先级；
- 滚动重规划。

暂不加入：

- 多无人机协同；
- 动态障碍物；
- 风场与复杂能耗模型；
- 多目标 Pareto archive；
- 多种局部搜索的堆叠。

## 目录

```text
src/          问题定义、三维环境、评价器和算法
experiments/  可复现实验入口
results/      运行输出，不手工修改
 docs/        问题规格和实验设计
```

## MATLAB 运行

```matlab
cd('D:\111\Desktop\噜噜\new');
setup;
RunSmokeTest;
RunScenarioAudit;

% 小规模配对动态实验
o.nRuns = 1; o.levels = {'mild'};
o.nInitialOrders = 4; o.nFutureOrders = 2;
o.safetySamples = 10; o.Particle_Number = 4; o.maxgen = 2;
RunFormalBenchmark(o);
```

当前 main.m 和 smoke test 会：

1. 生成固定随机种子的三维场景；
2. 生成初始订单和动态事件；
3. 运行 Random-key PSO 基线；
4. 应用一个动态事件；
5. 对事件后的订单集合再次规划；
6. 输出 CSV/MAT 和三维场景图。

所有论文候选结果必须在后续正式实验中重新运行，当前 smoke test 只验证数据链路和代码接口。

## 与老师示例代码的结构对应

为了保持和老师给出的 `main.m / PSO.m / LMS.m` 风格一致，仓库根目录提供了扁平入口：

```text
main.m          一键实验入口
PSO.m           Random-key PSO baseline
EAT_PSO.m       事件感知种群迁移 PSO
CreateModel.m   场景生成入口
Fitness.m       路线适应度入口
DynamicEvent.m  动态事件入口
ExecuteUntilEvent.m  执行到事件时刻并更新无人机状态
RunEpisode.m    按事件序列运行完整动态过程
PlotSolution.m  结果绘图入口
```

较长的实现放在 `src/`，根目录函数只负责保持清晰、可直接运行的算法对比接口。这样既保留老师示例中“主程序调用多个算法、记录收敛曲线、统一绘图”的结构，也避免把数据生成、评价器和算法全部写进一个 `main.m`。

运行：

```matlab
cd('D:\111\Desktop\噜噜\new');
main;
```

`main.m` 当前只是小规模演示入口，正式论文实验不会使用该演示规模，也不会把演示输出直接当作论文结论。
## 语义审计与开发诊断

外部评价中正确指出了锁定订单重排、事件严重度和难度校准问题。修复过程及未解决局限记录于 `docs/review_and_calibration.md`。当前所有 CSV/MAT 都是开发诊断，不得直接用于论文。

```matlab
addpath('tests'); RunCoreTests;             % 状态和 FE 不变量
RunDifficultyCalibration;                   % 仅 PSO/Warm-PSO 的盲校准
RunAblation;                                % 两个机制的开发级消融
```

根目录还提供 `Warm_PSO.m`、`RunDifficultyCalibration.m` 和 `RunAblation.m`。正式实验须先冻结场景生成规则、独立种子及统计口径。
## Blind calibration status (2026-09-27)

Current initial-order windows are constructed from a deterministic, independently evaluated reference route, so every generated initial scenario has at least one feasible plan. Future arrivals remain exogenous synthetic orders. The baseline-only window screen nominated **severe / future window 135** for independent confirmation; this is a **development candidate**, not a publishable result. See `docs/calibration_protocol.md` and `docs/review_and_calibration.md` for the criteria, seed sets, raw-result hashes, and limitations.

`RunBlindWindowScreen` uses only PSO and Warm-PSO. `data/reserved_holdout_seeds.csv` contains 30 disjoint tuples reserved for later use; do not consume them during algorithm development. The current `RunAblation` and `RunFormalBenchmark` are development interfaces, not the final statistical pipeline.

## Event recovery diagnostics

The development runner now records `firstFeasibleFE` for each event and writes `<outputStem>_recovery.csv` with post-event FE, lateness, safety violation and feasibility at each checkpoint. `SummarizeDynamicRuns` first aggregates correlated events within a scenario run; `PlotRecoveryDiagnostic` generates a run-level-aggregated, explicitly exploratory recovery plot. These are diagnostic utilities, **not** a substitute for the eventual 30 disjoint holdout scenarios and an independent strong baseline.
