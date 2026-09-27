function report = ValidateScenario(scenario)
%VALIDATESCENARIO Validate data contract and invariants for a scenario.
report = struct('ok',false,'errors',{{}},'warnings',{{}}, ...
    'nOrders',0,'nInitialActive',0,'nEvents',0);
requiredScenario = {'env','orders','events','initialState'};
for k = 1:numel(requiredScenario)
    if ~isfield(scenario,requiredScenario{k})
        report.errors{end+1} = ['Missing scenario field: ',requiredScenario{k}]; %#ok<AGROW>
    end
end
if ~isempty(report.errors), return; end

env = scenario.env;
requiredEnv = {'X','Y','terrainZ','depot','obstacles','speed','minClearance'};
for k = 1:numel(requiredEnv)
    if ~isfield(env,requiredEnv{k})
        report.errors{end+1} = ['Missing environment field: ',requiredEnv{k}]; %#ok<AGROW>
    end
end
if ~isempty(report.errors), return; end
if ~isequal(size(env.X),size(env.Y),size(env.terrainZ))
    report.errors{end+1} = 'X, Y and terrainZ must have identical sizes.';
end
if any(~isfinite(env.terrainZ(:)))
    report.errors{end+1} = 'terrainZ contains non-finite values.';
end
if env.speed <= 0 || env.minClearance < 0
    report.errors{end+1} = 'speed must be positive and minClearance non-negative.';
end

orders = scenario.orders;
report.nOrders = numel(orders);
ids = [orders.id];
if numel(unique(ids)) ~= numel(ids)
    report.errors{end+1} = 'Order IDs must be globally unique.';
end
for k = 1:numel(orders)
    o = orders(k);
    if o.readyTime > o.dueTime
        report.errors{end+1} = sprintf('Order %d has readyTime > dueTime.',o.id);
    end
    if o.releaseTime > o.readyTime
        report.warnings{end+1} = sprintf('Order %d is released after its ready time.',o.id);
    end
    if ~all(isfinite(o.xyz))
        report.errors{end+1} = sprintf('Order %d has non-finite xyz.',o.id);
    end
end

state = scenario.initialState;
report.nInitialActive = numel(state.activeOrderIDs);
if ~isempty(intersect(state.activeOrderIDs,state.servedOrderIDs))
    report.errors{end+1} = 'Initial active and served order sets overlap.';
end
if ~isempty(intersect(state.activeOrderIDs,state.cancelledOrderIDs))
    report.errors{end+1} = 'Initial active and cancelled order sets overlap.';
end
if ~all(ismember([state.activeOrderIDs state.servedOrderIDs state.cancelledOrderIDs],ids))
    report.errors{end+1} = 'State references an unknown order ID.';
end

events = scenario.events;
report.nEvents = numel(events);
lastTime = -inf;
for k = 1:numel(events)
    e = events(k);
    if e.time < lastTime
        report.errors{end+1} = 'Events must be sorted by nondecreasing time.';
    end
    lastTime = e.time;
    if ~ismember(e.type,{'add','cancel'})
        report.errors{end+1} = sprintf('Unsupported event type at index %d.',k);
    end
    if ~all(ismember(e.orderIDs,ids))
        report.errors{end+1} = sprintf('Event %d references an unknown order ID.',k);
    end
end
report.ok = isempty(report.errors);
end
