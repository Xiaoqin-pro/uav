function [BestSol,BestCost,stats] = EAT_PSO(model,state,maxgen,Particle_Number,previousSolution,seed,variant)
%EAT_PSO Event-aware transfer PSO.
%   This is the first implementation of the proposed structure:
%   multi-source population transfer plus event-severity-dependent guide
%   mixing. It deliberately keeps the same compact interface as PSO.m.
if nargin < 3 || isempty(maxgen), maxgen = 100; end
if nargin < 4 || isempty(Particle_Number), Particle_Number = 20; end
if nargin < 5, previousSolution = []; end
if nargin < 6, seed = 20260930; end
if nargin < 7 || isempty(variant), variant = 'full'; end
options.maxIt = maxgen;
options.nPop = Particle_Number;
options.maxFE = maxgen*Particle_Number;
options.seed = seed;
options.variant = variant;
[BestSol,history,stats] = EventAwareTransferPSO(model,state,options,previousSolution);
BestCost = history.bestCost;
end
