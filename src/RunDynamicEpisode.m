function result = RunDynamicEpisode(model,algorithm,maxgen,Particle_Number,seed)
%RUNDYNAMICEPISODE Execute all configured dynamic events sequentially.
%   algorithm is 'PSO' or 'EAT-PSO'. The returned result is intended for
%   development diagnostics; formal experiments will add paired seeds and
%   fixed-budget reporting.
if nargin < 2 || isempty(algorithm), algorithm = 'PSO'; end
if nargin < 3 || isempty(maxgen), maxgen = 20; end
if nargin < 4 || isempty(Particle_Number), Particle_Number = 20; end
if nargin < 5 || isempty(seed), seed = 20261010; end

state = model.initialState;
previousSolution = [];
plannedRoute = state.activeOrderIDs;
records = repmat(struct('eventIndex',0,'eventTime',0,'eventType','', ...
    'eventDescription','','nServed',0,'nActive',0,'nCancelled',0, ...
    'nLocked',0,'planCost',NaN,'distance',NaN,'totalLate',NaN, ...
    'totalViolation',NaN,'isFeasible',false,'eventSeverity',NaN, ...
    'responseTime',NaN,'functionEvaluations',0),0,1);
plans = cell(numel(model.events)+1,1);

% Plan at time zero.
t0 = tic;
if isempty(state.activeOrderIDs)
    plan = EmptyPlan(state);
    planStats.functionEvaluations = 0;
else
    [plan,~,planStats] = RunPlanner(model,state,algorithm,maxgen, ...
        Particle_Number,previousSolution,seed);
end
response = toc(t0);
plans{1} = plan;
plannedRoute = plan.Route;
previousSolution = plan;

for e = 1:numel(model.events)
    event = model.events(e);
    [state,remainingRoute,executionLog] = ExecuteUntilEvent( ...
        model,state,plannedRoute,event.time); %#ok<ASGLU>
    previousSolution.Route = remainingRoute;
    [model,state,applied] = ApplyDynamicEvent(model,state,event);

    t0 = tic;
    if isempty(state.activeOrderIDs)
        plan = EmptyPlan(state);
        planStats.functionEvaluations = 0;
    else
        [plan,~,planStats] = RunPlanner(model,state,algorithm,maxgen, ...
            Particle_Number,previousSolution,seed+e);
    end
    response = toc(t0);
    item = records;
    item = item([]);
    item = struct('eventIndex',0,'eventTime',0,'eventType','', ...
        'eventDescription','','nServed',0,'nActive',0,'nCancelled',0, ...
        'nLocked',0,'planCost',NaN,'distance',NaN,'totalLate',NaN, ...
        'totalViolation',NaN,'isFeasible',false,'eventSeverity',NaN, ...
        'responseTime',NaN,'functionEvaluations',0);
    plans{e+1} = plan;
    plannedRoute = plan.Route;
    previousSolution = plan;

    item.eventIndex = e;
    item.eventTime = event.time;
    item.eventType = event.type;
    item.eventDescription = event.description;
    item.nServed = numel(state.servedOrderIDs);
    item.nActive = numel(state.activeOrderIDs);
    item.nCancelled = numel(state.cancelledOrderIDs);
    item.nLocked = numel(state.lockedOrderIDs);
    item.planCost = plan.Cost;
    item.distance = plan.Detail.distance;
    item.totalLate = plan.Detail.totalLate;
    item.totalViolation = plan.Detail.totalViolation;
    if isfield(planStats,'eventSeverity'), item.eventSeverity = planStats.eventSeverity; end
    item.isFeasible = plan.Detail.isFeasible;
    item.responseTime = response;
    item.functionEvaluations = planStats.functionEvaluations;
    if ~applied
        item.eventDescription = [item.eventDescription,' (not applied)'];
    end
    records(end+1) = item; %#ok<AGROW>
end

result.algorithm = algorithm;
result.records = records;
result.plans = plans;
result.finalState = state;
result.finalModel = model;
end

function [plan,bestCost,stats] = RunPlanner(model,state,algorithm,maxgen,nPop,previous,seed)
if strcmpi(algorithm,'PSO')
    [plan,bestCost,stats] = PSO(model,state,maxgen,nPop,seed);
elseif strcmpi(algorithm,'Warm-PSO') || strcmpi(algorithm,'Warm_PSO')
    [plan,bestCost,stats] = Warm_PSO(model,state,maxgen,nPop,previous,seed);
elseif strcmpi(algorithm,'EAT-PSO') || strcmpi(algorithm,'EAT_PSO')
    [plan,bestCost,stats] = EAT_PSO(model,state,maxgen,nPop,previous,seed);
else
    error('Unsupported algorithm: %s',algorithm);
end
end

function plan = EmptyPlan(state)
plan = struct();
plan.Position = zeros(1,0);
plan.Velocity = zeros(1,0);
plan.Cost = 0;
plan.Route = zeros(1,0);
plan.Detail = struct('routeIDs',zeros(1,0),'distance',0, ...
    'totalLate',0,'totalWaiting',0,'totalViolation',0, ...
    'totalSmoothness',0,'minClearance',inf,'finishTime',state.time, ...
    'finalPosition',state.position,'records',zeros(0,10), ...
    'routeLegs',{{}},'isFeasible',true);
end


