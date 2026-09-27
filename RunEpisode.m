function result = RunEpisode(model,algorithm,maxgen,Particle_Number,seed)
%RUNEpisode Teacher-style root entry point for a complete dynamic episode.
if nargin < 2, algorithm = 'PSO'; end
if nargin < 3, maxgen = 20; end
if nargin < 4, Particle_Number = 20; end
if nargin < 5, seed = 20261010; end
result = RunDynamicEpisode(model,algorithm,maxgen,Particle_Number,seed);
end
