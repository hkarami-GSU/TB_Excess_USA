clc; clear; close all;

codeDir = fileparts(mfilename('fullpath')); if ~isempty(codeDir), addpath(codeDir); end
P = project_paths();
file_path = fullfile(P.tb_states, 'Rates_Wide.xlsx');
opts = detectImportOptions(file_path);
T = readtable(file_path, opts);
state_names = T.Properties.VariableNames(2:end);
state_names = state_names';

years = T.(1);
idx_2020_2023 = find(years >= 2020 & years <= 2023);

rates_2020_2023 = table2array(T(idx_2020_2023, 2:end));
avg_rates = mean(rates_2020_2023, 1)';

output_table = table(state_names, avg_rates, 'VariableNames', {'State', 'Average_Observed_Rate_2020_2023'});

output_file = fullfile(P.res, 'observed_rates_2020_2023.csv');
writetable(output_table, output_file);

fprintf('Data exported to: %s\n', output_file);

fprintf('Number of states: %d\n', length(state_names));

disp(output_table);
