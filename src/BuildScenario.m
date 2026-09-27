function scenario = BuildScenario(cfg)
%BUILDSCENARIO Deterministic reference-feasible synthetic instance.
%   If an initial reference has a genuine 3-D safety violation, reject the
%   whole order realization and try the next deterministic order seed.
if nargin < 1, cfg = struct(); end
if ~isfield(cfg,'nInitialOrders'), cfg.nInitialOrders = 20; end
if ~isfield(cfg,'nFutureOrders'), cfg.nFutureOrders = 8; end
if ~isfield(cfg,'terrainSeed'), cfg.terrainSeed = 20260927; end
if ~isfield(cfg,'orderSeed'), cfg.orderSeed = 20260928; end
if ~isfield(cfg,'eventSeed'), cfg.eventSeed = 20260929; end
if ~isfield(cfg,'level'), cfg.level = 'mild'; end
if ~isfield(cfg,'initialWindowMode'), cfg.initialWindowMode = 'reference'; end
if ~isfield(cfg,'maxOrderGenerationAttempts')
    cfg.maxOrderGenerationAttempts = 32;
end
assert(cfg.maxOrderGenerationAttempts>=1);
env = CreateEnvironment(cfg);
for attempt = 1:cfg.maxOrderGenerationAttempts
    orderCfg = cfg;
    orderCfg.orderSeed = cfg.orderSeed+(attempt-1)*1000003;
    [orders,referenceRoute] = CreateOrders(env,orderCfg);
    events = CreateDynamicEvents(orders,cfg);
    initialIDs = find(strcmp({orders.status},'active'))';
    state.time = 0;
    state.position = env.depot;
    state.activeOrderIDs = initialIDs;
    state.servedOrderIDs = zeros(1,0);
    state.cancelledOrderIDs = zeros(1,0);
    state.committedRoute = zeros(1,0);
    state.lockedOrderIDs = zeros(1,0);
    state.fixedPrefixIDs = zeros(1,0);
    state.lastEvent = struct();
    state.inFlightOrderID = 0;
    state.inServiceOrderID = 0;
    state.status = 'idle';
    state.pending = struct('id',0,'departureTime',NaN, ...
        'arrivalTime',NaN,'serviceStart',NaN,'serviceEnd',NaN, ...
        'points',zeros(0,3));
    scenario.env = env;
    scenario.orders = orders;
    scenario.referenceRoute = referenceRoute;
    scenario.events = events;
    scenario.initialState = state;
    scenario.config = cfg;
    scenario.schemaVersion = '0.3-deterministic-reference-retry';
    scenario.level = lower(char(cfg.level));
    scenario.effectiveOrderSeed = orderCfg.orderSeed;
    scenario.orderGenerationAttempts = attempt;
    [scenario.referenceCost,scenario.referenceDetail] = ...
        EvaluateRoute(referenceRoute,scenario,state);
    if strcmpi(cfg.initialWindowMode,'legacy') || ...
            scenario.referenceDetail.isFeasible
        return;
    end
end
error('No feasible initial reference after %d order-seed attempts.', ...
    cfg.maxOrderGenerationAttempts);
end
