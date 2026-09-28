function RunV2HoldoutBenchmark
%RUNV2HOLDOUTBENCHMARK Thin paper-v2 holdout wrapper.
root = fileparts(mfilename('fullpath'));
o = PaperExperimentConfig;
o.outputStem = 'paper_v2_holdout';
RunManifestBenchmark(fullfile(root,'data','paper_v2_holdout_seeds.csv'),o);
end
