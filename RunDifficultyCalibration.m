function RunDifficultyCalibration(options)
%RUNDIFFICULTYCALIBRATION Blind calibration of scenario execution difficulty.
%   This calibration intentionally excludes EAT-PSO. It checks whether the
%   generated scenarios create meaningful differences before final testing.
if nargin < 1, options = struct(); end
options = FillOptions(options);
algorithms = {'PSO','Warm-PSO'};
eventRows = table();
rows = repmat(struct('level','','run',0,'algorithm','', ...
    'nEvents',0,'referenceFeasible',false,'referenceCost',NaN, ...
    'initialFeasible',false,'initialLate',NaN, ...
    'eventAppliedRate',NaN,'addAppliedRate',NaN, ...
    'cancelAppliedRate',NaN,'eventFeasibleRate',NaN, ...
    'appliedEventFeasibleRate',NaN, ...
    'meanLate',NaN,'meanViolation',NaN,'meanDistance',NaN, ...
    'meanResponseTime',NaN,'meanFunctionEvaluations',NaN),0,1);

for levelIndex = 1:numel(options.levels)
    for runIndex = 1:options.nRuns
        cfg.nInitialOrders = options.nInitialOrders;
        cfg.nFutureOrders = options.nFutureOrders;
        cfg.level = options.levels{levelIndex};
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

        for a = 1:numel(algorithms)
            algorithm = algorithms{a};
            seed = options.baseAlgorithmSeed + 10000*levelIndex ...
                + 100*runIndex;
            result = RunDynamicEpisode(model,algorithm,options.maxgen, ...
                options.Particle_Number,seed);
            T = struct2table(result.records);
            row.level = options.levels{levelIndex};
            row.run = runIndex;
            row.algorithm = algorithm;
            row.nEvents = height(T);
            row.referenceFeasible = model.referenceDetail.isFeasible;
            row.referenceCost = model.referenceCost;
            row.initialFeasible = result.plans{1}.Detail.isFeasible;
            row.initialLate = result.plans{1}.Detail.totalLate;
            T.level = repmat(string(cfg.level),height(T),1);
            T.run = repmat(runIndex,height(T),1);
            T.algorithm = repmat(string(algorithm),height(T),1);
            T.terrainSeed = repmat(cfg.terrainSeed,height(T),1);
            T.orderSeed = repmat(cfg.orderSeed,height(T),1);
            T.eventSeed = repmat(cfg.eventSeed,height(T),1);
            T.algorithmSeed = repmat(seed,height(T),1);
            if isempty(eventRows), eventRows = T; else, eventRows = [eventRows;T]; end
            row.eventAppliedRate = mean(double(T.eventApplied));
            addMask = strcmp(T.eventType,'add');
            cancelMask = strcmp(T.eventType,'cancel');
            row.addAppliedRate = mean(double(T.eventApplied(addMask)));
            row.cancelAppliedRate = mean(double(T.eventApplied(cancelMask)));
            row.eventFeasibleRate = mean(double(T.isFeasible));
            appliedMask = logical(T.eventApplied);
            if any(appliedMask)
                row.appliedEventFeasibleRate = mean(double(T.isFeasible(appliedMask)));
            else
                row.appliedEventFeasibleRate = NaN;
            end
            row.meanLate = mean(T.totalLate);
            row.meanViolation = mean(T.totalViolation);
            row.meanDistance = mean(T.distance);
            row.meanResponseTime = mean(T.responseTime);
            row.meanFunctionEvaluations = mean(T.functionEvaluations);
            rows(end+1) = row; %#ok<AGROW>
        end
        fprintf('Calibrated level=%s run=%d/%d\n', ...
            options.levels{levelIndex},runIndex,options.nRuns);
    end
end

T = struct2table(rows);
outDir = fullfile(fileparts(mfilename('fullpath')),'results');
if ~exist(outDir,'dir'), mkdir(outDir); end
writetable(T,fullfile(outDir,[options.outputStem,'.csv']));
writetable(eventRows,fullfile(outDir,[options.outputStem,'_events.csv']));
save(fullfile(outDir,[options.outputStem,'.mat']),'T','eventRows','options');
disp(T);
end

function options = FillOptions(options)
defaults = struct('levels',{{'mild','moderate','severe'}}, ...
    'outputStem','difficulty_calibration','nRuns',5, ...
    'nInitialOrders',8,'nFutureOrders',6, ...
    'safetySamples',15,'Particle_Number',8,'maxgen',8, ...
    'baseTerrainSeed',20267000,'baseOrderSeed',20268000, ...
    'baseEventSeed',20269000,'baseAlgorithmSeed',20270000);
fields = fieldnames(defaults);
for k = 1:numel(fields)
    if ~isfield(options,fields{k}) || isempty(options.(fields{k}))
        options.(fields{k}) = defaults.(fields{k});
    end
end
end
