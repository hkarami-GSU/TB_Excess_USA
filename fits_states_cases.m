clc;
clear;
close all;

titleFontSize = 16;
ylabelFontSize = 16;
xlabelFontSize = 16;
yticklabelFontSize = 18;
xticklabelFontSize = 14;
ylabelText = 'Cases';


codeDir = fileparts(mfilename('fullpath')); if ~isempty(codeDir), addpath(codeDir); end
P = project_paths();
dataPath = P.out_states_cases;
titlesFile = fullfile(P.tb_states, 'Cases_Wide.xlsx');

titlesTable = readtable(titlesFile);
stateNames = titlesTable.Properties.VariableNames(2:end);

calibration_period = 10;

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

numCols = 5;
numRows = ceil(numAreas / numCols);
figure('Position', [10, 10, 1200, 200*numRows]);


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

data = readmatrix(csvFilename);
years = (2010:2023)';

actual_data = data(:,2);
below_lb_idx = (years > years(calibration_period)) & (data(:,2) < data(:,4));

subplot(numRows, numCols, i);
hold on;

plot(years(1:calibration_period), actual_data(1:calibration_period), 'o', ...
'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'none', 'LineWidth', 2, 'MarkerSize', 8);

plot(years(calibration_period+1:end), actual_data(calibration_period+1:end), 'o', ...
'MarkerEdgeColor', [0, 0.5, 0], 'MarkerFaceColor', [0, 0.5, 0], 'LineWidth', 2, 'MarkerSize', 8);
plot(years, data(:, 3), 'r-', 'LineWidth', 3);
plot(years, data(:, 4), 'k--', 'LineWidth', 2.5);
plot(years, data(:, 5), 'k--', 'LineWidth', 2.5);

xlim([2010 2023]);
ylims = ylim;
ylim([min(ylims)-1 max(ylims)+1]);

ylims = ylim;

set(gca, 'Clipping', 'off');
covid_start = 2019;
covid_end = 2023;
covid_patch = patch([covid_start covid_end covid_end covid_start], ...
[ylims(1) ylims(1) ylims(2) ylims(2)], ...
[0.7 0.7 0.7], 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'Clipping', 'off');
uistack(covid_patch, 'bottom');

grid off;
xline(2019, 'b--', 'LineWidth', 2.5);

if area <= length(stateNames)
stateName = stateNames{area};

stateName = strrep(stateName, '_', ' ');
stateName = strrep(regexprep(stateName, '([a-z])([A-Z])', '$1 $2'), ' Of ', ' of ');
else
stateName = sprintf('Area %d', area);
end
ax = gca;


ytick_vals = [ylims(1), mean(ylims), ylims(2)];
yticks(ytick_vals);
yticklabels(string(floor(ytick_vals)));


if i > (numAreas - numCols)
xticks([2010 2015 2019 2023]);
xtickangle(90);
else
xticks([]);
end

if mod(i - 1, numCols) == 0
ylabel(ylabelText, 'Interpreter', 'latex', 'FontSize', ylabelFontSize);
end


title(sprintf('%s', stateName), 'Interpreter', 'latex', 'FontSize', titleFontSize);


set(ax, 'FontSize', max(xticklabelFontSize, yticklabelFontSize));

grid on;
set(gca, 'Layer', 'top');
hold off;
end

widthPerCol = 4;
heightPerRow = 3.5;

totalWidth = numCols * widthPerCol;
totalHeight = numRows * heightPerRow;

fig = gcf;
set(fig, 'Units', 'inches');

set(fig, 'Position', [1, 1, totalWidth, totalHeight]);
set(fig, 'PaperUnits', 'inches');

set(fig, 'PaperSize', [totalWidth, totalHeight]);
set(fig, 'PaperPosition', [0, 0, totalWidth, totalHeight]);
print(fig, fullfile(P.res, 'US_States_TB_Cases.pdf'), '-dpdf', '-r300');
