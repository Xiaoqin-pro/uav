function env = CreateEnvironment(cfg)
%CREATEENVIRONMENT Create a deterministic 3-D terrain and obstacle field.
%   The environment is static in the first development stage. Dynamic
%   changes are represented by order events, not by moving obstacles.

if nargin < 1, cfg = struct(); end
if ~isfield(cfg,'mapSize'), cfg.mapSize = [1000 800]; end
if ~isfield(cfg,'terrainSeed'), cfg.terrainSeed = 20260927; end
if ~isfield(cfg,'gridNx'), cfg.gridNx = 161; end
if ~isfield(cfg,'gridNy'), cfg.gridNy = 129; end
if ~isfield(cfg,'safetySamples'), cfg.safetySamples = 60; end

env.mapSize = cfg.mapSize;
env.x = linspace(0,env.mapSize(1),cfg.gridNx);
env.y = linspace(0,env.mapSize(2),cfg.gridNy);
[env.X,env.Y] = meshgrid(env.x,env.y);

oldRng = rng;
rng(cfg.terrainSeed,'twister');
noiseLarge = CreateRandomField(env.X,env.Y,9,8);
noiseMedium = CreateRandomField(env.X,env.Y,24,19);
noiseSmall = CreateRandomField(env.X,env.Y,48,37);

ridgeA = CurvedRidge(env.X,env.Y,250,420,0.30,55,170,150);
ridgeB = CurvedRidge(env.X,env.Y,680,560,-0.22,35,135,105);
ridgeC = CurvedRidge(env.X,env.Y,500,160,0.18,30,105,80);
ridgeTerm = (ridgeA+ridgeB+ridgeC).*(0.82+0.18*NormalizeField(noiseMedium));
peakTerm = MountainPeak(env.X,env.Y,145,185,120,95,80) ...
    + MountainPeak(env.X,env.Y,300,570,175,115,95) ...
    + MountainPeak(env.X,env.Y,485,365,150,100,120) ...
    + MountainPeak(env.X,env.Y,650,690,125,105,75) ...
    + MountainPeak(env.X,env.Y,785,360,190,120,105) ...
    + MountainPeak(env.X,env.Y,900,630,110,85,90);
valleyTerm = CurvedValley(env.X,env.Y,50,355,0.28,42,72) ...
    + CurvedValley(env.X,env.Y,120,690,-0.18,35,58) ...
    + CurvedValley(env.X,env.Y,420,120,0.50,24,42);

env.terrainZ = 45 + 42*noiseLarge + 16*noiseMedium + 5*noiseSmall ...
    + ridgeTerm + peakTerm - valleyTerm;
env.terrainZ = ErosionRelaxation(env.terrainZ,10,0.10);
env.terrainZ = env.terrainZ - min(env.terrainZ(:));
env.terrainZ = 25 + 280*env.terrainZ/max(env.terrainZ(:));
rng(oldRng);

env.depotXY = [80 400];
env.cruiseHeight = 70;
env.flightAltitude = max(env.terrainZ(:)) + env.cruiseHeight;
env.depotGroundZ = interp2(env.X,env.Y,env.terrainZ, ...
    env.depotXY(1),env.depotXY(2),'linear');
env.depot = [env.depotXY,env.flightAltitude];

gaps = [330 410 130 110 125; ...
        570 575 150 120 145; ...
        760 270 135 150 120; ...
        475 175 105 120 155];
env.obstacles = repmat(struct('xMin',0,'xMax',0,'yMin',0, ...
    'yMax',0,'zMin',0,'zMax',0),size(gaps,1),1);
for k = 1:size(gaps,1)
    cx = gaps(k,1); cy = gaps(k,2);
    width = gaps(k,3); depth = gaps(k,4); height = gaps(k,5);
    ground = interp2(env.X,env.Y,env.terrainZ,cx,cy,'linear');
    env.obstacles(k).xMin = cx-width/2;
    env.obstacles(k).xMax = cx+width/2;
    env.obstacles(k).yMin = cy-depth/2;
    env.obstacles(k).yMax = cy+depth/2;
    env.obstacles(k).zMin = ground;
    env.obstacles(k).zMax = ground+height;
end
env.nObstacles = numel(env.obstacles);
env.obstacleSafety = 8;
env.minClearance = 40;
env.safetySamples = cfg.safetySamples;
env.speed = 25;
env.smoothPenalty = 1.5;
end

function field = CreateRandomField(X,Y,nx,ny)
x0 = linspace(min(X(:)),max(X(:)),nx);
y0 = linspace(min(Y(:)),max(Y(:)),ny);
field = interp2(x0,y0,randn(ny,nx),X,Y,'spline');
field = NormalizeField(field);
end

function field = NormalizeField(field)
field = field - mean(field(:));
field = field/(std(field(:))+eps);
end

function ridge = CurvedRidge(X,Y,cx,cy,slope,width,height,xWidth)
centerLine = cy+slope*(X-cx)+35*sin((X-cx)/120);
ridge = height*exp(-(Y-centerLine).^2/(2*width^2));
ridge = ridge.*exp(-(X-cx).^2/(2*xWidth^2));
end

function valley = CurvedValley(X,Y,cx,cy,slope,width,depth)
centerLine = cy+slope*(X-cx)+28*sin((X-cx)/145);
valley = depth*exp(-(Y-centerLine).^2/(2*width^2));
valley = valley.*exp(-(X-(cx+420)).^2/(2*500^2));
end

function peak = MountainPeak(X,Y,cx,cy,height,sigmaX,sigmaY)
peak = height*exp(-((X-cx).^2/(2*sigmaX^2) ...
    +(Y-cy).^2/(2*sigmaY^2)));
end

function Z = ErosionRelaxation(Z,nIterations,alpha)
kernel = ones(3,3)/9;
for k = 1:nIterations
    smoothZ = conv2(Z,kernel,'same');
    localRelief = abs(Z-smoothZ);
    threshold = prctile(localRelief(:),70);
    mask = localRelief>threshold;
    Z(mask) = (1-alpha)*Z(mask)+alpha*smoothZ(mask);
end
end

