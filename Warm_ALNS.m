function [BestSol,BestCost,stats,history] = Warm_ALNS(model,state,maxgen,Particle_Number,previousSolution,seed)
%WARM_ALNS Warm-start adaptive large-neighborhood routing baseline.
%   Uses the same route evaluator and maxgen*Particle_Number full-route FE.
%   Destroy/repair surrogate work is accounted for in wall-clock time.
if nargin < 3 || isempty(maxgen), maxgen = 100; end
if nargin < 4 || isempty(Particle_Number), Particle_Number = 20; end
if nargin < 5, previousSolution = []; end
if nargin < 6, seed = 20260930; end
options.maxFE = maxgen*Particle_Number;
options.checkpointFE = Particle_Number;
options.seed = seed;
[BestSol,history,stats] = WarmALNS(model,state,options,previousSolution);
BestCost = history.bestCost;
end
