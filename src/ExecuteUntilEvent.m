function [state,remainingRoute,log] = ExecuteUntilEvent(scenario,state,plannedRoute,eventTime)
%EXECUTEUNTILEVENT Advance the UAV until a dynamic event time.
%   The planned route is executed continuously. If the event occurs while
%   flying, waiting, or servicing, the current order becomes locked and the
%   returned state is the state at the event time.
if nargin < 4, error('scenario, state, plannedRoute and eventTime are required'); end
if eventTime < state.time-1e-10
    error('eventTime must not be earlier than state.time.');
end
route = plannedRoute(:)';
currentPosition = state.position;
currentTime = state.time;
remainingRoute = route;
log = repmat(struct('orderID',0,'status','','startTime',0, ...
    'endTime',0,'arrivalTime',NaN,'serviceStart',NaN,'serviceEnd',NaN),0,1);
state.inFlightOrderID = 0;
state.inServiceOrderID = 0;
state.lockedOrderIDs = zeros(1,0);
state.status = 'idle';

for k = 1:numel(route)
    id = route(k);
    idx = find([scenario.orders.id] == id,1);
    if isempty(idx) || ~ismember(id,state.activeOrderIDs)
        continue;
    end
    order = scenario.orders(idx);
    leg = Plan3DLeg(currentPosition,order.xyz,scenario.env);
    travelTime = leg.distance/scenario.env.speed;
    arrivalTime = currentTime + travelTime;

    if eventTime < arrivalTime-1e-10
        travelled = max(0,eventTime-currentTime)*scenario.env.speed;
        state.position = PointAlongPolyline(leg.points,travelled);
        state.time = eventTime;
        state.inFlightOrderID = id;
        state.lockedOrderIDs = id;
        state.status = 'in-flight';
        remainingRoute = route(k:end);
        log(end+1) = MakeLog(id,'in-flight',currentTime,eventTime, ...
            arrivalTime,NaN,NaN); %#ok<AGROW>
        state.committedRoute = remainingRoute;
        return;
    end

    serviceStart = max([arrivalTime,order.releaseTime,order.readyTime]);
    if eventTime < serviceStart-1e-10
        state.position = order.xyz;
        state.time = eventTime;
        state.inServiceOrderID = id;
        state.lockedOrderIDs = id;
        state.status = 'waiting';
        remainingRoute = route(k:end);
        log(end+1) = MakeLog(id,'waiting',currentTime,eventTime, ...
            arrivalTime,serviceStart,NaN); %#ok<AGROW>
        state.committedRoute = remainingRoute;
        return;
    end

    serviceEnd = serviceStart + order.serviceTime;
    if eventTime < serviceEnd-1e-10
        state.position = order.xyz;
        state.time = eventTime;
        state.inServiceOrderID = id;
        state.lockedOrderIDs = id;
        state.status = 'servicing';
        remainingRoute = route(k:end);
        log(end+1) = MakeLog(id,'servicing',currentTime,eventTime, ...
            arrivalTime,serviceStart,serviceEnd); %#ok<AGROW>
        state.committedRoute = remainingRoute;
        return;
    end

    currentPosition = order.xyz;
    currentTime = serviceEnd;
    state.activeOrderIDs(state.activeOrderIDs==id) = [];
    state.servedOrderIDs(end+1) = id;
    scenario.orders(idx).status = 'served';
    log(end+1) = MakeLog(id,'served',currentTime-serviceEnd,currentTime, ...
        arrivalTime,serviceStart,serviceEnd); %#ok<AGROW>
    remainingRoute = route(k+1:end);
end

state.position = currentPosition;
state.time = eventTime;
state.committedRoute = remainingRoute;
state.status = 'idle';
end

function p = PointAlongPolyline(points,distance)
if isempty(points), p = [0 0 0]; return; end
if size(points,1)==1, p = points(1,:); return; end
seg = diff(points,1,1);
len = sqrt(sum(seg.^2,2));
target = min(max(distance,0),sum(len));
if target <= 0, p = points(1,:); return; end
acc = 0;
for k = 1:numel(len)
    if target <= acc+len(k) || k==numel(len)
        ratio = (target-acc)/max(len(k),eps);
        p = points(k,:) + ratio*seg(k,:);
        return;
    end
    acc = acc + len(k);
end
p = points(end,:);
end

function item = MakeLog(id,status,startTime,endTime,arrival,serviceStart,serviceEnd)
item.orderID = id;
item.status = status;
item.startTime = startTime;
item.endTime = endTime;
item.arrivalTime = arrival;
item.serviceStart = serviceStart;
item.serviceEnd = serviceEnd;
end
