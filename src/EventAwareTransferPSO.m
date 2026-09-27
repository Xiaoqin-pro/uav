function [bestSol,history,stats] = EventAwareTransferPSO(scenario,state,options,previousSolution)
%EVENTAWARETRANSFERPSO Event-aware population-transfer Random-key PSO.
%   The first research implementation contains two deliberately small
%   mechanisms:
%   1) multi-source population reconstruction after an order event;
%   2) event-severity-dependent mixing of historical and current guides.
if nargin < 3, options = struct(); end
if nargin < 4, previousSolution = []; end
options = FillOptions(options);
if ~isempty(options.seed), rng(options.seed,'twister'); end

activeIDs = state.activeOrderIDs(:)';
nVar = numel(activeIDs);
if nVar == 0, error('No active orders are available for planning.'); end

severity = EstimateEventSeverity(activeIDs,previousSolution);
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
sourceLabels = strings(nPop,1);

for i = 1:nPop
    [position,sourceLabels(i)] = InitializePosition(i,nPop,activeIDs, ...
        oldGuide,severity,previousSolution);
    particle(i).Position = position;
    particle(i).Velocity = zeros(1,nVar);
    [particle(i).Cost,particle(i).Route,particle(i).Detail] = ...
        EvaluatePosition(position,activeIDs,scenario,state);
    functionEvaluations = functionEvaluations + 1;
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
    % Mild events retain more historical direction; severe events rely more
    % on the current event-specific global best.
    guideWeight = severity;
    mixedGuide = MixGuides(oldGuide,GlobalBest.Position,guideWeight);
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
            EvaluatePosition(particle(i).Position,activeIDs,scenario,state);
        functionEvaluations = functionEvaluations + 1;
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
stats.nVar = nVar;
stats.activeOrderIDs = activeIDs;
stats.eventSeverity = severity;
stats.sourceLabels = sourceLabels;
stats.historicalGuide = oldGuide;
stats.options = options;
end

function [position,label] = InitializePosition(index,nPop,activeIDs,oldGuide,severity,previousSolution)
nVar = numel(activeIDs);
if index <= floor(0.40*nPop) && ~isempty(previousSolution)
    route = PositionToRoute(oldGuide,activeIDs);
    position = RouteToPosition(route,activeIDs,0.025);
    label = "historical-transfer";
elseif index <= floor(0.70*nPop)
    route = activeIDs(randperm(nVar));
    if ~isempty(previousSolution) && severity < 0.75
        oldRoute = PositionToRoute(oldGuide,activeIDs);
        route = InsertNewOrders(route,oldRoute,activeIDs);
    end
    position = RouteToPosition(route,activeIDs,0.05);
    label = "event-insertion";
else
    position = rand(1,nVar);
    label = "diversity-immigrant";
end
end

function route = InsertNewOrders(route,oldRoute,activeIDs)
% Preserve a few historically useful adjacent pairs, without locking them.
if isempty(oldRoute), return; end
keep = intersect(oldRoute,activeIDs,'stable');
if numel(keep) < 2, return; end
pairStart = randi([1,max(1,numel(keep)-1)]);
pair = keep(pairStart:min(pairStart+1,numel(keep)));
route(ismember(route,pair)) = [];
pos = randi([1,numel(route)+1]);
route = [route(1:pos-1),pair,route(pos:end)];
end

function severity = EstimateEventSeverity(activeIDs,previousSolution)
if isempty(previousSolution) || ~isfield(previousSolution,'Route') || isempty(previousSolution.Route)
    severity = 1.0;
    return;
end
oldIDs = previousSolution.Route(:)';
newCount = numel(setdiff(activeIDs,oldIDs));
cancelCount = numel(setdiff(oldIDs,activeIDs));
severity = (newCount+cancelCount)/max(numel(activeIDs),numel(oldIDs));
severity = max(0,min(1,severity));
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
for k = 1:numel(route)
    idx = find(activeIDs==route(k),1);
    if ~isempty(idx), position(idx) = (k-1)/max(1,n-1); end
end
if jitter > 0
    position = position + jitter*randn(size(position));
end
position = max(0,min(1,position));
end

function guide = MixGuides(oldGuide,currentGuide,severity)
if isempty(currentGuide), guide = oldGuide; return; end
if isempty(oldGuide), guide = currentGuide; return; end
guide = (1-severity)*oldGuide + severity*currentGuide;
end

function [cost,route,detail] = EvaluatePosition(position,activeIDs,scenario,state)
[~,order] = sort(position,'ascend');
route = activeIDs(order);
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
    'velocityRatio',0.2,'seed',20260931);
fields = fieldnames(defaults);
for k = 1:numel(fields)
    if ~isfield(options,fields{k}) || isempty(options.(fields{k}))
        options.(fields{k}) = defaults.(fields{k});
    end
end
end

