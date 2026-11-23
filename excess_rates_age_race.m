clc;
clear;
close all;
codeDir = fileparts(mfilename('fullpath')); if ~isempty(codeDir), addpath(codeDir); end
P = project_paths();

years = 2020:2023;
rows  = 11:14;

popAge  = readtable(fullfile(P.pop, 'nc-est2023-agesex-res_both_sexes.csv'));
popAge  = popAge(popAge.AGE ~= 999, :);
popRace = readtable(fullfile(P.pop, 'nc-est2023-alldata-r_July1_allages_by_race_hispanic.csv'));


ageDef = {'< 1', 0, 0;  '1-4', 1, 4;  '5-14', 5, 14;  '15-24', 15, 24; ...
'25-34', 25, 34;  '35-44', 35, 44;  '45-54', 45, 54; ...
'55-64', 55, 64;  '65-74', 65, 74;  '75-84', 75, 84;  '85+', 85, 100};

ageNames = readHeader(fullfile(P.tb_age, 'Cases_Wide.xlsx'));


popA = zeros(size(ageDef, 1), numel(years));
for k = 1:size(ageDef, 1)
in = popAge.AGE >= ageDef{k, 2} & popAge.AGE <= ageDef{k, 3};
for j = 1:numel(years)
col = popAge.(sprintf('POPESTIMATE%d', years(j)));

popA(k, j) = sum(col(in));
end
end
Tage = excessTable(P.out_age, ageNames, ageDef(:, 1), popA, years, rows);
writetable(Tage, fullfile(P.res, 'ExcessRates_US_Age.csv'));

raceDef = {'AI/AN', 'NHIA';  'Asian', 'NHAA';  'Black', 'NHBA';  'Hispanic', 'H'; ...
'Multirace', 'NHTOM';  'NH/PI', 'NHNA';  'White', 'NHWA'};
raceNames = readHeader(fullfile(P.tb_race, 'Cases_race_all.xlsx'));

popR = zeros(size(raceDef, 1), numel(years));

for k = 1:size(raceDef, 1)
for j = 1:numel(years)
r = popRace.YEAR == years(j) & popRace.MONTH == 7 & popRace.AGE == 999;
popR(k, j) = popRace.([raceDef{k, 2} '_MALE'])(r) + popRace.([raceDef{k, 2} '_FEMALE'])(r);
end
end
Trace = excessTable(P.out_race, raceNames, raceDef(:, 1), popR, years, rows);
writetable(Trace, fullfile(P.res, 'ExcessRates_US_Race.csv'));
show = {'group', 'method', 'excess_total', 'excess_total_lower', 'excess_total_upper', ...
'rate_total', 'rate_total_lower', 'rate_total_upper'};
disp('Excess TB cases and excess per 100,000, 2020-2023, by age group:');

disp(Tage(:, show));
disp('Excess TB cases and excess per 100,000, 2020-2023, by race/ethnicity:');
disp(Trace(:, show));
function names = readHeader(xlsxFile)
T = readtable(xlsxFile, 'VariableNamingRule', 'preserve');
names = strtrim(T.Properties.VariableNames(2:end));
end

function T = excessTable(outDir, names, groups, pop, years, rows)
primary  = 'ranked(1)-onsetfixed-0-flag1-1-method-1-dist-1-horizon-4-yearly-tuberculosis-cases-USA-area-%d-01-01-2019.csv';
fallback = 'ranked(1)-onsetfixed-0-flag1-1-method-0-dist-0-horizon-4-yearly-tuberculosis-cases-USA-area-%d-01-01-2019.csv';
nG = numel(groups);
nY = numel(years);
method = zeros(nG, 1);
E = zeros(nG, nY, 3);
R = zeros(nG, nY, 3);
for k = 1:nG
area = find(strcmp(names, groups{k}));
if numel(area) ~= 1
error('Group "%s" not found among the column names.', groups{k});

end

f1 = fullfile(outDir, sprintf(primary, area));
f0 = fullfile(outDir, sprintf(fallback, area));
if exist(f1, 'file')
f = f1; method(k) = 1;
elseif exist(f0, 'file')
f = f0; method(k) = 0;
else

error('No model output for group "%s" (area %d).', groups{k}, area);
end
d = readmatrix(f);
for j = 1:nY
obs = d(rows(j), 2);
e = [max(0, obs - d(rows(j), 3)), max(0, obs - d(rows(j), 5)), max(0, obs - d(rows(j), 4))];
E(k, j, :) = reshape(e, 1, 1, 3);
R(k, j, :) = reshape(e / pop(k, j) * 1e5, 1, 1, 3);
end
end
T = table(string(groups(:)), method, 'VariableNames', {'group', 'method'});
for j = 1:nY
y = years(j);
T.(sprintf('pop_%d', y))          = pop(:, j);
T.(sprintf('excess_%d', y))       = E(:, j, 1);
T.(sprintf('excess_%d_lower', y)) = E(:, j, 2);
T.(sprintf('excess_%d_upper', y)) = E(:, j, 3);
T.(sprintf('rate_%d', y))         = R(:, j, 1);
T.(sprintf('rate_%d_lower', y))   = R(:, j, 2);
T.(sprintf('rate_%d_upper', y))   = R(:, j, 3);
end
T.excess_total       = sum(E(:, :, 1), 2);
T.excess_total_lower = sum(E(:, :, 2), 2);
T.excess_total_upper = sum(E(:, :, 3), 2);
T.rate_total         = sum(R(:, :, 1), 2);
T.rate_total_lower   = sum(R(:, :, 2), 2);
T.rate_total_upper   = sum(R(:, :, 3), 2);
end
