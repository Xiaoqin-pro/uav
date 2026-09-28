function RunV2PipelineDryRun
%RUNV2PIPELINEDRYRUN Run the v2 pipeline-only manifest.
root = fileparts(mfilename('fullpath'));
o = PaperExperimentConfig;
o.algorithms = {'PSO','Warm-PSO','Warm-ALNS','EAT-PSO', ...
    'EAT-NoReconstruction','EAT-NoInsertion'};
o.outputStem = 'paper_v2_pipeline_dryrun';
RunManifestBenchmark(fullfile(root,'data','pipeline_dryrun_v2_seeds.csv'),o);
end
