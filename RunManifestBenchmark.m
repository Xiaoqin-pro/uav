function RunManifestBenchmark(manifestPath,options)
%RUNMANIFESTBENCHMARK Run a fixed scenario manifest with no seed changes.
if nargin < 1 || isempty(manifestPath), error('manifestPath is required'); end
if nargin < 2 || isempty(options), options = PaperExperimentConfig; end
M = readtable(manifestPath,'TextType','string');
required = {'scenarioId','terrainSeed','orderSeed','eventSeed','algorithmSeed'};
assert(all(ismember(required,M.Properties.VariableNames)), ...
    'Manifest is missing a required seed column.');
rows = repmat(struct('scenarioId','','level','','run',0,'algorithm','', ...
    'terrainSeed',0,'requestedOrderSeed',0,'effectiveOrderSeed',0, ...
    'eventSeed',0,'algorithmSeed',0,'orderGenerationAttempts',0, ...
    'eventIndex',0,'eventTime',0,'eventType','','eventDescription','', ...
    'eventApplied',false,'nServed',0,'nActive',0,'nCancelled',0,'nLocked',0, ...
    'planCost',NaN,'distance',NaN,'totalLate',NaN,'totalViolation',NaN, ...
    'isFeasible',false,'eventSeverity',NaN,'responseTime',NaN, ...
    'functionEvaluations',0,'firstFeasibleFE',inf, ...
    'severityOrderChange',NaN,'severityUrgency',NaN, ...
    'severityRouteImpact',NaN,'guideWeight',NaN, ...
    'sourceHistCount',0,'sourceInsertionCount',0,'sourceImmigrantCount',0, ...
    'initialUniqueCount',0,'initialTargetUniqueCount',0, ...
    'initialDuplicateRetries',0,'initialUniqueExhausted',false),0,1);
recovery = table();
for i = 1:height(M)
    cfg.nInitialOrders = options.nInitialOrders;
    cfg.nFutureOrders = options.nFutureOrders;
    cfg.level = options.levels{1};
    cfg.safetySamples = options.safetySamples;
    cfg.initialWindowMode = 'reference';
    cfg.windowLengthOverride = options.windowLengthOverride;
    cfg.releaseStart = options.releaseStart;
    cfg.releaseInterval = options.releaseInterval;
    cfg.terrainSeed = M.terrainSeed(i);
    cfg.orderSeed = M.orderSeed(i);
    cfg.eventSeed = M.eventSeed(i);
    model = CreateModel(cfg);
    audit = ValidateScenario(model);
    assert(audit.ok,strjoin(audit.errors,' | '));
    for a = 1:numel(options.algorithms)
        algorithm = options.algorithms{a};
        result = RunDynamicEpisode(model,algorithm,options.maxgen, ...
            options.Particle_Number,M.algorithmSeed(i),options.sourceComposition);
        for e = 1:numel(result.records)
            row = result.records(e);
            row.scenarioId = char(M.scenarioId(i));
            row.level = cfg.level;
            row.run = i;
            row.algorithm = algorithm;
            row.terrainSeed = cfg.terrainSeed;
            row.requestedOrderSeed = cfg.orderSeed;
            row.effectiveOrderSeed = model.effectiveOrderSeed;
            row.eventSeed = cfg.eventSeed;
            row.algorithmSeed = M.algorithmSeed(i);
            row.orderGenerationAttempts = model.orderGenerationAttempts;
            rows(end+1) = row; %#ok<AGROW>
            h = result.histories{e+1};
            n = numel(h.FE);
            C = table(repmat(string(M.scenarioId(i)),n,1), ...
                repmat(i,n,1),repmat(string(algorithm),n,1), ...
                repmat(e,n,1),repmat(string(result.records(e).eventType),n,1), ...
                repmat(result.records(e).eventApplied,n,1),h.FE(:), ...
                h.totalLate(:),h.totalViolation(:),logical(h.isFeasible(:)), ...
                'VariableNames',{'scenarioId','run','algorithm','eventIndex', ...
                'eventType','eventApplied','FE','totalLate', ...
                'totalViolation','isFeasible'});
            if isempty(recovery), recovery = C; else, recovery=[recovery;C]; end
        end
    end
    fprintf('Manifest scenario %s (%d/%d) complete.\n', ...
        char(M.scenarioId(i)),i,height(M));
end
T = struct2table(rows);
outDir = fullfile(fileparts(mfilename('fullpath')),'results');
if ~exist(outDir,'dir'), mkdir(outDir); end
writetable(T,fullfile(outDir,[options.outputStem,'.csv']));
writetable(recovery,fullfile(outDir,[options.outputStem,'_recovery.csv']));
save(fullfile(outDir,[options.outputStem,'.mat']),'T','recovery','options','manifestPath');
end
