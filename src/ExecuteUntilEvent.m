function [state,remainingRoute,log] = ExecuteUntilEvent(scenario,state,plannedRoute,eventTime)
%EXECUTEUNTILEVENT Execute a committed route up to the next event.
%   An in-progress flight/wait/service retains its original completion
%   times across repeated events. The current target is a fixed prefix.
if eventTime < state.time-1e-10
    error('eventTime must not precede the current state time.');
end
route = plannedRoute(:)';
log = repmat(struct('orderID',0,'status','','arrivalTime',NaN, ...
    'serviceStart',NaN,'serviceEnd',NaN),0,1);
remainingRoute = route;
if ~isfield(state,'pending') || isempty(state.pending)
    state.pending = struct('id',0,'departureTime',NaN, ...
        'arrivalTime',NaN,'serviceStart',NaN,'serviceEnd',NaN, ...
        'points',zeros(0,3));
end
k = 1;
while k <= numel(route)
    id = route(k);
    if ~ismember(id,state.activeOrderIDs), k = k+1; continue; end
    idx = find([scenario.orders.id] == id,1);
    if state.pending.id ~= id
        if eventTime <= state.time+1e-10, break; end
        if state.pending.id ~= 0
            error('The committed target %d cannot be reordered.',state.pending.id);
        end
        order = scenario.orders(idx);
        leg = Plan3DLeg(state.position,order.xyz,scenario.env);
        departureTime = state.time;
        arrival = departureTime + leg.distance/scenario.env.speed;
        start = max([arrival,order.releaseTime,order.readyTime]);
        state.pending = struct('id',id,'departureTime',departureTime, ...
            'arrivalTime',arrival,'serviceStart',start, ...
            'serviceEnd',start+order.serviceTime,'points',leg.points);
    end
    p = state.pending;
    if eventTime < p.serviceEnd-1e-10
        state.time = eventTime;
        if eventTime < p.arrivalTime-1e-10
            distance = max(0,eventTime-p.departureTime)*scenario.env.speed;
            state.position = PointAlongPolyline(p.points,distance);
            state.status = 'in-flight';
            state.inFlightOrderID = id;
            state.inServiceOrderID = 0;
        else
            state.position = scenario.orders(idx).xyz;
            state.status = 'waiting';
            if eventTime >= p.serviceStart-1e-10
                state.status = 'servicing';
            end
            state.inFlightOrderID = 0;
            state.inServiceOrderID = id;
        end
        state.lockedOrderIDs = id;
        state.fixedPrefixIDs = id;
        state.committedRoute = route(k:end);
        remainingRoute = route(k:end);
        log(end+1) = MakeLog(id,state.status,p); %#ok<AGROW>
        return;
    end
    state.position = scenario.orders(idx).xyz;
    state.time = p.serviceEnd;
    state.activeOrderIDs(state.activeOrderIDs==id) = [];
    state.servedOrderIDs(end+1) = id;
    log(end+1) = MakeLog(id,'served',p); %#ok<AGROW>
    state.pending.id = 0;
    k = k+1;
end
state.time = eventTime;
state.status = 'idle';
state.inFlightOrderID = 0;
state.inServiceOrderID = 0;
state.lockedOrderIDs = zeros(1,0);
state.fixedPrefixIDs = zeros(1,0);
remainingRoute = route(k:end);
state.committedRoute = remainingRoute;
end

function p = PointAlongPolyline(points,distance)
seg = diff(points,1,1);
len = sqrt(sum(seg.^2,2));
target = min(max(distance,0),sum(len));
acc = 0;
for k = 1:numel(len)
    if target <= acc+len(k) || k==numel(len)
        p = points(k,:) + (target-acc)/max(len(k),eps)*seg(k,:);
        return;
    end
    acc = acc+len(k);
end
p = points(end,:);
end

function item = MakeLog(id,status,p)
item = struct('orderID',id,'status',status, ...
    'arrivalTime',p.arrivalTime,'serviceStart',p.serviceStart, ...
    'serviceEnd',p.serviceEnd);
end
