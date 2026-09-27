function setup
%SETUP Add project source and experiment paths.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root,'src'));
addpath(fullfile(root,'experiments'));
end
