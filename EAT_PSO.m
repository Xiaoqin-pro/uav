function [BestSol,BestCost,stats,history] = EAT_PSO(model,state,maxgen,Particle_Number,previousSolution,seed,variant,sourceComposition)
%EAT_PSO Event-aware transfer PSO.
%   Paper-core uses event-triggered multi-source population reconstruction
%   with fixed guide weight 0.5. Adaptive transfer is exploratory only.
if nargin < 3 || isempty(maxgen), maxgen = 100; end
if nargin < 4 || isempty(Particle_Number), Particle_Number = 20; end
if nargin < 5, previousSolution = []; end
if nargin < 6, seed = 20260930; end
if nargin < 7 || isempty(variant), variant = 'paper-core'; end
if nargin < 8 || isempty(sourceComposition), sourceComposition = [2 3 1]; end
options.maxIt = maxgen;
options.nPop = Particle_Number;
options.maxFE = maxgen*Particle_Number;
options.seed = seed;
options.variant = variant;
options.sourceComposition = sourceComposition;
[BestSol,history,stats] = EventAwareTransferPSO(model,state,options,previousSolution);
BestCost = history.bestCost;
end
