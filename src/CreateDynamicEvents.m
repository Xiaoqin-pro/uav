function events = CreateDynamicEvents(orders,cfg)
%CREATEDYNAMICEVENTS Create deterministic add/cancel events.
if nargin < 2, cfg = struct(); end
if ~isfield(cfg,'eventSeed'), cfg.eventSeed = 20260929; end
if ~isfield(cfg,'nInitialOrders'), cfg.nInitialOrders = 20; end
if ~isfield(cfg,'nFutureOrders'), cfg.nFutureOrders = 8; end

oldRng = rng;
rng(cfg.eventSeed,'twister');
futureIDs = (cfg.nInitialOrders+1):(cfg.nInitialOrders+cfg.nFutureOrders);
futureIDs = futureIDs(randperm(numel(futureIDs)));
initialIDs = 1:cfg.nInitialOrders;

n = min(4,numel(futureIDs));
events = repmat(struct('time',0,'type','','orderIDs',[], ...
    'description',''),n+2,1);
for k = 1:n
    events(k).time = orders(futureIDs(k)).releaseTime;
    events(k).type = 'add';
    events(k).orderIDs = futureIDs(k);
    events(k).description = sprintf('new order %d arrives',futureIDs(k));
end
% Cancellation events only reference currently possible initial orders.
for k = 1:2
    events(n+k).time = 220 + 120*(k-1);
    events(n+k).type = 'cancel';
    events(n+k).orderIDs = initialIDs(end-k+1);
    events(n+k).description = sprintf('order %d cancelled',initialIDs(end-k+1));
end
[~,idx] = sort([events.time]);
events = events(idx);
rng(oldRng);
end

