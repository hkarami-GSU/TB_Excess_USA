codeDir = fileparts(mfilename('fullpath'));
addpath(codeDir);
P = project_paths();


steps = {
'excess_states_cases'
'excess_states_rates'
'excess_age'
'excess_race'
'excess_rates_age_race'
'logratio_states_rates'
'fits_states_cases'
'fits_age'
'fits_race'
'regression_excess_rates'
'regression_excess_cases'
'regression_logratio_rates'
'observed_rates_for_map'
};

logFile = fullfile(P.res, 'run_all_log.txt');
if exist(logFile, 'file'), delete(logFile); end
diary(logFile);
failed = {};
for k = 1:numel(steps)
fprintf('\n=== [%d/%d] %s ===\n', k, numel(steps), steps{k});
try
runStep(fullfile(codeDir, [steps{k} '.m']));
catch ME
fprintf(2, 'FAILED: %s\n  %s\n', steps{k}, ME.message);
failed{end+1} = steps{k};
end
close all;
end

if isempty(failed)
fprintf('\nAll %d steps finished. Results: %s\n', numel(steps), P.res);
else
fprintf(2, '\n%d step(s) failed: %s\n', numel(failed), strjoin(failed, ', '));
end
diary('off');

function runStep(scriptFile)
run(scriptFile);
end
