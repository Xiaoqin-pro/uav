function [severity,components] = EstimateEventSeverity(activeIDs,previousSolution,scenario,state)
%ESTIMATEEVENTSEVERITY Pre-search event impact proxy; no optimizer results.
% Components: order-set change, deadline-pressure change, route detour.
if ~isfield(state,'lastEvent') || isempty(fieldnames(state.lastEvent)) ...
        || ~isfield(state.lastEvent,'applied') || ~state.lastEvent.applied
    severity = 0;
    components = [0 0 0];
    return;
end
event = state.lastEvent;
oldIDs = event.preActiveIDs(:)';
newIDs = state.activeOrderIDs(:)';
change = min(1,numel(setxor(oldIDs,newIDs))/max([numel(oldIDs),numel(newIDs),1]));
oldPressure = DeadlinePressure(oldIDs,scenario,state.time);
newPressure = DeadlinePressure(newIDs,scenario,state.time);
urgency = abs(newPressure-oldPressure);

structure = numel(setdiff(oldIDs,newIDs))/max(numel(oldIDs),1);
added = setdiff(newIDs,oldIDs,'stable');
if ~isempty(added) && ~isempty(previousSolution) && ...
        isfield(previousSolution,'Route')
    retained = intersect(previousSolution.Route(:)',oldIDs,'stable');
    retained = intersect(retained,newIDs,'stable');
    pts = [state.position;OrderPoints(retained,scenario)];
    lengthBefore = sum(sqrt(sum(diff(pts,1,1).^2,2)));
    extra = 0;
    for id = added
        p = OrderPoints(id,scenario);
        if size(pts,1)==1
            delta = norm(p-pts(1,:));
        else
            deltas = norm(p-pts(end,:));
            for k = 1:size(pts,1)-1
                d = norm(pts(k,:)-p)+norm(p-pts(k+1,:)) ...
                    -norm(pts(k,:)-pts(k+1,:));
                deltas(end+1) = d; %#ok<AGROW>
            end
            delta = min(deltas);
        end
        extra = extra+delta;
    end
    structure = max(structure,min(1,extra/max(lengthBefore,1)));
end
components = [change,urgency,min(1,structure)];
severity = min(1,max(0,0.4*components(1)+0.3*components(2) ...
    +0.3*components(3)));
end

function pressure = DeadlinePressure(ids,scenario,t)
if isempty(ids), pressure = 0; return; end
orders = scenario.orders;
pressure = zeros(size(ids));
for k = 1:numel(ids)
    o = orders([orders.id]==ids(k));
    window = max(o.dueTime-o.readyTime,1);
    remaining = max(0,o.dueTime-t);
    pressure(k) = 1-min(1,remaining/window);
end
pressure = mean(pressure);
end

function pts = OrderPoints(ids,scenario)
pts = zeros(numel(ids),3);
for k = 1:numel(ids)
    o = scenario.orders([scenario.orders.id]==ids(k));
    pts(k,:) = o.xyz;
end
end
