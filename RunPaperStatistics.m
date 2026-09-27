function [statsTable,holmTable] = RunPaperStatistics(runCsvPath,outputStem)
%RUNPAPERSTATISTICS Frozen paired run-level comparisons for paper v1.
if nargin < 1 || isempty(runCsvPath), error('runCsvPath is required'); end
if nargin < 2 || isempty(outputStem), outputStem = 'paper_statistics'; end
R = readtable(runCsvPath,'TextType','string');
algorithms = unique(R.algorithm,'stable');
assert(ismember('EAT-PSO',algorithms),'EAT-PSO is required.');
baselines = setdiff(algorithms,'EAT-PSO','stable');
metrics = {'addFeasibleRate','addMeanCappedFirstFE','addMeanLate','addMeanResponse'};
directions = {'higher','lower','lower','lower'};
rows = repmat(struct('level','','metric','','baseline','','nPairs',0, ...
    'direction','','eatMean',NaN,'baselineMean',NaN,'meanDifference',NaN, ...
    'medianDifference',NaN,'pRaw',NaN,'pHolm',NaN),0,1);
for m = 1:numel(metrics)
    metric = metrics{m};
    for b = 1:numel(baselines)
        levels = unique(R.level,'stable');
        for l = 1:numel(levels)
            E = R(strcmp(R.level,levels{l}) & strcmp(R.algorithm,'EAT-PSO'),:);
            B = R(strcmp(R.level,levels{l}) & strcmp(R.algorithm,baselines{b}),:);
            [keysE,ia] = unique(E(:,{'run'}),'stable'); %#ok<ASGLU>
            [keysB,ib] = unique(B(:,{'run'}),'stable'); %#ok<ASGLU>
            common = intersect(E.run,B.run);
            if isempty(common), continue; end
            e = zeros(numel(common),1); q = e;
            for k = 1:numel(common)
                e(k) = E{find(E.run==common(k),1),metric};
                q(k) = B{find(B.run==common(k),1),metric};
            end
            d = e-q;
            try
                p = signrank(d,0,'method','approximate');
            catch
                p = signrank(d,0);
            end
            item = struct('level',levels{l},'metric',metric, ...
                'baseline',baselines{b},'nPairs',numel(d), ...
                'direction',directions{m},'eatMean',mean(e), ...
                'baselineMean',mean(q),'meanDifference',mean(d), ...
                'medianDifference',median(d),'pRaw',p,'pHolm',NaN);
            rows(end+1) = item; %#ok<AGROW>
        end
    end
end
statsTable = struct2table(rows);
holmTable = statsTable;
for l = unique(statsTable.level)'
    for m = unique(statsTable.metric)'
        idx = strcmp(statsTable.level,l{1}) & strcmp(statsTable.metric,m{1});
        p = statsTable.pRaw(idx); [sp,ord] = sort(p); adj = zeros(size(p));
        for k = 1:numel(sp), adj(ord(k)) = min(1,(numel(sp)-k+1)*sp(k)); end
        % enforce monotonic Holm adjustment
        for k = 2:numel(adj(ord)), adj(ord(k)) = max(adj(ord(k-1)),adj(ord(k))); end
        holmTable.pHolm(idx) = adj;
    end
end
outDir = fullfile(fileparts(mfilename('fullpath')),'results');
writetable(holmTable,fullfile(outDir,[outputStem,'.csv']));
save(fullfile(outDir,[outputStem,'.mat']),'statsTable','holmTable');
disp(holmTable);
end
