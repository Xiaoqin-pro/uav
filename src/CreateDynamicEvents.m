function events = CreateDynamicEvents(orders,cfg)
%CREATEDYNAMICEVENTS Create deterministic add/cancel events.
if nargin < 2, cfg = struct(); end
if ~isfield(cfg,'eventSeed'), cfg.eventSeed = 20260929; end
if ~isfield(cfg,'nInitialOrders'), cfg.nInitialOrders = 20; end
if ~isfield(cfg,'nFutureOrders'), cfg.nFutureOrders = 8; end
if ~isfield(cfg,'level'), cfg.level = 'mild'; end

oldRng = rng;
rng(cfg.eventSeed,'twister');
level = lower(char(cfg.level));
futureIDs = (cfg.nInitialOrders+1):(cfg.nInitialOrders+cfg.nFutureOrders);
futureIDs = futureIDs(randperm(numel(futureIDs)));
initialIDs = 1:cfg.nInitialOrders;

switch level
    case 'mild'
        nAdd = 2; nCancel = 1;
    case 'moderate'
        nAdd = 4; nCancel = 2;
    case 'severe'
        nAdd = 6; nCancel = 3;
    otherwise
        error('Unknown scenario level: %s',cfg.level);
end
nAdd = min(nAdd,numel(futureIDs));
nCancel = min(nCancel,numel(initialIDs));
events = repmat(struct('time',0,'type','','orderIDs',[], ...
    'description',''),nAdd+nCancel,1);
for k = 1:nAdd
    events(k).time = orders(futureIDs(k)).releaseTime;
    events(k).type = 'add';
    events(k).orderIDs = futureIDs(k);
    events(k).description = sprintf('new order %d arrives',futureIDs(k));
end
% Cancellation events only reference currently possible initial orders.
for k = 1:nCancel
    events(nAdd+k).time = 220 + 120*(k-1);
    events(nAdd+k).type = 'cancel';
    events(nAdd+k).orderIDs = initialIDs(end-k+1);
    events(nAdd+k).description = sprintf('order %d cancelled',initialIDs(end-k+1));
end
[~,idx] = sort([events.time]);
events = events(idx);
rng(oldRng);
end



