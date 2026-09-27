function model = CreateModel(cfg)
%CREATEMODEL Teacher-style entry point for the dynamic UAV model.
%   The returned structure contains env, orders, events and initialState.
if nargin < 1, cfg = struct(); end
model = BuildScenario(cfg);
end
