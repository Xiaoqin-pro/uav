function RunBlindWindowScreen(options)
%RUNBLINDWINDOWSCREEN Predeclared baseline-only multi-seed window screen.
%   Never calls EAT-PSO. A passing four-seed result is only a candidate for
%   independent confirmation, not a frozen dataset or publication evidence.
if nargin < 1, options = struct(); end
if ~isfield(options,'windows'), options.windows = [135 155 175]; end
if ~isfield(options,'nRuns'), options.nRuns = 4; end
if ~isfield(options,'outputPrefix'), options.outputPrefix = 'blind_window'; end
if ~isfield(options,'nInitialOrders'), options.nInitialOrders = 8; end
if ~isfield(options,'nFutureOrders'), options.nFutureOrders = 6; end
if ~isfield(options,'safetySamples'), options.safetySamples = 8; end
if ~isfield(options,'Particle_Number'), options.Particle_Number = 6; end
if ~isfield(options,'maxgen'), options.maxgen = 3; end
if ~isfield(options,'releaseStart'), options.releaseStart = 45; end
if ~isfield(options,'releaseInterval'), options.releaseInterval = 15; end
if ~isfield(options,'baseTerrainSeed'), options.baseTerrainSeed = 20267000; end
if ~isfield(options,'baseOrderSeed'), options.baseOrderSeed = 20268000; end
if ~isfield(options,'baseEventSeed'), options.baseEventSeed = 20269000; end
if ~isfield(options,'baseAlgorithmSeed'), options.baseAlgorithmSeed = 20270000; end

rows = table();
for w = options.windows
    cfg = options;
    cfg.levels = {'severe'};
    cfg.windowLengthOverride = w;
    cfg.outputStem = sprintf('%s_w%d',options.outputPrefix,w);
    RunDifficultyCalibration(cfg);
    path = fullfile(fileparts(mfilename('fullpath')),'results', ...
        [cfg.outputStem,'.csv']);
    T = readtable(path);
    entry = table(w,height(T)/2,all(T.referenceFeasible), ...
        all(T.initialFeasible),mean(T.addAppliedRate,'omitnan'), ...
        mean(T.cancelAppliedRate,'omitnan'), ...
        mean(T.appliedEventFeasibleRate,'omitnan'), ...
        mean(T.meanLate,'omitnan'), ...
        'VariableNames',{'windowLength','nSeedTriples', ...
        'allReferenceFeasible','allInitialFeasible','meanAddApplied', ...
        'meanCancelApplied','pooledRunMeanAppliedFeasible','pooledRunMeanLate'});
    entry.meetsPilotRule = entry.allReferenceFeasible && ...
        entry.allInitialFeasible && entry.meanAddApplied==1 && ...
        entry.meanCancelApplied>=0.5 && ...
        entry.pooledRunMeanAppliedFeasible>=0.15 && ...
        entry.pooledRunMeanAppliedFeasible<=0.85;
    rows = [rows;entry]; %#ok<AGROW>
end
outDir = fullfile(fileparts(mfilename('fullpath')),'results');
writetable(rows,fullfile(outDir,[options.outputPrefix,'_screen.csv']));
save(fullfile(outDir,[options.outputPrefix,'_screen.mat']),'rows','options');
disp(rows);
end
