codeDir = fileparts(mfilename('fullpath')); if ~isempty(codeDir), addpath(codeDir); end
P = project_paths();

outDir = P.res;
filename = fullfile(P.tb_states, 'data_states.xlsx');
data = readtable(filename);
data = data(~cellfun(@isempty, data.State), :);

years = unique(data.Year);

years = years(~isnan(years));
states = unique(data.State);

cases_matrix = NaN(length(years), length(states));
rate_matrix = NaN(length(years), length(states));

for i = 1:length(states)
state = states{i};
idx = strcmp(data.State, state);
for j = 1:length(years)

year = years(j);
year_idx = idx & (data.Year == year);
if any(year_idx)
cases_matrix(j,i) = data.Cases(year_idx);
rate_matrix(j,i) = data.('Rate')(year_idx);
end
end

end


for i = 1:length(states)
missing_idx = isnan(rate_matrix(:, i));
if any(missing_idx)
rate_matrix(:, i) = fillmissing(rate_matrix(:, i), 'linear', ...
'SamplePoints', years, 'EndValues', 'nearest');
end
end


cases_table = array2table(cases_matrix, 'VariableNames', states);
cases_table = addvars(cases_table, years, 'Before', 1);


rate_table = array2table(rate_matrix, 'VariableNames', states);
rate_table = addvars(rate_table, years, 'Before', 1);

writetable(cases_table, fullfile(outDir, 'Cases_Wide_states.xlsx'));

writetable(rate_table, fullfile(outDir, 'Rates_Wide_states.xlsx'));
disp('Wide tables for cases and rates have been saved.');
