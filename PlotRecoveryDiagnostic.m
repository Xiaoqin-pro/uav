function [runTable,summaryTable] = PlotRecoveryDiagnostic(csvPath,outputStem)
%PLOTRECOVERYDIAGNOSTIC Descriptive post-event feasibility vs FE.
%   First average applied events within each run, then summarize runs.
%   This is a diagnostic plot, not an independent-event significance test.
if nargin < 2 || isempty(outputStem), outputStem = 'recovery_diagnostic'; end
T = readtable(csvPath);
T = T(logical(T.eventApplied) & strcmp(T.eventType,'add'),:);
if isempty(T), error('No applied add events are available.'); end
levels = unique(T.level,'stable');
algorithms = unique(T.algorithm,'stable');
feValues = unique(T.FE)';
runRows = repmat(struct('level','','run',0,'algorithm','', ...
    'FE',0,'nAppliedEvents',0,'feasibleRate',NaN, ...
    'meanLate',NaN),0,1);
for l = 1:numel(levels)
    for r = unique(T.run(:))'
        for a = 1:numel(algorithms)
            for fe = feValues
                idx = strcmp(T.level,levels{l}) & T.run==r & ...
                    strcmp(T.algorithm,algorithms{a}) & T.FE==fe;
                S = T(idx,:);
                if isempty(S), continue; end
                item = struct('level',levels{l},'run',r, ...
                    'algorithm',algorithms{a},'FE',fe, ...
                    'nAppliedEvents',height(S), ...
                    'feasibleRate',mean(double(S.isFeasible)), ...
                    'meanLate',mean(S.totalLate));
                runRows(end+1) = item; %#ok<AGROW>
            end
        end
    end
end
runTable = struct2table(runRows);
summaryRows = repmat(struct('level','','algorithm','','FE',0, ...
    'nRuns',0,'feasibleMean',NaN,'feasibleStd',NaN, ...
    'lateMean',NaN,'lateStd',NaN),0,1);
for l = 1:numel(levels)
    for a = 1:numel(algorithms)
        for fe = feValues
            idx = strcmp(runTable.level,levels{l}) & ...
                strcmp(runTable.algorithm,algorithms{a}) & runTable.FE==fe;
            S = runTable(idx,:);
            if isempty(S), continue; end
            item = struct('level',levels{l},'algorithm',algorithms{a}, ...
                'FE',fe,'nRuns',height(S), ...
                'feasibleMean',mean(S.feasibleRate), ...
                'feasibleStd',std(S.feasibleRate), ...
                'lateMean',mean(S.meanLate), ...
                'lateStd',std(S.meanLate));
            summaryRows(end+1) = item; %#ok<AGROW>
        end
    end
end
summaryTable = struct2table(summaryRows);
outDir = fullfile(fileparts(mfilename('fullpath')),'results');
writetable(runTable,fullfile(outDir,[outputStem,'_runs.csv']));
writetable(summaryTable,fullfile(outDir,[outputStem,'_summary.csv']));
for l = 1:numel(levels)
    fig = figure('Color','w','Visible','off'); hold on;
    for a = 1:numel(algorithms)
        idx = strcmp(summaryTable.level,levels{l}) & ...
            strcmp(summaryTable.algorithm,algorithms{a});
        S = sortrows(summaryTable(idx,:),'FE');
        plot(S.FE,S.feasibleMean,'LineWidth',1.5,'DisplayName',algorithms{a});
    end
    xlabel('Full route evaluations after event');
    ylabel('Mean run-level add-event feasible fraction');
    ylim([0 1]); grid on;
    title(sprintf('%s: exploratory recovery (not paper evidence)',levels{l}));
    legend('Location','best');
    exportgraphics(fig,fullfile(outDir, ...
        sprintf('%s_%s.png',outputStem,levels{l})),'Resolution',150);
    close(fig);
end
end
