function [bestSol,history,stats] = WarmALNS(scenario,state,options,previousSolution)
%WARMALNS Compact independent adaptive destroy/repair route baseline.
%   Random or costly-order removal and greedy or regret-2 repair are
%   selected by smoothed operator rewards. Exactly one full EvaluateRoute
%   call is counted per complete candidate; all surrogate and operator
%   overhead is included in wall-clock response time.
if nargin < 4, previousSolution = []; end
if ~isfield(options,'maxFE'), options.maxFE = 3000; end
if ~isfield(options,'checkpointFE'), options.checkpointFE = 30; end
if ~isfield(options,'seed'), options.seed = 20260930; end
assert(options.maxFE>=1 && options.checkpointFE>=1);
if ~isempty(options.seed), rng(options.seed,'twister'); end
active = state.activeOrderIDs(:)';
fixed = zeros(1,0);
if isfield(state,'fixedPrefixIDs')
    fixed = intersect(state.fixedPrefixIDs(:)',active,'stable');
end
free = setdiff(active,fixed,'stable');
if isempty(free)
    route = fixed;
else
    retained = zeros(1,0);
    if ~isempty(previousSolution) && isfield(previousSolution,'Route')
        retained = intersect(previousSolution.Route(:)',free,'stable');
    end
    route = [fixed,GreedyFill(retained,setdiff(free,retained,'stable'), ...
        fixed,scenario,state)];
end
[bestCost,bestDetail] = EvaluateRoute(route,scenario,state);
currentRoute = route;
currentCost = bestCost;
currentDetail = bestDetail;
bestRoute = route;
fe = 1;
firstFeasibleFE = inf;
if bestDetail.isFeasible, firstFeasibleFE = 1; end
history.FE = zeros(0,1);
history.bestCost = zeros(0,1);
history.distance = zeros(0,1);
history.totalLate = zeros(0,1);
history.totalViolation = zeros(0,1);
history.isFeasible = false(0,1);
if options.maxFE==1, history = Record(history,fe,bestCost,bestDetail); end
weightsDestroy = ones(1,2);
weightsRepair = ones(1,2);
accepted = 0;
while fe<options.maxFE
    if isempty(free)
        % No decision variables: avoid repeated objective calls.
        break;
    end
    destroy = WeightedPick(weightsDestroy);
    repair = WeightedPick(weightsRepair);
    nRemove = min(numel(free),max(1,ceil((0.15+0.25*rand)*numel(free))));
    [partial,removed] = Destroy(currentRoute,fixed,destroy,nRemove, ...
        currentDetail,scenario,state);
    candidate = Repair(partial,removed,fixed,repair,scenario,state);
    [candidateCost,candidateDetail] = EvaluateRoute(candidate,scenario,state);
    fe = fe+1;
    if isinf(firstFeasibleFE) && candidateDetail.isFeasible
        firstFeasibleFE = fe;
    end
    improvedBest = CompareRouteDetails(candidateCost,candidateDetail, ...
        bestCost,bestDetail);
    improvedCurrent = CompareRouteDetails(candidateCost,candidateDetail, ...
        currentCost,currentDetail);
    reward = 0.1;
    if improvedBest
        bestCost = candidateCost; bestDetail = candidateDetail;
        bestRoute = candidate;
        reward = 3;
    elseif improvedCurrent
        reward = 1;
    end
    if improvedCurrent || improvedBest || (rand<0.05 && ...
            candidateDetail.totalViolation<=currentDetail.totalViolation+1e-10)
        currentRoute = candidate;
        currentCost = candidateCost;
        currentDetail = candidateDetail;
        accepted = accepted+1;
    end
    weightsDestroy(destroy) = max(0.1,0.8*weightsDestroy(destroy)+0.2*reward);
    weightsRepair(repair) = max(0.1,0.8*weightsRepair(repair)+0.2*reward);
    if mod(fe,options.checkpointFE)==0 || fe==options.maxFE
        history = Record(history,fe,bestCost,bestDetail);
    end
end
if isempty(history.FE) || history.FE(end)~=fe
    history = Record(history,fe,bestCost,bestDetail);
end
bestSol = struct('Position',[],'Velocity',[], ...
    'Cost',bestCost,'Route',bestRoute,'Detail',bestDetail);
stats.functionEvaluations = fe;
stats.firstFeasibleFE = firstFeasibleFE;
stats.nVar = numel(free);
stats.activeOrderIDs = free;
stats.fixedPrefixIDs = fixed;
stats.accepted = accepted;
stats.destroyWeights = weightsDestroy;
stats.repairWeights = weightsRepair;
stats.options = options;
end

function [partial,removed] = Destroy(route,fixed,mode,q,detail,scenario,state)
suffix = route(numel(fixed)+1:end);
if mode==1
    indices = randperm(numel(suffix),q);
else
    scores = zeros(1,numel(suffix));
    for i = 1:numel(suffix)
        id = suffix(i);
        pos = find(route==id,1);
        before = state.position;
        if pos>1, before = scenario.orders(route(pos-1)).xyz; end
        after = before;
        if pos<numel(route), after = scenario.orders(route(pos+1)).xyz; end
        here = scenario.orders(id).xyz;
        marginal = norm(before-here)+norm(here-after)-norm(before-after);
        late = 0;
        recordIndex = find(detail.records(:,1)==id,1);
        if ~isempty(recordIndex), late = detail.records(recordIndex,5); end
        scores(i) = marginal+scenario.env.speed*late+1e-6*rand;
    end
    [~,rank] = sort(scores,'descend');
    indices = rank(1:q);
end
removed = suffix(indices);
suffix(indices) = [];
partial = [fixed,suffix];
end

function route = Repair(partial,removed,fixed,mode,scenario,state)
route = partial;
removed = removed(randperm(numel(removed)));
while ~isempty(removed)
    bestCost = inf(1,numel(removed));
    bestPos = ones(1,numel(removed));
    regret = zeros(1,numel(removed));
    for j = 1:numel(removed)
        choices = zeros(1,numel(route)-numel(fixed)+1);
        for k = 1:numel(choices)
            pos = numel(fixed)+k;
            candidate = [route(1:pos-1),removed(j),route(pos:end)];
            choices(k) = SurrogateCost(candidate,scenario,state);
        end
        [sorted,rank] = sort(choices);
        bestCost(j) = sorted(1);
        bestPos(j) = numel(fixed)+rank(1);
        regret(j) = sorted(min(2,numel(sorted)))-sorted(1);
    end
    if mode==1, [~,chosen] = min(bestCost);
    else, [~,chosen] = max(regret); end
    pos = bestPos(chosen);
    route = [route(1:pos-1),removed(chosen),route(pos:end)];
    removed(chosen) = [];
end
end

function suffix = GreedyFill(retained,missing,fixed,scenario,state)
suffix = retained;
if isempty(missing), return; end
route = Repair([fixed,suffix],missing,fixed,1,scenario,state);
suffix = route(numel(fixed)+1:end);
end

function value = SurrogateCost(route,scenario,state)
t = state.time;
position = state.position;
value = 0;
for id = route
    order = scenario.orders(id);
    if isfield(state,'pending') && state.pending.id==id
        d = max(0,state.pending.arrivalTime-state.time)*scenario.env.speed;
        value = value+d;
        t = state.pending.serviceEnd;
        position = order.xyz;
        continue;
    end
    d = norm(order.xyz-position);
    arrival = t+d/scenario.env.speed;
    start = max([arrival,order.readyTime,order.releaseTime]);
    value = value+d+scenario.env.speed*max(0,start-order.dueTime);
    t = start+order.serviceTime;
    position = order.xyz;
end
end

function index = WeightedPick(weights)
cdf = cumsum(weights/sum(weights));
index = find(rand<=cdf,1,'first');
end

function history = Record(history,fe,cost,detail)
history.FE(end+1,1) = fe;
history.bestCost(end+1,1) = cost;
history.distance(end+1,1) = detail.distance;
history.totalLate(end+1,1) = detail.totalLate;
history.totalViolation(end+1,1) = detail.totalViolation;
history.isFeasible(end+1,1) = detail.isFeasible;
end
