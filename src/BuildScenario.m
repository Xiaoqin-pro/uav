function scenario = BuildScenario(cfg)
%BUILDSCENARIO Build the complete reproducible problem instance.
if nargin < 1, cfg = struct(); end
if ~isfield(cfg,'nInitialOrders'), cfg.nInitialOrders = 20; end
if ~isfield(cfg,'nFutureOrders'), cfg.nFutureOrders = 8; end
if ~isfield(cfg,'terrainSeed'), cfg.terrainSeed = 20260927; end
if ~isfield(cfg,'orderSeed'), cfg.orderSeed = 20260928; end
if ~isfield(cfg,'eventSeed'), cfg.eventSeed = 20260929; end
if ~isfield(cfg,'level'), cfg.level = 'mild'; end

envCfg = cfg;
env = CreateEnvironment(envCfg);
[orders,referenceRoute] = CreateOrders(env,cfg);
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
scenario.schemaVersion = '0.2-dynamic-execution';
scenario.level = lower(char(cfg.level));
[scenario.referenceCost,scenario.referenceDetail] = ...
    EvaluateRoute(referenceRoute,scenario,state);
if strcmpi(GetInitialWindowMode(cfg),'reference') && ...
        ~scenario.referenceDetail.isFeasible
    error('Constructed reference route is not feasible; check data contract.');
end
end

function mode = GetInitialWindowMode(cfg)
if isfield(cfg,'initialWindowMode'), mode = cfg.initialWindowMode;
else, mode = 'reference'; end
end
