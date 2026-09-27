function [bestSol,history,stats] = EventAwareTransferPSO(scenario,state,options,previousSolution)
%EVENTAWARETRANSFERPSO Event-aware transfer Random-key PSO.
%   The search space excludes state.fixedPrefixIDs. The locked prefix is
%   prepended to every candidate route before route evaluation.
if nargin < 3, options = struct(); end
if nargin < 4, previousSolution = []; end
options = FillOptions(options);
if ~isempty(options.seed), rng(options.seed,'twister'); end

allActiveIDs = state.activeOrderIDs(:)';
fixedPrefix = GetFixedPrefix(state,allActiveIDs);
activeIDs = setdiff(allActiveIDs,fixedPrefix,'stable');
nVar = numel(activeIDs);
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
    history.diversity = 0;
    stats.functionEvaluations = 1;
    if detail.isFeasible, stats.firstFeasibleFE = 1;
    else, stats.firstFeasibleFE = inf; end
    stats.nVar = 0;
    stats.activeOrderIDs = activeIDs;
    stats.fixedPrefixIDs = fixedPrefix;
    stats.eventSeverity = 0;
    stats.guideWeight = 0;
    stats.severityComponents = [0 0 0];
    stats.variant = options.variant;
    stats.initialUniqueCount = numel(unique(usedSignatures));
stats.initialDuplicateRetries = initialDuplicateRetries;
stats.options = options;
    return;
end

[severity,severityComponents] = EstimateEventSeverity( ...
    activeIDs,previousSolution,scenario,state);
oldGuide = BuildHistoricalGuide(activeIDs,previousSolution);

nPop = options.nPop;
empty.Position = [];
empty.Velocity = [];
empty.Cost = inf;
empty.Route = [];
empty.Detail = [];
empty.Best = empty;
particle = repmat(empty,nPop,1);
GlobalBest = empty;
GlobalBest.Cost = inf;
functionEvaluations = 0;
firstFeasibleFE = inf;
sourceLabels = strings(nPop,1);
usedSignatures = strings(0,1);
initialDuplicateRetries = 0;
ensureUnique = strcmpi(options.variant,'paper-core') || ...
    strcmpi(options.variant,'adaptive-transfer');

if isempty(previousSolution)
    guideWeight = 1;  % No historical memory exists at initial planning.
elseif strcmpi(options.variant,'paper-core') || strcmpi(options.variant,'fixed-severity')
    guideWeight = 0.5;
else
    guideWeight = severity;
end
for i = 1:nPop
        for attempt = 1:options.maxInitializationRetries
        [position,label] = InitializePosition(i,nPop,activeIDs, ...
            oldGuide,guideWeight,previousSolution,options,scenario,state);
        [~,order] = sort(position,'ascend');
        candidateRoute = [fixedPrefix,activeIDs(order)];
        signature = RouteSignature(candidateRoute);
        if ~ensureUnique || ~ismember(signature,usedSignatures)
            break;
        end
        initialDuplicateRetries = initialDuplicateRetries+1;
        route = PerturbRoute(activeIDs(order),attempt);
        position = RouteToPosition(route,activeIDs,0);
        [~,order] = sort(position,'ascend');
        candidateRoute = [fixedPrefix,activeIDs(order)];
        signature = RouteSignature(candidateRoute);
        label = label+"-unique";
    end
    sourceLabels(i) = label;
    usedSignatures(end+1) = signature;
    particle(i).Position = position;
    particle(i).Velocity = zeros(1,nVar);
    [particle(i).Cost,particle(i).Route,particle(i).Detail] = ...
        EvaluatePosition(position,activeIDs,fixedPrefix,scenario,state);
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
history.diversity = PopulationDiversity(particle);

w = options.w;

for it = 1:options.maxIt
    currentGuide = RouteToPosition(GlobalBest.Route,activeIDs,0);
    mixedGuide = MixGuides(oldGuide,currentGuide,guideWeight);
    for i = 1:nPop
        if functionEvaluations >= options.maxFE, break; end
        particle(i).Velocity = w*particle(i).Velocity ...
            + options.c1*rand(1,nVar).*(particle(i).Best.Position-particle(i).Position) ...
            + options.c2*rand(1,nVar).*(mixedGuide-particle(i).Position);
        particle(i).Velocity = max(-options.velocityRatio, ...
            min(options.velocityRatio,particle(i).Velocity));
        particle(i).Position = particle(i).Position + particle(i).Velocity;
        particle(i).Position = max(0,min(1,particle(i).Position));
        [particle(i).Cost,particle(i).Route,particle(i).Detail] = ...
            EvaluatePosition(particle(i).Position,activeIDs,fixedPrefix,scenario,state);
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
    history.diversity(end+1,1) = PopulationDiversity(particle);
    w = w*options.wdamp;
    if functionEvaluations >= options.maxFE, break; end
end

bestSol = GlobalBest;
bestSol.Route = GlobalBest.Route;
stats.functionEvaluations = functionEvaluations;
stats.firstFeasibleFE = firstFeasibleFE;
stats.nVar = nVar;
stats.activeOrderIDs = activeIDs;
stats.fixedPrefixIDs = fixedPrefix;
stats.eventSeverity = severity;
stats.guideWeight = guideWeight;
stats.severityComponents = severityComponents;
stats.sourceLabels = sourceLabels;
stats.variant = options.variant;
stats.initialUniqueCount = numel(unique(usedSignatures));
stats.initialDuplicateRetries = initialDuplicateRetries;
stats.options = options;
end

function [position,label] = InitializePosition(index,nPop,activeIDs,oldGuide, ...
    severity,previousSolution,options,scenario,state)
nVar = numel(activeIDs);
if strcmpi(options.variant,'paper-no-reconstruction') || strcmpi(options.variant,'no-reconstruction')
    position = rand(1,nVar);
    label = "random-no-reconstruction";
    return;
end
isAdaptive = strcmpi(options.variant,'adaptive-transfer');
if isAdaptive
    historicalShare = max(0.15,0.60-0.40*severity);
else
    historicalShare = 0.60;
end
if index <= floor(historicalShare*nPop) && ~isempty(previousSolution)
    route = PositionToRoute(oldGuide,activeIDs);
    position = RouteToPosition(route,activeIDs,0.025);
    label = "historical-transfer";
elseif index <= floor(min(0.90,historicalShare+0.25)*nPop) ...
        && ~isempty(previousSolution)
    route = BuildInsertionRoute(previousSolution.Route,activeIDs,scenario,state);
    position = RouteToPosition(route,activeIDs,0.01);
    label = "event-insertion";
else
    position = rand(1,nVar);
    label = "diversity-immigrant";
end
end

function route = BuildInsertionRoute(previousRoute,activeIDs,scenario,state)
% Cheap surrogate insertion: no calls to the full objective are hidden.
route = intersect(previousRoute(:)',activeIDs,'stable');
missing = setdiff(activeIDs,route,'stable');
for id = missing
    cost = zeros(1,numel(route)+1);
    for pos = 1:numel(cost)
        candidate = [route(1:pos-1),id,route(pos:end)];
        cost(pos) = SurrogateSchedule(candidate,scenario,state);
    end
    [~,rank] = sort(cost);
    % Sample from the three best positions to retain diversity.
    shortlist = rank(1:min(3,numel(rank)));
    pos = shortlist(randi(numel(shortlist)));
    route = [route(1:pos-1),id,route(pos:end)];
end
end

function value = SurrogateSchedule(route,scenario,state)
p = state.position;
t = state.time;
value = 0;
for id = route
    o = scenario.orders([scenario.orders.id]==id);
    d = norm(o.xyz-p);
    t = max([t+d/scenario.env.speed,o.readyTime,o.releaseTime]);
    value = value+d+scenario.env.speed*max(0,t-o.dueTime);
    t = t+o.serviceTime;
    p = o.xyz;
end
end
function fixedPrefix = GetFixedPrefix(state,activeIDs)
if isfield(state,'fixedPrefixIDs') && ~isempty(state.fixedPrefixIDs)
    fixedPrefix = intersect(state.fixedPrefixIDs(:)',activeIDs,'stable');
else
    fixedPrefix = zeros(1,0);
end
end

function guide = BuildHistoricalGuide(activeIDs,previousSolution)
if isempty(previousSolution) || ~isfield(previousSolution,'Route') || isempty(previousSolution.Route)
    guide = 0.5*ones(1,numel(activeIDs));
    return;
end
route = previousSolution.Route(:)';
route = intersect(route,activeIDs,'stable');
missing = setdiff(activeIDs,route,'stable');
route = [route,missing];
guide = RouteToPosition(route,activeIDs,0);
end

function route = PositionToRoute(position,activeIDs)
[~,order] = sort(position,'ascend');
route = activeIDs(order);
end

function position = RouteToPosition(route,activeIDs,jitter)
if nargin < 3, jitter = 0; end
n = numel(activeIDs);
position = zeros(1,n);
route = intersect(route(:)',activeIDs,'stable');
route = [route,setdiff(activeIDs,route,'stable')];
for k = 1:numel(route)
    idx = find(activeIDs==route(k),1);
    if ~isempty(idx), position(idx) = (k-1)/max(1,n-1); end
end
if jitter > 0, position = position + jitter*randn(size(position)); end
position = max(0,min(1,position));
end

function guide = MixGuides(oldGuide,currentGuide,severity)
if isempty(currentGuide), guide = oldGuide; return; end
if isempty(oldGuide), guide = currentGuide; return; end
guide = (1-severity)*oldGuide + severity*currentGuide;
end

function [cost,route,detail] = EvaluatePosition(position,activeIDs,fixedPrefix,scenario,state)
[~,order] = sort(position,'ascend');
route = [fixedPrefix,activeIDs(order)];
[cost,detail] = EvaluateRoute(route,scenario,state);
end

function diversity = PopulationDiversity(particle)
if numel(particle) <= 1, diversity = 0; return; end
P = vertcat(particle.Position);
diversity = mean(std(P,0,1));
end

function options = FillOptions(options)
defaults = struct('nPop',30,'maxIt',100,'maxFE',3000, ...
    'w',0.9,'wdamp',0.99,'c1',1.5,'c2',1.5, ...
    'velocityRatio',0.2,'seed',20260931,'variant','paper-core', ...
    'fixedGuideWeight',0.5,'maxInitializationRetries',20);
fields = fieldnames(defaults);
for k = 1:numel(fields)
    if ~isfield(options,fields{k}) || isempty(options.(fields{k}))
        options.(fields{k}) = defaults.(fields{k});
    end
end
end

function route = PerturbRoute(route,attempt)
if nargin<2, attempt=1; end
if numel(route)<2, return; end
if mod(attempt,2)==1
    idx = randperm(numel(route),2);
    route(idx) = route(fliplr(idx));
else
    from = randi(numel(route));
    item = route(from); route(from) = [];
    pos = randi(numel(route)+1);
    route = [route(1:pos-1),item,route(pos:end)];
end
end

function s = RouteSignature(route)
s = string(strjoin(string(route),'-'));
end
