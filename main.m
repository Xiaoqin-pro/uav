clc
clear
close all

% MAIN Teacher-style one-click experiment entry point.
% The code intentionally keeps the flat structure of the supplied teacher
% project: create data, run baseline/novel algorithm, compare curves, save.
root = fileparts(mfilename('fullpath'));
setup;

%% Problem data
cfg.nInitialOrders = 8;
cfg.nFutureOrders = 4;
cfg.terrainSeed = 20260927;
cfg.orderSeed = 20260928;
cfg.eventSeed = 20260929;
cfg.safetySamples = 25;
model = CreateModel(cfg);
report = ValidateScenario(model);
assert(report.ok,strjoin(report.errors,' | '));
state = model.initialState;

%% Initial planning
Particle_Number = 8;
maxgen = 6;
seed = 20261001;
[Best0,T0,stats0] = PSO(model,state,maxgen,Particle_Number,seed);

%% Execute until the first dynamic order event, then apply it
[eventState,remainingRoute,executionLog] = ExecuteUntilEvent( ...
    model,state,Best0.Route,model.events(1).time);
previousBeforeEvent = Best0;
previousBeforeEvent.Route = remainingRoute;
[eventModel,eventState,applied] = DynamicEvent(model,eventState,model.events(1));
assert(applied,'The first dynamic event was not applied.');

%% Replan after the event: baseline versus event-aware PSO
[WarmBest,TWarm,statsWarm] = PSO(eventModel,eventState,maxgen,Particle_Number,seed+1);
[EATBest,TEAT,statsEAT] = EAT_PSO(eventModel,eventState,maxgen, ...
    Particle_Number,previousBeforeEvent,seed+2);

%% Save machine-readable demo output
outDir = fullfile(root,'results');
if ~exist(outDir,'dir'), mkdir(outDir); end
save(fullfile(outDir,'main_demo.mat'),'model','state','Best0','T0', ...
    'stats0','executionLog','remainingRoute','eventModel','eventState','WarmBest','TWarm','statsWarm', ...
    'EATBest','TEAT','statsEAT');
PlotSolution(eventModel,eventState,EATBest, ...
    fullfile(outDir,'main_eat_pso_route.png'));

figure('Color','w');
plot(TWarm,'LineWidth',1.5); hold on;
plot(TEAT,'LineWidth',1.5);
grid on;
xlabel('Iteration'); ylabel('Best cost');
legend('Warm-start PSO','EAT-PSO','Location','best');
title('Dynamic event replanning demo');
exportgraphics(gcf,fullfile(outDir,'main_replanning_convergence.png'), ...
    'Resolution',150);
close(gcf);

fprintf('Initial route cost: %.3f\n',Best0.Cost);
fprintf('Warm-start cost after event: %.3f\n',WarmBest.Cost);
fprintf('EAT-PSO cost after event: %.3f\n',EATBest.Cost);
fprintf('Estimated event severity: %.3f\n',statsEAT.eventSeverity);

