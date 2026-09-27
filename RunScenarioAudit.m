function RunScenarioAudit
%RUNSCENARIOAUDIT Generate a compact audit table for difficulty levels.
root = fileparts(mfilename('fullpath'));
setup;
levels = {'mild','moderate','severe'};
rows = repmat(struct('level','','nOrders',0,'nInitialActive',0, ...
    'nEvents',0,'nAdd',0,'nCancel',0,'minWindow',0,'maxWindow',0, ...
    'valid',false),numel(levels),1);
for k = 1:numel(levels)
    cfg.nInitialOrders = 8;
    cfg.nFutureOrders = 6;
    cfg.level = levels{k};
    cfg.terrainSeed = 20260927;
    cfg.orderSeed = 20260928;
    cfg.eventSeed = 20260929;
    cfg.safetySamples = 15;
    model = CreateModel(cfg);
    report = ValidateScenario(model);
    windows = [model.orders.dueTime]-[model.orders.readyTime];
    types = {model.events.type};
    rows(k).level = levels{k};
    rows(k).nOrders = report.nOrders;
    rows(k).nInitialActive = report.nInitialActive;
    rows(k).nEvents = report.nEvents;
    rows(k).nAdd = sum(strcmp(types,'add'));
    rows(k).nCancel = sum(strcmp(types,'cancel'));
    rows(k).minWindow = min(windows);
    rows(k).maxWindow = max(windows);
    rows(k).valid = report.ok;
end
T = struct2table(rows);
outDir = fullfile(root,'results');
if ~exist(outDir,'dir'), mkdir(outDir); end
writetable(T,fullfile(outDir,'scenario_audit.csv'));
disp(T);
end
