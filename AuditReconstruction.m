function [events,summary] = AuditReconstruction(manifestPath,outputStem)
%AUDITRECONSTRUCTION Audit v1 initial population route uniqueness.
%   This uses deterministic reference-route execution to obtain event states
%   and spends no full candidate EvaluateRoute FE on the audit itself.
if nargin < 1 || isempty(manifestPath)
    manifestPath = fullfile(fileparts(mfilename('fullpath')), ...
        'data','paper_v2_dev_seeds.csv');
end
if nargin < 2 || isempty(outputStem), outputStem = 'paper_v2_reconstruction_audit'; end
M = readtable(manifestPath,'TextType','string');
rows = repmat(struct('scenarioId','','run',0,'eventIndex',0, ...
    'eventTime',0,'nActive',0,'nSearch',0,'nHistorical',0, ...
    'nInsertion',0,'nImmigrant',0,'nUniqueHistorical',0, ...
    'nUniqueInsertion',0,'nUniqueImmigrant',0,'nUniqueAll',0, ...
    'historicalDuplicateRate',NaN,'allDuplicateRate',NaN, ...
    'historicalPairwiseDuplicateRate',NaN,'allPairwiseDuplicateRate',NaN, ...
    'routeDim',0,'fixedPrefixLength',0),0,1);
for i = 1:height(M)
    cfg.nInitialOrders = 8; cfg.nFutureOrders = 6;
    cfg.level = 'severe'; cfg.safetySamples = 8;
    cfg.initialWindowMode = 'reference'; cfg.windowLengthOverride = 135;
    cfg.releaseStart = 45; cfg.releaseInterval = 15;
    cfg.terrainSeed = M.terrainSeed(i); cfg.orderSeed = M.orderSeed(i);
    cfg.eventSeed = M.eventSeed(i);
    model = CreateModel(cfg);
    state = model.initialState;
    plannedRoute = model.referenceRoute;
    previous = struct('Route',plannedRoute);
    for e = 1:numel(model.events)
        event = model.events(e);
        [state,remaining] = ExecuteUntilEvent(model,state,plannedRoute,event.time);
        previous.Route = remaining;
        [model,state,applied] = ApplyDynamicEvent(model,state,event);
        if applied && strcmp(event.type,'add')
            audit = AuditInitialSources(model,state,previous,M.algorithmSeed(i));
            item = audit;
            item.scenarioId = char(M.scenarioId(i));
            item.run = i; item.eventIndex = e; item.eventTime = event.time;
            rows(end+1) = item; %#ok<AGROW>
        end
        plannedRoute = [state.fixedPrefixIDs(:)', ...
            setdiff(state.activeOrderIDs(:)',state.fixedPrefixIDs(:)','stable')];
    end
end
events = struct2table(rows);
summary = SummarizeAudit(events);
outDir = fullfile(fileparts(mfilename('fullpath')),'results');
writetable(events,fullfile(outDir,[outputStem,'_events.csv']));
writetable(summary,fullfile(outDir,[outputStem,'_summary.csv']));
save(fullfile(outDir,[outputStem,'.mat']),'events','summary');
disp(summary);
end

function item = AuditInitialSources(model,state,previous,seed)
rng(seed,'twister');
nPop = 6;
active = state.activeOrderIDs(:)';
fixed = GetFixedPrefix(state,active);
search = setdiff(active,fixed,'stable');
source = strings(nPop,1); signatures = strings(nPop,1);
historical = strings(0,1); insertion = strings(0,1); immigrant = strings(0,1);
historicalShare = 0.60;
for i = 1:nPop
    if i <= floor(historicalShare*nPop) && ~isempty(previous.Route)
        route = CompleteRoute(PositionToRoute(RouteToPosition(previous.Route,search),search),search);
        position = RouteToPosition(route,search,0.025);
        source(i) = "historical";
    elseif i <= floor(min(0.90,historicalShare+0.25)*nPop) ...
            && ~isempty(previous.Route)
        route = BuildInsertionRoute(previous.Route,search,model,state);
        position = RouteToPosition(route,search,0.01);
        source(i) = "insertion";
    else
        position = rand(1,numel(search));
        route = PositionToRoute(position,search);
        source(i) = "immigrant";
    end
    [~,order] = sort(position,'ascend');
    decoded = [fixed,search(order)];
    signatures(i) = RouteSignature(decoded);
    if source(i)=="historical", historical(end+1)=signatures(i); end %#ok<AGROW>
    if source(i)=="insertion", insertion(end+1)=signatures(i); end %#ok<AGROW>
    if source(i)=="immigrant", immigrant(end+1)=signatures(i); end %#ok<AGROW>
end
item = struct('scenarioId','','run',0,'eventIndex',0,'eventTime',0, ...
    'nActive',numel(active),'nSearch',numel(search), ...
    'nHistorical',sum(source=="historical"),'nInsertion',sum(source=="insertion"), ...
    'nImmigrant',sum(source=="immigrant"), ...
    'nUniqueHistorical',numel(unique(historical)), ...
    'nUniqueInsertion',numel(unique(insertion)), ...
    'nUniqueImmigrant',numel(unique(immigrant)), ...
    'nUniqueAll',numel(unique(signatures)), ...
    'historicalDuplicateRate',DuplicateRate(historical), ...
    'allDuplicateRate',DuplicateRate(signatures), ...
    'historicalPairwiseDuplicateRate',PairwiseDuplicateRate(historical), ...
    'allPairwiseDuplicateRate',PairwiseDuplicateRate(signatures), ...
    'routeDim',numel(search),'fixedPrefixLength',numel(fixed));
end

function route = BuildInsertionRoute(previousRoute,active,model,state)
route = intersect(previousRoute(:)',active,'stable');
missing = setdiff(active,route,'stable');
for id = missing
    values = zeros(1,numel(route)+1);
    for p = 1:numel(values)
        values(p) = SurrogateCost([route(1:p-1),id,route(p:end)],model,state);
    end
    [~,rank] = sort(values);
    shortlist = rank(1:min(3,numel(rank)));
    p = shortlist(randi(numel(shortlist)));
    route = [route(1:p-1),id,route(p:end)];
end
end

function v = SurrogateCost(route,model,state)
v = 0; t = state.time; p = state.position;
for id = route
    o = model.orders([model.orders.id]==id); d = norm(o.xyz-p);
    start = max([t+d/model.env.speed,o.readyTime,o.releaseTime]);
    v = v+d+model.env.speed*max(0,start-o.dueTime);
    t = start+o.serviceTime; p=o.xyz;
end
end

function p = RouteToPosition(route,active,jitter)
if nargin<3, jitter=0; end
route = intersect(route(:)',active,'stable');
route = [route,setdiff(active,route,'stable')];
p = zeros(1,numel(active));
for k=1:numel(route), p(active==route(k))=(k-1)/max(1,numel(active)-1); end
if jitter>0, p=p+jitter*randn(size(p)); end
p=max(0,min(1,p));
end

function route = PositionToRoute(p,active)
[~,idx]=sort(p); route=active(idx);
end
function route = CompleteRoute(route,active)
route=[route,setdiff(active,route,'stable')];
end
function s = RouteSignature(route)
s = string(strjoin(string(route),'-'));
end
function r = DuplicateRate(s)
if isempty(s), r=0; else, r=1-numel(unique(s))/numel(s); end
end
function r = PairwiseDuplicateRate(s)
if numel(s)<2, r=0; else, r=1-numel(unique(s))/numel(s); end
end
function fixed = GetFixedPrefix(state,active)
if isfield(state,'fixedPrefixIDs'), fixed=intersect(state.fixedPrefixIDs(:)',active(:)','stable'); else, fixed=[]; end
end
function summary = SummarizeAudit(T)
if isempty(T), summary=table(); return; end
summary = groupsummary(T,{'scenarioId'},'mean', ...
    {'nUniqueAll','allDuplicateRate','historicalDuplicateRate', ...
    'historicalPairwiseDuplicateRate','allPairwiseDuplicateRate'});
end
