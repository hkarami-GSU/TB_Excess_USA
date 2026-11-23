clc;
clear;
close all;

calibration_period = 10;

stateFontSize = 16;
xlabelFontSize = 16;
xticklabelFontSize = 16;
valueFontSize = 16;
barHeightInches = 0.35;


codeDir = fileparts(mfilename('fullpath')); if ~isempty(codeDir), addpath(codeDir); end
P = project_paths();
dataPath = P.out_age;
titlesFile = fullfile(P.tb_age, 'Cases_Wide.xlsx');
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

excessCases = cell(numAreas, 6);
selectedAge = cell(numAreas, 1);

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
ageName = stateNames{area};

if startsWith(ageName, 'x')
ageName = ageName(2:end);
end
ageName = strrep(ageName, '_', '-');
if strcmp(ageName, '-1') || strcmp(ageName, '1')
ageName = '$<$1';
elseif strcmp(ageName, '85-') || strcmp(ageName, '85')
ageName = '$\geq$85';
end

else
ageName = sprintf('Area %d', area);
end
selectedAge{i} = ageName;

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
total_excess_median = excess_cases_median_2020 + excess_cases_median_2021 + ...
excess_cases_median_2022 + excess_cases_median_2023;
total_excess_lower = excess_cases_lower_2020 + excess_cases_lower_2021 + ...
excess_cases_lower_2022 + excess_cases_lower_2023;
total_excess_upper = excess_cases_upper_2020 + excess_cases_upper_2021 + ...
excess_cases_upper_2022 + excess_cases_upper_2023;

excessCases{i,1} = ageName;
excessCases{i,2} = [excess_cases_median_2020, excess_cases_lower_2020, excess_cases_upper_2020];
excessCases{i,3} = [excess_cases_median_2021, excess_cases_lower_2021, excess_cases_upper_2021];
excessCases{i,4} = [excess_cases_median_2022, excess_cases_lower_2022, excess_cases_upper_2022];
excessCases{i,5} = [excess_cases_median_2023, excess_cases_lower_2023, excess_cases_upper_2023];
excessCases{i,6} = [total_excess_median, total_excess_lower, total_excess_upper];
end
validIdx = ~cellfun(@isempty, selectedAge);
selectedAge = selectedAge(validIdx);
excessCases = excessCases(validIdx, :);

years_to_plot = 2020:2023;

for year_idx = 1:length(years_to_plot)
current_year = years_to_plot(year_idx);

width_inches = 12;
height_inches = barHeightInches * length(selectedAge);

fig = figure('Units', 'inches', 'Position', [1, 1, width_inches, height_inches]);

year_medians = zeros(length(selectedAge), 1);
year_lowers = zeros(length(selectedAge), 1);
year_uppers = zeros(length(selectedAge), 1);


for i = 1:length(selectedAge)
if ~isempty(excessCases{i, year_idx+1})
year_medians(i) = excessCases{i, year_idx+1}(1);
year_lowers(i) = excessCases{i, year_idx+1}(2);
year_uppers(i) = excessCases{i, year_idx+1}(3);
end
end


sort_matrix = [year_medians, year_uppers, year_lowers];

[~, sort_idx] = sortrows(sort_matrix, [1, 2, 3], {'ascend', 'ascend', 'ascend'});


sorted_Age = selectedAge(sort_idx);
sorted_medians = year_medians(sort_idx);
sorted_lowers = year_lowers(sort_idx);

sorted_uppers = year_uppers(sort_idx);

y_positions = 1:length(selectedAge);
h = barh(y_positions, sorted_medians, 'FaceColor', [0.3 0.6 0.8]);
hold on;

err_neg = sorted_medians - sorted_lowers;
err_pos = sorted_uppers - sorted_medians;
errorbar(sorted_medians, y_positions, err_neg, err_pos, 'horizontal', '.k', 'LineWidth', 1.5);

yticks(y_positions);
set(gca, 'YTickLabel', sorted_Age, 'TickLabelInterpreter', 'latex', 'FontSize', stateFontSize);
xlabel(sprintf('Excess TB Cases in %d', current_year), 'FontSize', xlabelFontSize, 'FontWeight', 'bold', 'Interpreter', 'latex');

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

exportname = fullfile(outputPath, sprintf('ExcessCases_US_Age_%d.pdf', current_year));
set(fig, 'PaperUnits', 'inches');
set(fig, 'PaperSize', [width_inches height_inches]);
set(fig, 'PaperPosition', [0 0 width_inches height_inches]);
saveas(fig, exportname);

hold off;
end


width_inches = 12;
height_inches = barHeightInches * length(selectedAge);
fig = figure('Units', 'inches', 'Position', [1, 1, width_inches, height_inches]);


total_medians = zeros(length(selectedAge), 1);
total_lowers = zeros(length(selectedAge), 1);
total_uppers = zeros(length(selectedAge), 1);


for i = 1:length(selectedAge)
if ~isempty(excessCases{i, 6})
total_medians(i) = excessCases{i, 6}(1);
total_lowers(i) = excessCases{i, 6}(2);
total_uppers(i) = excessCases{i, 6}(3);

end
end

sort_matrix = [total_medians, total_uppers, total_lowers];
[~, sort_idx] = sortrows(sort_matrix, [1, 2, 3], {'ascend', 'ascend', 'ascend'});
sorted_Age = selectedAge(sort_idx);
sorted_medians = total_medians(sort_idx);
sorted_lowers = total_lowers(sort_idx);
sorted_uppers = total_uppers(sort_idx);
y_positions = 1:length(selectedAge);

h = barh(y_positions, sorted_medians, 'FaceColor', [0.3 0.6 0.8]);
hold on;

err_neg = sorted_medians - sorted_lowers;
err_pos = sorted_uppers - sorted_medians;
errorbar(sorted_medians, y_positions, err_neg, err_pos, 'horizontal', '.k', 'LineWidth', 1.5);

yticks(y_positions);
set(gca, 'YTickLabel', sorted_Age, 'TickLabelInterpreter', 'latex', 'FontSize', stateFontSize);
xlabel('Total Excess TB Cases (2020–2023)', ...
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

exportname = fullfile(outputPath, 'ExcessCases_US_Age_Total.pdf');
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
x = round2sd(x, 2);
if x < 10
out = sprintf('%.2g', x);
elseif x < 100
out = sprintf('%.1f', x);
else
out = sprintf('%.0f', x);
end
end
end
