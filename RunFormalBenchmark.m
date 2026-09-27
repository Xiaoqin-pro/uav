function RunFormalBenchmark(options)
%RUNFORMALBENCHMARK Paired dynamic development runner and FE histories.
%   Default values are intentionally small enough for development. Increase
%   nRuns, maxgen and Particle_Number only after the data contract is frozen.
if nargin < 1, options = struct(); end
options = FillOptions(options);
levels = options.levels;
algorithms = options.algorithms;
rows = repmat(struct('level','','run',0,'algorithm','','eventIndex',0, ...
    'eventTime',0,'eventType','','eventDescription','','eventApplied',false,'nServed',0, ...
    'nActive',0,'nCancelled',0,'nLocked',0,'planCost',NaN, ...
    'distance',NaN,'totalLate',NaN,'totalViolation',NaN, ...
    'isFeasible',false,'eventSeverity',NaN,'responseTime',NaN, ...
    'functionEvaluations',0,'firstFeasibleFE',inf, ...
    'severityOrderChange',NaN,'severityUrgency',NaN, ...
    'severityRouteImpact',NaN,'guideWeight',NaN),0,1);
recoveryRows = table();

for levelIndex = 1:numel(levels)
    for runIndex = 1:options.nRuns
        cfg.nInitialOrders = options.nInitialOrders;
        cfg.nFutureOrders = options.nFutureOrders;
        cfg.level = levels{levelIndex};
        cfg.safetySamples = options.safetySamples;
        cfg.initialWindowMode = 'reference';
        if isfield(options,'windowLengthOverride')
            cfg.windowLengthOverride = options.windowLengthOverride;
        end
        if isfield(options,'releaseStart'), cfg.releaseStart = options.releaseStart; end
        if isfield(options,'releaseInterval')
            cfg.releaseInterval = options.releaseInterval;
        end
        cfg.terrainSeed = options.baseTerrainSeed + runIndex;
        cfg.orderSeed = options.baseOrderSeed + 100*levelIndex + runIndex;
        cfg.eventSeed = options.baseEventSeed + 1000*levelIndex + runIndex;
        model = CreateModel(cfg);
        audit = ValidateScenario(model);
        assert(audit.ok,strjoin(audit.errors,' | '));

        for algorithmIndex = 1:numel(algorithms)
            algorithm = algorithms{algorithmIndex};
            seed = options.baseAlgorithmSeed ...
                + 10000*levelIndex + 100*runIndex;
            result = RunDynamicEpisode(model,algorithm,options.maxgen, ...
                options.Particle_Number,seed);
            for e = 1:numel(result.records)
                row = result.records(e);
                row.level = levels{levelIndex};
                row.run = runIndex;
                row.algorithm = algorithm;
                rows(end+1) = row; %#ok<AGROW>
                h = result.histories{e+1};
                n = numel(h.FE);
                C = table(repmat(string(levels{levelIndex}),n,1), ...
                    repmat(runIndex,n,1),repmat(string(algorithm),n,1), ...
                    repmat(e,n,1),repmat(result.records(e).eventTime,n,1), ...
                    repmat(string(result.records(e).eventType),n,1), ...
                    repmat(result.records(e).eventApplied,n,1), ...
                    h.FE(:),h.totalLate(:),h.totalViolation(:), ...
                    logical(h.isFeasible(:)),h.distance(:), ...
                    'VariableNames',{'level','run','algorithm','eventIndex', ...
                    'eventTime','eventType','eventApplied','FE', ...
                    'totalLate','totalViolation','isFeasible','distance'});
                if isempty(recoveryRows), recoveryRows = C;
                else, recoveryRows = [recoveryRows;C]; end
            end
        end
        fprintf('Finished level=%s run=%d/%d\n', ...
            levels{levelIndex},runIndex,options.nRuns);
    end
end

T = struct2table(rows);
outDir = fullfile(fileparts(mfilename('fullpath')),'results');
if ~exist(outDir,'dir'), mkdir(outDir); end
writetable(T,fullfile(outDir,[options.outputStem,'.csv']));
writetable(recoveryRows,fullfile(outDir,[options.outputStem,'_recovery.csv']));
save(fullfile(outDir,[options.outputStem,'.mat']), ...
    'T','recoveryRows','options');
end

function options = FillOptions(options)
defaults = struct(...
    'levels',{{'mild','moderate','severe'}}, ...
    'algorithms',{{'PSO','Warm-PSO','EAT-PSO'}}, ...
    'outputStem','formal_dynamic_benchmark', ...
    'nRuns',3,'nInitialOrders',8,'nFutureOrders',6, ...
    'safetySamples',20,'Particle_Number',10,'maxgen',20, ...
    'baseTerrainSeed',20262000,'baseOrderSeed',20263000, ...
    'baseEventSeed',20264000,'baseAlgorithmSeed',20265000);
fields = fieldnames(defaults);
for k = 1:numel(fields)
    if ~isfield(options,fields{k}) || isempty(options.(fields{k}))
        options.(fields{k}) = defaults.(fields{k});
    end
end
end
