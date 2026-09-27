function [scenario,state,applied] = ApplyDynamicEvent(scenario,state,event)
%APPLYDYNAMICEVENT Apply an add/cancel event to the active order set.
%   This function does not move the UAV. Execution simulation will be added
%   after the data contract and static route evaluator are validated.
if nargin < 3, error('scenario, state and event are required'); end
applied = false;
ids = event.orderIDs(:)';
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
                ~ismember(id,state.servedOrderIDs)
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
end
