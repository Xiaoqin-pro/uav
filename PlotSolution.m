function PlotSolution(model,state,solution,filePath)
%PLOTSOLUTION Teacher-style plotting entry point.
if nargin < 4, filePath = ''; end
PlotScenario(model,state,solution,filePath);
end
