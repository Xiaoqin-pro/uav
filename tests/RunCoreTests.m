function RunCoreTests
%RUNCORETESTS Hand-checkable state and optimizer invariants.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root); addpath(fullfile(root,'src'));
cfg.nInitialOrders = 4;
cfg.nFutureOrders = 2;
cfg.safetySamples = 8;
cfg.level = 'mild';
model = CreateModel(cfg);
assert(ValidateScenario(model).ok);
assert(model.referenceDetail.isFeasible);
retryCfg = cfg;
retryCfg.terrainSeed = 20350003;
retryCfg.orderSeed = 20351103;
retry = CreateModel(retryCfg);
assert(retry.referenceDetail.isFeasible);
assert(retry.orderGenerationAttempts>=2);
assert(retry.effectiveOrderSeed==retryCfg.orderSeed ...
    + (retry.orderGenerationAttempts-1)*1000003);
retryAgain = CreateModel(retryCfg);
assert(retryAgain.effectiveOrderSeed==retry.effectiveOrderSeed);
assert(isequal([retryAgain.orders.xyz],[retry.orders.xyz]));
assert(abs(retryAgain.referenceCost-retry.referenceCost)<1e-10);
assert(isequal(sort(model.referenceRoute(:)'), ...
    sort(model.initialState.activeOrderIDs(:)')));
for e = model.events(:)'
    if strcmp(e.type,'add')
        assert(abs(e.time-model.orders(e.orderIDs).releaseTime)<1e-10);
    end
end
state = model.initialState;
route = state.activeOrderIDs;
first = route(1);
leg = Plan3DLeg(state.position,model.orders(first).xyz,model.env);
arrival = leg.distance/model.env.speed;

% Two events during the same committed flight retain the original arrival.
[state,remaining] = ExecuteUntilEvent(model,state,route,arrival/3);
assert(strcmp(state.status,'in-flight') && state.fixedPrefixIDs==first);
assert(abs(state.pending.arrivalTime-arrival)<1e-10);
[state,remaining] = ExecuteUntilEvent(model,state,remaining,arrival*2/3);
assert(state.fixedPrefixIDs==first && abs(state.pending.arrivalTime-arrival)<1e-10);
[cost,detail] = EvaluateRoute(remaining,model,state); %#ok<ASGLU>
assert(abs(detail.records(1,3)-arrival)<1e-10);

% Cancellation of the committed target must not change the active set.
event = struct('time',state.time,'type','cancel', ...
    'orderIDs',first,'description','locked-target cancellation');
[model,state,applied] = ApplyDynamicEvent(model,state,event);
assert(~applied && ismember(first,state.activeOrderIDs));
[plan,~,stats] = PSO(model,state,2,4,31415);
assert(plan.Route(1)==first && stats.nVar==numel(route)-1);
assert(stats.functionEvaluations==8);
[alt,~,altStats] = EAT_PSO(model,state,2,4,plan,31415);
assert(alt.Route(1)==first && altStats.functionEvaluations==8);
[lns,~,lnsStats,lnsHistory] = Warm_ALNS(model,state,2,4,plan,31415);
assert(lns.Route(1)==first && lnsStats.functionEvaluations==8);
assert(lnsHistory.FE(end)==8);
assert(isequal(sort(lns.Route),sort(state.activeOrderIDs(:)')));

% A service may not be restarted after an event in the servicing interval.
serviceStart = state.pending.serviceStart;
serviceEnd = state.pending.serviceEnd;
[state,remaining] = ExecuteUntilEvent(model,state,remaining, ...
    (serviceStart+serviceEnd)/2);
assert(strcmp(state.status,'servicing'));
assert(state.pending.serviceEnd==serviceEnd);
[state,remaining] = ExecuteUntilEvent(model,state,remaining,serviceEnd);
assert(ismember(first,state.servedOrderIDs));
assert(~ismember(first,state.activeOrderIDs));
assert(state.pending.id~=first);

% Generated add event changes order set and yields bounded impact features.
future = model.events(strcmp({model.events.type},'add'));
event = future(1); event.time = state.time;
[model,state,applied] = ApplyDynamicEvent(model,state,event);
assert(applied);
[severity,components] = EstimateEventSeverity( ...
    state.activeOrderIDs,plan,model,state);
assert(all(components>=0 & components<=1) && severity>=0 && severity<=1);
assert(severity>0);
for variant = {'full','no-reconstruction','fixed-severity'}
    [solution,~,st] = EAT_PSO(model,state,2,4,plan,27182,variant{1});
    assert(st.functionEvaluations==8);
    assert(numel(unique(solution.Route))==numel(state.activeOrderIDs));
    assert(all(ismember(solution.Route,state.activeOrderIDs)));
end
episode = RunEpisode(CreateModel(cfg),'PSO',2,4,27183);
for e = 1:numel(episode.records)
    h = episode.histories{e+1};
    assert(all(diff(h.FE)>=0));
    assert(h.FE(end)==episode.records(e).functionEvaluations);
    assert(h.FE(end)<=8);
    first = find(h.isFeasible,1,'first');
    if isempty(first), assert(isinf(episode.records(e).firstFeasibleFE));
    else
        assert(episode.records(e).firstFeasibleFE<=h.FE(first));
        assert(episode.records(e).firstFeasibleFE>=0);
    end
end
manifest = readtable(fullfile(root,'data','reserved_holdout_seeds.csv'));
assert(height(manifest)==30);
assert(numel(unique(manifest.scenarioId))==30);
assert(numel(unique(manifest.terrainSeed))==30);
assert(all(manifest.terrainSeed>20286000));
fprintf('Core tests passed: locked prefix, repeated event, service, FE, history, severity and reserved seeds.\n');
end
