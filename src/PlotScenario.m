function PlotScenario(scenario,state,solution,filePath)
%PLOTSCENARIO Plot terrain, obstacles, route and order state.
env = scenario.env;
figure('Color','w','Visible','off');
surf(env.X,env.Y,env.terrainZ,'EdgeColor','none','FaceAlpha',0.85);
colormap(turbo); hold on; axis tight; grid on; view(3);
for k = 1:env.nObstacles
    o = env.obstacles(k);
    DrawBox(o,[0.55 0.15 0.15]);
end
plot3(env.depot(1),env.depot(2),env.depot(3),'kp','MarkerSize',12, ...
    'MarkerFaceColor','y');
if nargin >= 3 && ~isempty(solution) && isfield(solution,'Detail')
    for k = 1:numel(solution.Detail.routeLegs)
        pts = solution.Detail.routeLegs{k}.points;
        plot3(pts(:,1),pts(:,2),pts(:,3),'b-','LineWidth',2);
    end
end
orders = scenario.orders;
active = state.activeOrderIDs;
for i = 1:numel(orders)
    p = orders(i).xyz;
    if ismember(orders(i).id,active)
        plot3(p(1),p(2),p(3),'ko','MarkerFaceColor',[0.2 0.8 0.9]);
        text(p(1),p(2),p(3)+12,sprintf('O%d',orders(i).id),'FontSize',8);
    elseif strcmp(orders(i).status,'cancelled')
        plot3(p(1),p(2),p(3),'rx','MarkerSize',8,'LineWidth',1.2);
    end
end
xlabel('x'); ylabel('y'); zlabel('z');
title('Dynamic 3-D UAV order-routing smoke test');
if nargin >= 4 && ~isempty(filePath)
    exportgraphics(gcf,filePath,'Resolution',150);
end
close(gcf);
end

function DrawBox(o,color)
X = [o.xMin o.xMax]; Y = [o.yMin o.yMax]; Z = [o.zMin o.zMax];
faces = [1 2 4 3;5 6 8 7;1 2 6 5;3 4 8 7;1 3 7 5;2 4 8 6];
verts = [X(1) Y(1) Z(1); X(2) Y(1) Z(1); ...
    X(1) Y(2) Z(1); X(2) Y(2) Z(1); ...
    X(1) Y(1) Z(2); X(2) Y(1) Z(2); ...
    X(1) Y(2) Z(2); X(2) Y(2) Z(2)];
patch('Vertices',verts,'Faces',faces,'FaceColor',color, ...
    'FaceAlpha',0.45,'EdgeColor','none');
end
