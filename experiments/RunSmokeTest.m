function RunSmokeTest
%RUNSMOKETEST Validate the first data contract and baseline execution.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('BuildScenario'))
    addpath(fullfile(root,'src'));
end

cfg.nInitialOrders = 6;
cfg.nFutureOrders = 4;
cfg.terrainSeed = 20260927;
cfg.orderSeed = 20260928;
cfg.eventSeed = 20260929;
cfg.safetySamples = 20;
scenario = BuildScenario(cfg);
report = ValidateScenario(scenario);
assert(report.ok, strjoin(report.errors,' | '));
state = scenario.initialState;

options.nPop = 6;
options.maxIt = 4;
options.maxFE = 50;
options.seed = 20260930;
[solution0,history0,stats0] = RandomKeyPSO(scenario,state,options);

if isempty(scenario.events)
    error('Scenario must contain dynamic events.');
end
[scenario1,state1,applied] = ApplyDynamicEvent(scenario,state,scenario.events(1));
if ~applied
    error('The first smoke-test event was not applied.');
end
[solution1,history1,stats1] = RandomKeyPSO(scenario1,state1,options);

outDir = fullfile(root,'results');
if ~exist(outDir,'dir'), mkdir(outDir); end
writetable(array2table(solution0.Detail.records, ...
    'VariableNames',{'order_id','priority','arrival','service_start', ...
    'late','waiting','leg_distance','leg_violation','min_clearance', ...
    'cumulative_distance'}),fullfile(outDir,'smoke_initial_schedule.csv'));
writetable(array2table(solution1.Detail.records, ...
    'VariableNames',{'order_id','priority','arrival','service_start', ...
    'late','waiting','leg_distance','leg_violation','min_clearance', ...
    'cumulative_distance'}),fullfile(outDir,'smoke_after_event_schedule.csv'));
save(fullfile(outDir,'smoke_test.mat'),'scenario','state','solution0', ...
    'history0','stats0','scenario1','state1','solution1','history1','stats1');
PlotScenario(scenario,state,solution0,fullfile(outDir,'smoke_initial.png'));
PlotScenario(scenario1,state1,solution1,fullfile(outDir,'smoke_after_event.png'));

fprintf('Initial active orders: %d\n',numel(state.activeOrderIDs));
fprintf('After first event: %d active orders (%s)\n', ...
    numel(state1.activeOrderIDs),scenario.events(1).description);
fprintf('Initial cost %.3f, distance %.3f, late %.3f, violation %.3f\n', ...
    solution0.Cost,solution0.Detail.distance,solution0.Detail.totalLate, ...
    solution0.Detail.totalViolation);
fprintf('After event cost %.3f, distance %.3f, late %.3f, violation %.3f\n', ...
    solution1.Cost,solution1.Detail.distance,solution1.Detail.totalLate, ...
    solution1.Detail.totalViolation);
end


