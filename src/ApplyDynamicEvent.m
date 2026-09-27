function [scenario,state,applied] = ApplyDynamicEvent(scenario,state,event)
%APPLYDYNAMICEVENT Apply an add/cancel event to the active order set.
%   The UAV state should be advanced by ExecuteUntilEvent before this function
%   is called. Cancellation of an in-flight/servicing order is rejected.
if nargin < 3, error('scenario, state and event are required'); end
applied = false;
ids = event.orderIDs(:)';
preIDs = state.activeOrderIDs;
preIdx = ismember([scenario.orders.id],preIDs);
state.lastEvent = struct('time',event.time,'type',event.type, ...
    'orderIDs',ids,'preActiveIDs',preIDs, ...
    'preReadyTimes',[scenario.orders(preIdx).readyTime], ...
    'preDueTimes',[scenario.orders(preIdx).dueTime]);
for id = ids
    idx = find([scenario.orders.id] == id,1);
    if isempty(idx), continue; end
    if strcmp(event.type,'add')
        if ~ismember(id,state.activeOrderIDs) && ...
                ~ismember(id,state.servedOrderIDs) && ...
                ~ismember(id,state.cancelledOrderIDs)
            state.activeOrderIDs(end+1) = id;
            scenario.orders(idx).status = 'active';
            applied = true;
        end
    elseif strcmp(event.type,'cancel')
        if ismember(id,state.activeOrderIDs) && ...
                ~ismember(id,state.servedOrderIDs) && ...
                ~ismember(id,state.lockedOrderIDs)
            state.activeOrderIDs(state.activeOrderIDs==id) = [];
            state.cancelledOrderIDs(end+1) = id;
            scenario.orders(idx).status = 'cancelled';
            applied = true;
        end
    else
        error('Unsupported event type: %s',event.type);
    end
end
state.time = max(state.time,event.time);
if ~isfield(state,'eventLog'), state.eventLog = {}; end
state.lastEvent.postActiveIDs = state.activeOrderIDs;
postIdx = ismember([scenario.orders.id],state.activeOrderIDs);
state.lastEvent.postReadyTimes = [scenario.orders(postIdx).readyTime];
state.lastEvent.postDueTimes = [scenario.orders(postIdx).dueTime];
state.lastEvent.applied = applied;
state.lastEvent.description = event.description;
state.eventLog{end+1} = struct('time',event.time,'type',event.type, ...
    'orderIDs',ids,'applied',applied,'description',event.description);
end
