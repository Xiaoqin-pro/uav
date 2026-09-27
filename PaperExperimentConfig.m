function o = PaperExperimentConfig
%PAPEREXPERIMENTCONFIG Frozen candidate configuration for paper v1.
%   Do not change after the pipeline dry run without creating a new version.
o.version = 'paper-v1-candidate';
o.levels = {'severe'};
o.windowLengthOverride = 135;
o.releaseStart = 45;
o.releaseInterval = 15;
o.nInitialOrders = 8;
o.nFutureOrders = 6;
o.safetySamples = 8;
o.Particle_Number = 6;
o.maxgen = 3;
o.maxFE = 18;
o.algorithms = {'PSO','Warm-PSO','Warm-ALNS','EAT-PSO'};
o.ablationAlgorithms = {'EAT-PSO','EAT-NoReconstruction'};
o.censoredFE = o.maxFE+1;
o.primaryEventType = 'add';
o.stats = {'mean','std','median','paired-wilcoxon','holm'};
o.holdoutManifest = fullfile('data','reserved_holdout_seeds.csv');
o.dryrunManifest = fullfile('data','pipeline_dryrun_v1_seeds.csv');
o.outputStem = 'paper_v1';
end
