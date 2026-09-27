function [BestSol,BestCost,stats,history] = PSO(model,state,maxgen,Particle_Number,seed)
%PSO Baseline Random-key PSO using a compact teacher-style interface.
%   The implementation remains in src/RandomKeyPSO.m so the root entry
%   point stays easy to compare with other algorithms.
if nargin < 3 || isempty(maxgen), maxgen = 100; end
if nargin < 4 || isempty(Particle_Number), Particle_Number = 20; end
if nargin < 5, seed = 20260930; end
options.maxIt = maxgen;
options.nPop = Particle_Number;
options.maxFE = maxgen*Particle_Number;
options.seed = seed;
[BestSol,history,stats] = RandomKeyPSO(model,state,options);
BestCost = history.bestCost;
end
