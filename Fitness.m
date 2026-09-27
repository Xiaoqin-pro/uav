function [cost,detail] = Fitness(route,model,state)
%FITNESS Teacher-style route fitness entry point.
%   route is an order-ID sequence; model is the scenario structure.
if nargin < 3, state = model.initialState; end
[cost,detail] = EvaluateRoute(route,model,state);
end
