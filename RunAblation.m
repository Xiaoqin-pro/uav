function RunAblation(options)
%RUNABLATION Paired, equal-FE development experiment for the two mechanisms.
if nargin < 1, options = struct(); end
options.algorithms = {'PSO','Warm-PSO','EAT-NoReconstruction', ...
    'EAT-FixedSeverity','EAT-PSO'};
if ~isfield(options,'outputStem')
    options.outputStem = 'ablation_dynamic_pilot';
end
RunFormalBenchmark(options);
end
