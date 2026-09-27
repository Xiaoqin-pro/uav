function [cost,detail] = EvaluateRoute(routeIDs,scenario,state)
%EVALUATEROUTE Evaluate a future order route from the current UAV state.
%   The first baseline uses a finite scalar cost. The final algorithm will
%   replace this with an explicit feasibility-first comparator.
routeIDs = routeIDs(:)';
env = scenario.env;
orders = scenario.orders;
currentPosition = state.position;
currentTime = state.time;
totalDistance = 0;
totalLate = 0;
totalWaiting = 0;
totalViolation = 0;
totalSmoothness = 0;
minClearance = inf;
records = zeros(numel(routeIDs),10);
routeLegs = cell(numel(routeIDs),1);

for k = 1:numel(routeIDs)
    idx = find([orders.id] == routeIDs(k),1);
    if isempty(idx)
        error('Unknown order id %d.',routeIDs(k));
    end
    order = orders(idx);
    isPending = k==1 && isfield(state,'pending') && ...
        state.pending.id==order.id;
    if isPending
        pending = state.pending;
        arrival = pending.arrivalTime;
        serviceStart = pending.serviceStart;
        leg.points = pending.points;
        leg.distance = max(0,arrival-currentTime)*env.speed;
        leg.totalViolation = 0;
        leg.smoothness = 0;
        leg.minClearance = inf;
    else
        leg = Plan3DLeg(currentPosition,order.xyz,env);
        arrival = currentTime + leg.distance/env.speed;
        serviceStart = max([arrival,order.releaseTime,order.readyTime]);
    end
    late = max(0,serviceStart-order.dueTime);
    waiting = max(0,serviceStart-max(arrival,currentTime));
    if isPending
        currentTime = pending.serviceEnd;
    else
        currentTime = serviceStart + order.serviceTime;
    end
    currentPosition = order.xyz;

    totalDistance = totalDistance + leg.distance;
    totalLate = totalLate + late;
    totalWaiting = totalWaiting + waiting;
    totalViolation = totalViolation + leg.totalViolation;
    totalSmoothness = totalSmoothness + leg.smoothness;
    minClearance = min(minClearance,leg.minClearance);
    routeLegs{k} = leg;
    records(k,:) = [order.id,order.priority,arrival,serviceStart, ...
        late,waiting,leg.distance,leg.totalViolation, ...
        leg.minClearance,totalDistance];
end

% This first-stage contract does not force a return to the depot. The UAV
% can continue from its final delivery position at the next event.
finitePenalty = 1e4*totalViolation + 1e3*totalLate;
cost = totalDistance + env.smoothPenalty*totalSmoothness + finitePenalty;

detail.routeIDs = routeIDs;
detail.distance = totalDistance;
detail.totalLate = totalLate;
detail.totalWaiting = totalWaiting;
detail.totalViolation = totalViolation;
detail.totalSmoothness = totalSmoothness;
detail.minClearance = minClearance;
detail.finishTime = currentTime;
detail.finalPosition = currentPosition;
detail.records = records;
detail.routeLegs = routeLegs;
detail.isFeasible = totalViolation <= 1e-9 && totalLate <= 1e-9;
detail.comparisonVector = [totalViolation,totalLate, ...
    totalDistance+env.smoothPenalty*totalSmoothness];
end
