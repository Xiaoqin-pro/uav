function summary = PlotPaperRecovery(recoveryCsvPath,outputStem)
%PLOTPAPERRECOVERY Plot run-level add-event recovery curves by FE.
if nargin < 2 || isempty(outputStem), outputStem = 'paper_recovery'; end
T = readtable(recoveryCsvPath,'TextType','string');
T = T(strcmp(T.eventType,'add') & logical(T.eventApplied),:);
assert(~isempty(T),'No applied add-event recovery rows.');
algorithms = unique(T.algorithm,'stable');
scenarioIds = unique(T.scenarioId,'stable');
FE = unique(T.FE)';
rows = repmat(struct('algorithm','','FE',0,'nScenarios',0, ...
    'recoveredMean',NaN,'recoveredStd',NaN,'meanLateness',NaN),0,1);
for a = 1:numel(algorithms)
    for fe = FE
        scenarioRate = zeros(numel(scenarioIds),1);
        scenarioLate = zeros(numel(scenarioIds),1);
        for s = 1:numel(scenarioIds)
            Q = T(strcmp(T.algorithm,algorithms{a}) & ...
                T.FE==fe & strcmp(T.scenarioId,scenarioIds{s}),:);
            scenarioRate(s) = mean(double(Q.isFeasible));
            scenarioLate(s) = mean(Q.totalLate);
        end
        rows(end+1) = struct('algorithm',algorithms{a},'FE',fe, ...
            'nScenarios',numel(scenarioIds), ...
            'recoveredMean',mean(scenarioRate), ...
            'recoveredStd',std(scenarioRate), ...
            'meanLateness',mean(scenarioLate)); %#ok<AGROW>
    end
end
summary = struct2table(rows);
outDir = fullfile(fileparts(mfilename('fullpath')),'results');
writetable(summary,fullfile(outDir,[outputStem,'.csv']));
fig = figure('Color','w','Visible','off'); hold on;
for a = 1:numel(algorithms)
    Q = summary(strcmp(summary.algorithm,algorithms{a}),:);
    Q = sortrows(Q,'FE');
    errorbar(Q.FE,Q.recoveredMean,Q.recoveredStd,'-o','LineWidth',1.2, ...
        'DisplayName',algorithms{a});
end
grid on; ylim([0 1]); xlabel('Function evaluations after add event');
ylabel('Run-level fraction of add events recovered');
title('Post-event feasibility recovery (paper-v1 diagnostic)');
legend('Location','best');
exportgraphics(fig,fullfile(outDir,[outputStem,'.png']),'Resolution',180);
close(fig);
end
