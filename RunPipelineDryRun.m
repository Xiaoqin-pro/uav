function RunPipelineDryRun
%RUNPIPELINEDRYRUN Run the fixed 8-scenario pipeline manifest.
root = fileparts(mfilename('fullpath'));
o = PaperExperimentConfig;
o.outputStem = 'paper_v1_dryrun';
RunManifestBenchmark(fullfile(root,'data','pipeline_dryrun_v1_seeds.csv'),o);
end
