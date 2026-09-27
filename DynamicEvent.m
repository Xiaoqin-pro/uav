function [model,state,applied] = DynamicEvent(model,state,event)
%DYNAMICEVENT Teacher-style dynamic-event entry point.
[model,state,applied] = ApplyDynamicEvent(model,state,event);
end
