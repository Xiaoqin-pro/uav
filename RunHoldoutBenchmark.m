function RunHoldoutBenchmark
%RUNHOLDOUTBENCHMARK Thin wrapper; do not call before paper-v1 freeze.
root = fileparts(mfilename('fullpath'));
o = PaperExperimentConfig;
o.outputStem = 'paper_v1_holdout';
RunManifestBenchmark(fullfile(root,'data','reserved_holdout_seeds.csv'),o);
end
