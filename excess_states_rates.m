clc;
clear;
close all;


calibration_period = 10;

stateFontSize = 16;
xlabelFontSize = 16;
xticklabelFontSize = 16;
valueFontSize = 16;
barHeightInches = 0.25;

codeDir = fileparts(mfilename('fullpath')); if ~isempty(codeDir), addpath(codeDir); end
P = project_paths();
dataPath = P.out_states_cases;
titlesFile = fullfile(P.tb_states, 'Cases_Wide.xlsx');

popTable = readtable(fullfile(P.pop, 'NST-EST2023-POPCHG2020_2023_states.csv'));
popKey = lower(strrep(popTable.NAME, ' ', ''));
popMat = [popTable.POPESTIMATE2020, popTable.POPESTIMATE2021, popTable.POPESTIMATE2022, popTable.POPESTIMATE2023];
outputPath = P.res;

titlesTable = readtable(titlesFile);
stateNames = titlesTable.Properties.VariableNames(2:end);
primaryPattern = 'ranked(1)-onsetfixed-0-flag1-1-method-1-dist-1-horizon-4-yearly-tuberculosis-cases-USA-area-%d-01-01-2019.csv';
fallbackPattern = 'ranked(1)-onsetfixed-0-flag1-1-method-0-dist-0-horizon-4-yearly-tuberculosis-cases-USA-area-%d-01-01-2019.csv';
files1 = dir(fullfile(dataPath, 'ranked(1)-*method-1-dist-1*.csv'));

files0 = dir(fullfile(dataPath, 'ranked(1)-*method-0-dist-0*.csv'));


allAreas = [];
for i = 1:length(files1)
tokens = regexp(files1(i).name, 'area-(\d+)-', 'tokens');
if ~isempty(tokens)
allAreas = [allAreas; str2double(tokens{1}{1})];
end
end
for i = 1:length(files0)
tokens = regexp(files0(i).name, 'area-(\d+)-', 'tokens');
if ~isempty(tokens)
allAreas = [allAreas; str2double(tokens{1}{1})];
end
end

areaNumbers = unique(allAreas);
numAreas = length(areaNumbers);

ExcessRates = cell(numAreas, 6);
selectedStates = cell(numAreas, 1);

for i = 1:numAreas
area = areaNumbers(i);
primaryFile = fullfile(dataPath, sprintf(primaryPattern, area));
fallbackFile = fullfile(dataPath, sprintf(fallbackPattern, area));

if exist(primaryFile, 'file')
csvFilename = primaryFile;
elseif exist(fallbackFile, 'file')
csvFilename = fallbackFile;
else

continue;
end


if area <= length(stateNames)
stateName = stateNames{area};
stateName = strrep(stateName, '_', ' ');

else
stateName = sprintf('Area %d', area);
end
selectedStates{i} = stateName;

data = readmatrix(csvFilename);
years = (2010:2023)';
excess_cases_median_2020 = max(0, data(11,2) - data(11,3));
excess_cases_lower_2020 = max(0, data(11,2) - data(11,5));
excess_cases_upper_2020 = max(0, data(11,2) - data(11,4));

excess_cases_median_2021 = max(0, data(12,2) - data(12,3));
excess_cases_lower_2021 = max(0, data(12,2) - data(12,5));
excess_cases_upper_2021 = max(0, data(12,2) - data(12,4));


excess_cases_median_2022 = max(0, data(13,2) - data(13,3));
excess_cases_lower_2022 = max(0, data(13,2) - data(13,5));
excess_cases_upper_2022 = max(0, data(13,2) - data(13,4));

excess_cases_median_2023 = max(0, data(14,2) - data(14,3));
excess_cases_lower_2023 = max(0, data(14,2) - data(14,5));
excess_cases_upper_2023 = max(0, data(14,2) - data(14,4));

pidx = find(strcmp(popKey, lower(strrep(stateName, ' ', ''))));
if numel(pidx) ~= 1
error('No population found for %s.', stateName);
end
scale = 1e5 ./ popMat(pidx, :);
excess_cases_median_2020 = excess_cases_median_2020 * scale(1);
excess_cases_lower_2020  = excess_cases_lower_2020  * scale(1);
excess_cases_upper_2020  = excess_cases_upper_2020  * scale(1);
excess_cases_median_2021 = excess_cases_median_2021 * scale(2);
excess_cases_lower_2021  = excess_cases_lower_2021  * scale(2);
excess_cases_upper_2021  = excess_cases_upper_2021  * scale(2);
excess_cases_median_2022 = excess_cases_median_2022 * scale(3);
excess_cases_lower_2022  = excess_cases_lower_2022  * scale(3);
excess_cases_upper_2022  = excess_cases_upper_2022  * scale(3);
excess_cases_median_2023 = excess_cases_median_2023 * scale(4);
excess_cases_lower_2023  = excess_cases_lower_2023  * scale(4);
excess_cases_upper_2023  = excess_cases_upper_2023  * scale(4);


total_excess_median = excess_cases_median_2020 + excess_cases_median_2021 + ...
excess_cases_median_2022 + excess_cases_median_2023;
total_excess_lower = excess_cases_lower_2020 + excess_cases_lower_2021 + ...
excess_cases_lower_2022 + excess_cases_lower_2023;
total_excess_upper = excess_cases_upper_2020 + excess_cases_upper_2021 + ...
excess_cases_upper_2022 + excess_cases_upper_2023;

ExcessRates{i,1} = stateName;
ExcessRates{i,2} = [excess_cases_median_2020, excess_cases_lower_2020, excess_cases_upper_2020];
ExcessRates{i,3} = [excess_cases_median_2021, excess_cases_lower_2021, excess_cases_upper_2021];
ExcessRates{i,4} = [excess_cases_median_2022, excess_cases_lower_2022, excess_cases_upper_2022];

ExcessRates{i,5} = [excess_cases_median_2023, excess_cases_lower_2023, excess_cases_upper_2023];
ExcessRates{i,6} = [total_excess_median, total_excess_lower, total_excess_upper];
end

validIdx = ~cellfun(@isempty, selectedStates);
selectedStates = selectedStates(validIdx);

ExcessRates = ExcessRates(validIdx, :);

excelData = cell(length(selectedStates), 4);

for i = 1:length(selectedStates)
excelData{i, 1} = selectedStates{i};
excelData{i, 2} = ExcessRates{i, 6}(1);
excelData{i, 3} = ExcessRates{i, 6}(2);
excelData{i, 4} = ExcessRates{i, 6}(3);
end

excelTable = cell2table(excelData, 'VariableNames', {'State', 'ExcessRate_Median', 'ExcessRate_LB', 'ExcessRate_UB'});
writetable(excelTable, fullfile(outputPath, 'ExcessRates_US_States.xlsx'));

years_to_plot = 2020:2023;


for year_idx = 1:length(years_to_plot)
current_year = years_to_plot(year_idx);
width_inches = 12;
height_inches = max(8, barHeightInches * length(selectedStates));
fig = figure('Units', 'inches', 'Position', [1, 1, width_inches, height_inches]);

year_medians = zeros(length(selectedStates), 1);
year_lowers = zeros(length(selectedStates), 1);
year_uppers = zeros(length(selectedStates), 1);

for i = 1:length(selectedStates)
if ~isempty(ExcessRates{i, year_idx+1})
year_medians(i) = ExcessRates{i, year_idx+1}(1);
year_lowers(i) = ExcessRates{i, year_idx+1}(2);
year_uppers(i) = ExcessRates{i, year_idx+1}(3);
end
end


sort_matrix = [year_medians, year_uppers, year_lowers];
[~, sort_idx] = sortrows(sort_matrix, [1, 2, 3], {'ascend', 'ascend', 'ascend'});

sorted_states = strrep(regexprep(selectedStates(sort_idx), '([a-z])([A-Z])', '$1 $2'), ' Of ', ' of ');
sorted_medians = year_medians(sort_idx);
sorted_lowers = year_lowers(sort_idx);
sorted_uppers = year_uppers(sort_idx);

y_positions = 1:length(selectedStates);


h = barh(y_positions, sorted_medians, 'FaceColor', [0.3 0.6 0.8]);
hold on;

err_neg = sorted_medians - sorted_lowers;
err_pos = sorted_uppers - sorted_medians;
errorbar(sorted_medians, y_positions, err_neg, err_pos, 'horizontal', '.k', 'LineWidth', 1.5);
yticks(y_positions);
set(gca, 'YTickLabel', sorted_states, 'TickLabelInterpreter', 'latex', 'FontSize', stateFontSize);
xlabel(sprintf('Excess TB Rate in %d', current_year), 'FontSize', xlabelFontSize, 'FontWeight', 'bold', 'Interpreter', 'latex');
for i = 1:length(y_positions)

text(sorted_uppers(i) + max(sorted_medians)*0.02, y_positions(i), ...
sprintf('%s [%s--%s]', ...
formatNumber(sorted_medians(i)), ...
formatNumber(sorted_lowers(i)), ...
formatNumber(sorted_uppers(i))), ...
'VerticalAlignment', 'middle', ...
'HorizontalAlignment', 'left', ...
'FontSize', valueFontSize, ...
'Interpreter', 'latex');
end

max_x = max(sorted_uppers) * 1.4;
xlim([0 max_x]);
ax = gca;
ax.XAxis.FontSize = xticklabelFontSize;
ax.XAxis.TickLabelInterpreter = 'latex';
ax.XAxis.Exponent = 0;
xtickformat('%.0f');

grid off;
set(gca, 'YGrid', 'off');
box off;
set(gca, 'LineWidth', 1.2);

exportname = fullfile(outputPath, sprintf('ExcessRates_US_States_%d.pdf', current_year));
set(fig, 'PaperUnits', 'inches');
set(fig, 'PaperSize', [width_inches height_inches]);
set(fig, 'PaperPosition', [0 0 width_inches height_inches]);
saveas(fig, exportname);

hold off;
end
width_inches = 12;

height_inches = max(8, barHeightInches * length(selectedStates));
fig = figure('Units', 'inches', 'Position', [1, 1, width_inches, height_inches]);

total_medians = zeros(length(selectedStates), 1);
total_lowers = zeros(length(selectedStates), 1);
total_uppers = zeros(length(selectedStates), 1);


for i = 1:length(selectedStates)
if ~isempty(ExcessRates{i, 6})
total_medians(i) = ExcessRates{i, 6}(1);
total_lowers(i) = ExcessRates{i, 6}(2);
total_uppers(i) = ExcessRates{i, 6}(3);

end
end

sort_matrix = [total_medians, total_uppers, total_lowers];

[~, sort_idx] = sortrows(sort_matrix, [1, 2, 3], {'ascend', 'ascend', 'ascend'});

sorted_states = strrep(regexprep(selectedStates(sort_idx), '([a-z])([A-Z])', '$1 $2'), ' Of ', ' of ');
sorted_medians = total_medians(sort_idx);
sorted_lowers = total_lowers(sort_idx);
sorted_uppers = total_uppers(sort_idx);

y_positions = 1:length(selectedStates);


h = barh(y_positions, sorted_medians, 'FaceColor', [0.3 0.6 0.8]);
hold on;

err_neg = sorted_medians - sorted_lowers;
err_pos = sorted_uppers - sorted_medians;
errorbar(sorted_medians, y_positions, err_neg, err_pos, 'horizontal', '.k', 'LineWidth', 1.5);

yticks(y_positions);
set(gca, 'YTickLabel', sorted_states, 'TickLabelInterpreter', 'latex', 'FontSize', stateFontSize);
xlabel('Excess TB incidence rate per 100,000 (2020--2023)', ...
'FontSize', xlabelFontSize,'Interpreter', 'latex');

for i = 1:length(y_positions)
text(sorted_uppers(i) + max(sorted_medians)*0.02, y_positions(i), ...
sprintf('%s [%s--%s]', ...
formatNumber(sorted_medians(i)), ...
formatNumber(sorted_lowers(i)), ...
formatNumber(sorted_uppers(i))), ...
'VerticalAlignment', 'middle', ...
'HorizontalAlignment', 'left', ...
'FontSize', valueFontSize, ...
'Interpreter', 'latex');
end

max_x = max(sorted_uppers) * 1.4;
xlim([0 max_x]);
ax = gca;
ax.XAxis.FontSize = xticklabelFontSize;
ax.XAxis.TickLabelInterpreter = 'latex';
ax.XAxis.Exponent = 0;
xtickformat('%.0f');

grid off;
set(gca, 'YGrid', 'off');

box off;
set(gca, 'LineWidth', 1.2);

exportname = fullfile(outputPath, 'ExcessRates_US_States_Total.pdf');
set(fig, 'PaperUnits', 'inches');
set(fig, 'PaperSize', [width_inches height_inches]);
set(fig, 'PaperPosition', [0 0 width_inches height_inches]);
saveas(fig, exportname);

hold off;


function out = round2sd(x, n)

if x == 0
out = 0;
else
out = round(x, n - floor(log10(abs(x))) - 1);
end
end


function out = formatNumber(x)
if x == 0
out = '0';
else
if x < 10
out = sprintf('%.2g', round2sd(x, 2));
elseif x < 100
out = sprintf('%.1f', x);
else
out = sprintf('%.0f', round2sd(x, 2));

end
end
end
