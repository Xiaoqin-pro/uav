function cmp = CompareRouteDetails(candidateCost,candidateDetail,bestCost,bestDetail)
%COMPAREROUTEDETAILS Feasibility-first route comparison.
%   The scalar cost is retained for plotting, but solution selection uses:
%   safety violation -> total lateness -> route quality.
if nargin < 4 || isempty(bestDetail)
    cmp = true;
    return;
end
if isempty(candidateDetail)
    cmp = false;
    return;
end
ca = ComparisonVector(candidateCost,candidateDetail);
cb = ComparisonVector(bestCost,bestDetail);
for k = 1:numel(ca)
    if ca(k) < cb(k)-1e-10
        cmp = true;
        return;
    elseif ca(k) > cb(k)+1e-10
        cmp = false;
        return;
    end
end
cmp = false;
end

function v = ComparisonVector(cost,detail)
if isfield(detail,'comparisonVector') && ~isempty(detail.comparisonVector)
    v = detail.comparisonVector(:)';
else
    v = [detail.totalViolation,detail.totalLate,cost];
end
end
