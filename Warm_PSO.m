function [BestSol,BestCost,stats] = Warm_PSO(model,state,maxgen,Particle_Number,previousSolution,seed)
%WARM_PSO Warm-start PSO baseline: only a small fraction of particles are
% initialized from the previous route; the rest remain random.
if nargin < 3 || isempty(maxgen), maxgen = 100; end
if nargin < 4 || isempty(Particle_Number), Particle_Number = 20; end
if nargin < 5, previousSolution = []; end
if nargin < 6, seed = 20260930; end
options.maxIt = maxgen;
options.nPop = Particle_Number;
options.maxFE = maxgen*Particle_Number;
options.seed = seed;
if ~isempty(previousSolution) && isfield(previousSolution,'Route')
    options.initialRoute = previousSolution.Route;
else
    options.initialRoute = [];
end
[BestSol,history,stats] = RandomKeyPSO(model,state,options);
BestCost = history.bestCost;
end
