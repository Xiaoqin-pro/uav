function orders = CreateOrders(env,cfg)
%CREATEORDERS Create initial and future order records.
if nargin < 2, cfg = struct(); end
if ~isfield(cfg,'nInitialOrders'), cfg.nInitialOrders = 20; end
if ~isfield(cfg,'nFutureOrders'), cfg.nFutureOrders = 8; end
if ~isfield(cfg,'orderSeed'), cfg.orderSeed = 20260928; end
if ~isfield(cfg,'orderMargin'), cfg.orderMargin = 18; end
if ~isfield(cfg,'level'), cfg.level = 'mild'; end
level = lower(char(cfg.level));
switch level
    case 'mild'
        windowLength = 320; readyStep = 3;
    case 'moderate'
        windowLength = 240; readyStep = 5;
    case 'severe'
        windowLength = 170; readyStep = 7;
    otherwise
        error('Unknown scenario level: %s',cfg.level);
end

if isfield(cfg,'windowLengthOverride') && ~isempty(cfg.windowLengthOverride)
    windowLength = cfg.windowLengthOverride;
end
if ~isfield(cfg,'releaseStart'), cfg.releaseStart = 180; end
if ~isfield(cfg,'releaseInterval'), cfg.releaseInterval = 40; end
assert(windowLength>0 && cfg.releaseStart>=0 && cfg.releaseInterval>0);
oldRng = rng;
rng(cfg.orderSeed,'twister');
N = cfg.nInitialOrders + cfg.nFutureOrders;
xy = [env.depotXY; ...
      110+780*rand(N,1), 80+640*rand(N,1)];
xy = xy(2:end,:);
groundZ = interp2(env.X,env.Y,env.terrainZ,xy(:,1),xy(:,2),'linear');
xyz = [xy, repmat(env.flightAltitude,N,1)];

% Windows are generated in two difficulty bands. The initial set is
% intentionally moderate; the experiment scripts will create stress cases.
release = zeros(N,1);
release(cfg.nInitialOrders+1:end) = cfg.releaseStart ...
    + cfg.releaseInterval*(0:cfg.nFutureOrders-1);
ready = 15 + readyStep*(0:N-1)';
ready(cfg.nInitialOrders+1:end) = release(cfg.nInitialOrders+1:end) + 10;
due = ready + windowLength;
service = 8 + 4*mod((0:N-1)',4);
priority = 1 + mod((0:N-1)',3);

orders = repmat(struct('id',0,'xy',[0 0],'xyz',[0 0 0], ...
    'groundZ',0,'releaseTime',0,'readyTime',0,'dueTime',0, ...
    'serviceTime',0,'priority',0,'status','future'),N,1);
for i = 1:N
    orders(i).id = i;
    orders(i).xy = xy(i,:);
    orders(i).xyz = xyz(i,:);
    orders(i).groundZ = groundZ(i);
    orders(i).releaseTime = release(i);
    orders(i).readyTime = ready(i);
    orders(i).dueTime = due(i);
    orders(i).serviceTime = service(i);
    orders(i).priority = priority(i);
    if i <= cfg.nInitialOrders
        orders(i).status = 'active';
    end
end
rng(oldRng);
end
