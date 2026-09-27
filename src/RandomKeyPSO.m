function [bestSol,history,stats] = RandomKeyPSO(scenario,state,options)
%RANDOMKEYPSO Baseline Random-key PSO for dynamic order sequencing.
%   If state.fixedPrefixIDs is non-empty, the locked prefix is preserved
%   and only the remaining active orders are optimized.
if nargin < 3, options = struct(); end
options = FillOptions(options);
allActiveIDs = state.activeOrderIDs(:)';
fixedPrefix = GetFixedPrefix(state,allActiveIDs);
searchIDs = setdiff(allActiveIDs,fixedPrefix,'stable');
nVar = numel(searchIDs);
if nVar == 0
    [cost,detail] = EvaluateRoute(fixedPrefix,scenario,state);
    bestSol = struct('Position',zeros(1,0),'Velocity',zeros(1,0), ...
        'Cost',cost,'Route',fixedPrefix,'Detail',detail);
    history.FE = 1;
    history.bestCost = cost;
    history.distance = detail.distance;
    history.totalLate = detail.totalLate;
    history.totalViolation = detail.totalViolation;
    history.isFeasible = detail.isFeasible;
    stats.functionEvaluations = 1;
    if detail.isFeasible, stats.firstFeasibleFE = 1;
    else, stats.firstFeasibleFE = inf; end
    stats.nVar = 0;
    stats.activeOrderIDs = searchIDs;
    stats.fixedPrefixIDs = fixedPrefix;
    stats.options = options;
    return;
end
if ~isempty(options.seed), rng(options.seed,'twister'); end

nPop = options.nPop;
empty.Position = [];
empty.Velocity = [];
empty.Cost = inf;
empty.Route = [];
empty.Detail = [];
empty.Best = empty;
particle = repmat(empty,nPop,1);

vMax = options.velocityRatio;
functionEvaluations = 0;
firstFeasibleFE = inf;
GlobalBest = empty;
GlobalBest.Cost = inf;

for i = 1:nPop
    if ~isempty(options.initialRoute) && i <= max(1,ceil(0.20*nPop))
        particle(i).Position = RouteToPosition(options.initialRoute,searchIDs, ...
            0.03*(i-1));
    else
        particle(i).Position = rand(1,nVar);
    end
    particle(i).Velocity = zeros(1,nVar);
    [particle(i).Cost,particle(i).Route,particle(i).Detail] = ...
        EvaluatePosition(particle(i).Position,searchIDs,fixedPrefix,scenario,state);
    functionEvaluations = functionEvaluations + 1;
    if isinf(firstFeasibleFE) && particle(i).Detail.isFeasible
        firstFeasibleFE = functionEvaluations;
    end
    particle(i).Best = particle(i);
    if CompareRouteDetails(particle(i).Cost,particle(i).Detail, ...
            GlobalBest.Cost,GlobalBest.Detail)
        GlobalBest = particle(i);
    end
end

history.FE = functionEvaluations;
history.bestCost = GlobalBest.Cost;
history.distance = GlobalBest.Detail.distance;
history.totalLate = GlobalBest.Detail.totalLate;
history.totalViolation = GlobalBest.Detail.totalViolation;
history.isFeasible = GlobalBest.Detail.isFeasible;

w = options.w;
for it = 1:options.maxIt
    for i = 1:nPop
        if functionEvaluations >= options.maxFE, break; end
        particle(i).Velocity = w*particle(i).Velocity ...
            + options.c1*rand(1,nVar).*(particle(i).Best.Position-particle(i).Position) ...
            + options.c2*rand(1,nVar).*(GlobalBest.Position-particle(i).Position);
        particle(i).Velocity = max(-vMax,min(vMax,particle(i).Velocity));
        particle(i).Position = particle(i).Position + particle(i).Velocity;
        particle(i).Position = max(0,min(1,particle(i).Position));
        [particle(i).Cost,particle(i).Route,particle(i).Detail] = ...
            EvaluatePosition(particle(i).Position,searchIDs,fixedPrefix,scenario,state);
        functionEvaluations = functionEvaluations + 1;
        if isinf(firstFeasibleFE) && particle(i).Detail.isFeasible
            firstFeasibleFE = functionEvaluations;
        end
        if CompareRouteDetails(particle(i).Cost,particle(i).Detail, ...
                particle(i).Best.Cost,particle(i).Best.Detail)
            particle(i).Best = particle(i);
            if CompareRouteDetails(particle(i).Best.Cost,particle(i).Best.Detail, ...
                    GlobalBest.Cost,GlobalBest.Detail)
                GlobalBest = particle(i).Best;
            end
        end
    end
    history.FE(end+1,1) = functionEvaluations;
    history.bestCost(end+1,1) = GlobalBest.Cost;
    history.distance(end+1,1) = GlobalBest.Detail.distance;
    history.totalLate(end+1,1) = GlobalBest.Detail.totalLate;
    history.totalViolation(end+1,1) = GlobalBest.Detail.totalViolation;
    history.isFeasible(end+1,1) = GlobalBest.Detail.isFeasible;
    w = w*options.wdamp;
    if functionEvaluations >= options.maxFE, break; end
end

bestSol = GlobalBest;
bestSol.Position = GlobalBest.Position;
bestSol.Route = GlobalBest.Route;
stats.functionEvaluations = functionEvaluations;
stats.firstFeasibleFE = firstFeasibleFE;
stats.nVar = nVar;
stats.activeOrderIDs = searchIDs;
stats.fixedPrefixIDs = fixedPrefix;
stats.options = options;
end

function [cost,route,detail] = EvaluatePosition(position,searchIDs,fixedPrefix,scenario,state)
[~,order] = sort(position,'ascend');
route = [fixedPrefix,searchIDs(order)];
[cost,detail] = EvaluateRoute(route,scenario,state);
end

function fixedPrefix = GetFixedPrefix(state,activeIDs)
if isfield(state,'fixedPrefixIDs') && ~isempty(state.fixedPrefixIDs)
    fixedPrefix = intersect(state.fixedPrefixIDs(:)',activeIDs,'stable');
else
    fixedPrefix = zeros(1,0);
end
end

function position = RouteToPosition(route,activeIDs,jitter)
if nargin < 3, jitter = 0; end
route = intersect(route(:)',activeIDs,'stable');
route = [route,setdiff(activeIDs,route,'stable')];
n = numel(activeIDs);
position = zeros(1,n);
for k = 1:numel(route)
    idx = find(activeIDs==route(k),1);
    if ~isempty(idx), position(idx) = (k-1)/max(1,n-1); end
end
if jitter > 0, position = position + jitter*randn(size(position)); end
position = max(0,min(1,position));
end

function options = FillOptions(options)
defaults = struct('nPop',30,'maxIt',100,'maxFE',3000, ...
    'w',0.9,'wdamp',0.99,'c1',1.5,'c2',1.5, ...
    'velocityRatio',0.2,'seed',20260930,'initialRoute',[]);
fields = fieldnames(defaults);
for k = 1:numel(fields)
    if ~isfield(options,fields{k}) || isempty(options.(fields{k}))
        options.(fields{k}) = defaults.(fields{k});
    end
end
end
