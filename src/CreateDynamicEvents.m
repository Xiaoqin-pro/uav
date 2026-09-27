function events = CreateDynamicEvents(orders,cfg)
%CREATEDYNAMICEVENTS Create reproducible event candidates.
%   Add events coincide with their order release times. Cancellation
%   candidates are selected from initial IDs, never from future orders.
if nargin < 2, cfg = struct(); end
if ~isfield(cfg,'eventSeed'), cfg.eventSeed = 20260929; end
if ~isfield(cfg,'nInitialOrders'), cfg.nInitialOrders = 20; end
if ~isfield(cfg,'nFutureOrders'), cfg.nFutureOrders = 8; end
if ~isfield(cfg,'level'), cfg.level = 'mild'; end
oldRng = rng;
rng(cfg.eventSeed,'twister');
futureIDs = (cfg.nInitialOrders+1):(cfg.nInitialOrders+cfg.nFutureOrders);
initialIDs = randperm(cfg.nInitialOrders);
switch lower(char(cfg.level))
    case 'mild', nAdd = 2; nCancel = 1;
    case 'moderate', nAdd = 4; nCancel = 2;
    case 'severe', nAdd = 6; nCancel = 3;
    otherwise, error('Unknown scenario level: %s',cfg.level);
end
nAdd = min(nAdd,numel(futureIDs));
nCancel = min(nCancel,numel(initialIDs));
events = repmat(struct('time',0,'type','','orderIDs',[], ...
    'description',''),nAdd+nCancel,1);
for k = 1:nAdd
    id = futureIDs(k);
    events(k).time = orders(id).releaseTime;
    events(k).type = 'add';
    events(k).orderIDs = id;
    events(k).description = sprintf('new order %d arrives',id);
end
% Early cancellation requests increase the chance that orders are pending,
% but the simulator still records a rejected request when already served.
for k = 1:nCancel
    id = initialIDs(k);
    events(nAdd+k).time = 20+40*(k-1);
    events(nAdd+k).type = 'cancel';
    events(nAdd+k).orderIDs = id;
    events(nAdd+k).description = sprintf('order %d cancellation requested',id);
end
[~,idx] = sort([events.time]);
events = events(idx);
rng(oldRng);
end
