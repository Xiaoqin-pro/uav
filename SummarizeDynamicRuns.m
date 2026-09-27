function [runTable,summaryTable] = SummarizeDynamicRuns(csvPath,outputStem)
%SUMMARIZEDYNAMICRUNS Treat each scenario/seed run as one replicate.
%   Event rows are correlated within a run. This function does not perform
%   significance testing or convert diagnostic results to paper evidence.
if nargin < 1 || isempty(csvPath)
    root = fileparts(mfilename('fullpath'));
    csvPath = fullfile(root,'results','formal_dynamic_benchmark.csv');
end
if nargin < 2 || isempty(outputStem), outputStem = 'dynamic_diagnostic'; end
T = readtable(csvPath);
levels = unique(T.level,'stable');
algorithms = unique(T.algorithm,'stable');
runRows = repmat(struct('level','','run',0,'algorithm','', ...
    'nEvents',0,'nApplied',0,'feasibleRate',NaN, ...
    'appliedFeasibleRate',NaN,'meanLate',NaN, ...
    'meanDistance',NaN,'meanResponseTime',NaN, ...
    'meanFE',NaN),0,1);
for l = 1:numel(levels)
    for r = unique(T.run(:))'
        for a = 1:numel(algorithms)
            idx = strcmp(T.level,levels{l}) & T.run==r ...
                & strcmp(T.algorithm,algorithms{a});
            S = T(idx,:);
            if isempty(S), continue; end
            applied = logical(S.eventApplied);
            item.level = levels{l};
            item.run = r;
            item.algorithm = algorithms{a};
            item.nEvents = height(S);
            item.nApplied = sum(applied);
            item.feasibleRate = mean(double(S.isFeasible));
            item.appliedFeasibleRate = NaN;
            if any(applied)
                item.appliedFeasibleRate = mean(double(S.isFeasible(applied)));
            end
            item.meanLate = mean(S.totalLate);
            item.meanDistance = mean(S.distance);
            item.meanResponseTime = mean(S.responseTime);
            item.meanFE = mean(S.functionEvaluations);
            runRows(end+1) = item; %#ok<AGROW>
        end
    end
end
runTable = struct2table(runRows);
summaryRows = repmat(struct('level','','algorithm','','nRuns',0, ...
    'appliedFeasibleMean',NaN,'appliedFeasibleStd',NaN, ...
    'lateMean',NaN,'lateStd',NaN,'responseMean',NaN, ...
    'responseStd',NaN),0,1);
for l = 1:numel(levels)
    for a = 1:numel(algorithms)
        S = runTable(strcmp(runTable.level,levels{l}) & ...
            strcmp(runTable.algorithm,algorithms{a}),:);
        if isempty(S), continue; end
        item = struct('level',levels{l},'algorithm',algorithms{a}, ...
            'nRuns',height(S),'appliedFeasibleMean',NaN, ...
            'appliedFeasibleStd',NaN,'lateMean',NaN,'lateStd',NaN, ...
            'responseMean',NaN,'responseStd',NaN);
        item.appliedFeasibleMean = mean(S.appliedFeasibleRate,'omitnan');
        item.appliedFeasibleStd = std(S.appliedFeasibleRate,'omitnan');
        item.lateMean = mean(S.meanLate,'omitnan');
        item.lateStd = std(S.meanLate,'omitnan');
        item.responseMean = mean(S.meanResponseTime,'omitnan');
        item.responseStd = std(S.meanResponseTime,'omitnan');
        summaryRows(end+1) = item; %#ok<AGROW>
    end
end
summaryTable = struct2table(summaryRows);
root = fileparts(mfilename('fullpath'));
outDir = fullfile(root,'results');
writetable(runTable,fullfile(outDir,[outputStem,'_runs.csv']));
writetable(summaryTable,fullfile(outDir,[outputStem,'_summary.csv']));
disp(summaryTable);
end
