clc;
clear;
close all;

forecastingperiod = 4;

stateFontSize      = 16;
xlabelFontSize     = 16;
xticklabelFontSize = 16;
valueFontSize      = 14;
barHeightInches    = 0.28;


codeDir = fileparts(mfilename('fullpath')); if ~isempty(codeDir), addpath(codeDir); end
P = project_paths();

dataPath     = P.out_states_cases;
ensemblePath = P.toolbox;
titlesFile   = fullfile(P.tb_states, 'Cases_Wide.xlsx');
observedFile = fullfile(P.tb_states, 'data_states.xlsx');
outputPath   = P.res;

if ~exist(outputPath, 'dir')
mkdir(outputPath);

end
addpath(ensemblePath);
titlesTable = readtable(titlesFile);
stateNames  = titlesTable.Properties.VariableNames(2:end);

obsRateByState = buildObservedRateMap(observedFile);
getObsRate = @(stateName, yr) interpRate(obsRateByState, stateName, yr);

casePattern = 'ranked(1)-onsetfixed-0-flag1-1-method-%d-dist-%d-horizon-4-yearly-tuberculosis-cases-USA-area-%d-01-01-2019.csv';

areaNumbers = 1:numel(stateNames);
numAreas = numel(areaNumbers);

RatioRates     = cell(numAreas, 6);
LogRatioRates  = cell(numAreas, 6);
ExpectedRates  = cell(numAreas, 6);
ObservedRates  = cell(numAreas, 6);
selectedStates = cell(numAreas, 1);
skippedStates  = {};


pandemicYears = 2020:2023;

for i = 1:numAreas
area = areaNumbers(i);
stateName = strrep(stateNames{area}, '_', ' ');
selectedStates{i} = stateName;

f1 = fullfile(dataPath, sprintf(casePattern, 1, 1, area));
f0 = fullfile(dataPath, sprintf(casePattern, 0, 0, area));
if exist(f1, 'file')
modelFile = f1;
elseif exist(f0, 'file')
modelFile = f0;

else
skippedStates{end+1} = stateName;
continue;
end
d = readmatrix(modelFile);
rowsP = 11:10+forecastingperiod;
obs_vec = d(rowsP, 2);
exp_med = d(rowsP, 3);

exp_lb  = d(rowsP, 4);
exp_ub  = d(rowsP, 5);
expSummary = struct('total_median', sum(exp_med), 'total_lb', sum(exp_lb), 'total_ub', sum(exp_ub));
ratio_med   = safeDivide(obs_vec, exp_med);
ratio_lower = safeDivide(obs_vec, exp_ub);
ratio_upper = safeDivide(obs_vec, exp_lb);

log_ratio_med   = safeLog(ratio_med);
log_ratio_lower = safeLog(ratio_lower);
log_ratio_upper = safeLog(ratio_upper);

sum_obs = sum(obs_vec, 'omitnan');

total_ratio_med   = safeDivide(sum_obs, expSummary.total_median);
total_ratio_lower = safeDivide(sum_obs, expSummary.total_ub);
total_ratio_upper = safeDivide(sum_obs, expSummary.total_lb);

total_log_ratio_med   = safeLog(total_ratio_med);
total_log_ratio_lower = safeLog(total_ratio_lower);
total_log_ratio_upper = safeLog(total_ratio_upper);

RatioRates{i,1}    = stateName;
LogRatioRates{i,1} = stateName;
ExpectedRates{i,1} = stateName;
ObservedRates{i,1} = stateName;


for k = 1:forecastingperiod
RatioRates{i,1+k}    = [ratio_med(k), ratio_lower(k), ratio_upper(k)];
LogRatioRates{i,1+k} = [log_ratio_med(k), log_ratio_lower(k), log_ratio_upper(k)];
ExpectedRates{i,1+k} = [exp_med(k), exp_lb(k), exp_ub(k)];
ObservedRates{i,1+k} = obs_vec(k);

end

RatioRates{i,6}    = [total_ratio_med, total_ratio_lower, total_ratio_upper];
LogRatioRates{i,6} = [total_log_ratio_med, total_log_ratio_lower, total_log_ratio_upper];
ExpectedRates{i,6} = [expSummary.total_median, expSummary.total_lb, expSummary.total_ub];
ObservedRates{i,6} = sum_obs;
end

validIdx = ~cellfun(@isempty, selectedStates) & ~cellfun(@isempty, RatioRates(:,1));
selectedStates = selectedStates(validIdx);
RatioRates     = RatioRates(validIdx, :);
LogRatioRates  = LogRatioRates(validIdx, :);
ExpectedRates  = ExpectedRates(validIdx, :);
ObservedRates  = ObservedRates(validIdx, :);
nStates        = numel(selectedStates);

if ~isempty(skippedStates)

warning('Skipped states without ranked model files: %s', strjoin(skippedStates, ', '));
end
yearLabels = {'2020','2021','2022','2023','Total_2020_2023'};
headers = {'State'};
for y = 1:5
headers{end+1} = sprintf('Ratio_%s_Median', yearLabels{y});
headers{end+1} = sprintf('Ratio_%s_LB',     yearLabels{y});

headers{end+1} = sprintf('Ratio_%s_UB',     yearLabels{y});
end
for y = 1:5
headers{end+1} = sprintf('LogRatio_%s_Median', yearLabels{y});
headers{end+1} = sprintf('LogRatio_%s_LB',     yearLabels{y});
headers{end+1} = sprintf('LogRatio_%s_UB',     yearLabels{y});
end
for y = 1:5
headers{end+1} = sprintf('Expected_%s_Median', yearLabels{y});
headers{end+1} = sprintf('Expected_%s_LB',     yearLabels{y});
headers{end+1} = sprintf('Expected_%s_UB',     yearLabels{y});
end
for y = 1:5
headers{end+1} = sprintf('Observed_%s', yearLabels{y});
end

excelData = cell(nStates, numel(headers));
for i = 1:nStates
excelData{i,1} = selectedStates{i};
col = 2;
for ci = 2:6
v = RatioRates{i, ci};
excelData{i, col} = v(1); excelData{i, col+1} = v(2); excelData{i, col+2} = v(3);
col = col + 3;
end
for ci = 2:6
v = LogRatioRates{i, ci};
excelData{i, col} = v(1); excelData{i, col+1} = v(2); excelData{i, col+2} = v(3);
col = col + 3;
end
for ci = 2:6

v = ExpectedRates{i, ci};
excelData{i, col} = v(1); excelData{i, col+1} = v(2); excelData{i, col+2} = v(3);
col = col + 3;
end

for ci = 2:6
excelData{i, col} = ObservedRates{i, ci};
col = col + 1;
end
end
ratioTable = cell2table(excelData, 'VariableNames', headers);
writetable(ratioTable, fullfile(outputPath, 'RatioRates_US_States.xlsx'));


logHeaders = {'State'};
for y = 1:5
logHeaders{end+1} = sprintf('LogRatio_%s_Median', yearLabels{y});
logHeaders{end+1} = sprintf('LogRatio_%s_LB',     yearLabels{y});
logHeaders{end+1} = sprintf('LogRatio_%s_UB',     yearLabels{y});
end
logData = cell(nStates, numel(logHeaders));
for i = 1:nStates
logData{i,1} = selectedStates{i};
col = 2;
for ci = 2:6
v = LogRatioRates{i, ci};
logData{i, col} = v(1); logData{i, col+1} = v(2); logData{i, col+2} = v(3);
col = col + 3;
end
end
logTable = cell2table(logData, 'VariableNames', logHeaders);
writetable(logTable, fullfile(outputPath, 'LogRatioRates_US_States.xlsx'));

for year_idx = 1:numel(pandemicYears)
medians = zeros(nStates, 1);
lowers  = zeros(nStates, 1);
uppers  = zeros(nStates, 1);
for i = 1:nStates
v = LogRatioRates{i, 1+year_idx};
medians(i) = v(1);
lowers(i)  = v(2);
uppers(i)  = v(3);
end

plotLogRatioPanel(selectedStates, medians, lowers, uppers, ...
sprintf('$\\log\\left(\\frac{O}{E}\\right)$ of TB cases in %d', pandemicYears(year_idx)), ...
fullfile(outputPath, sprintf('LogRatio_US_States_%d.pdf', pandemicYears(year_idx))), ...
stateFontSize, xlabelFontSize, xticklabelFontSize, valueFontSize, barHeightInches);
end

total_medians = zeros(nStates,1);
total_lowers  = zeros(nStates,1);
total_uppers  = zeros(nStates,1);
for i = 1:nStates
v = LogRatioRates{i, 6};
total_medians(i) = v(1);
total_lowers(i)  = v(2);
total_uppers(i)  = v(3);
end
plotLogRatioPanel(selectedStates, total_medians, total_lowers, total_uppers, ...
'Total $\log\left(\frac{O}{E}\right)$ of TB cases (2020--2023)', ...
fullfile(outputPath, 'LogRatio_US_States_Total.pdf'), ...
stateFontSize, xlabelFontSize, xticklabelFontSize, valueFontSize, barHeightInches);


fprintf('Done. Wrote:\n  %s\n  %s\n  %s\n', ...
fullfile(outputPath,'RatioRates_US_States.xlsx'), ...
fullfile(outputPath,'LogRatioRates_US_States.xlsx'), ...
fullfile(outputPath,'LogRatio_US_States_Total.pdf'));

function obsRateByState = buildObservedRateMap(observedFile)
obsTable = readtable(observedFile, 'VariableNamingRule', 'preserve');
obsTable = obsTable(~cellfun(@isempty, obsTable.State), :);
obsTable = obsTable(~isnan(obsTable.Year), :);

obsRateByState = containers.Map('KeyType','char','ValueType','any');
uniqueStates = unique(obsTable.State);

for s = 1:numel(uniqueStates)
stateName = uniqueStates{s};
rows = obsTable(strcmp(obsTable.State, stateName), :);
[yrs, idx] = sort(rows.Year);
rates = rows.Rate(idx);
obsRateByState(normalizeStateKey(stateName)) = struct('years', yrs(:), 'rates', rates(:));
end
end
function summary = getContinuousForecastSummary(modelFile, forecastingperiod)
global invasions timeinvasions Cinvasions

S = load(modelFile);
if isfield(S, 'npatches')
npatches = full(S.npatches);
else
npatches = full(S.npatches_fixed);
end
timevect2 = 0:S.t_window(end)-1+forecastingperiod;

curves = NaN(numel(timevect2), S.M);
kept = false(S.M, 1);

for realization = 1:S.M
rs_hat = S.Phatss(realization, 1:npatches);
ps_hat = S.Phatss(realization, npatches+1:2*npatches);
as_hat = S.Phatss(realization, 2*npatches+1:3*npatches);
Ks_hat = S.Phatss(realization, 3*npatches+1:4*npatches);


IC = zeros(npatches, 1);
if S.onset_thr > 0
IC(1,1) = S.data1(1,2);
IC(2:end,1) = 1;
invasions = zeros(npatches, 1);
timeinvasions = zeros(npatches, 1);
Cinvasions = zeros(npatches, 1);
invasions(1) = 1;
timeinvasions(1) = 0;

Cinvasions(1) = 0;

else
IC(1:end,1) = S.data1(1,2) ./ length(IC);

invasions = ones(npatches, 1);
timeinvasions = zeros(npatches, 1);
Cinvasions = zeros(npatches, 1);
end

[~, x] = ode15s(@modifiedLogisticGrowthPatch, timevect2, IC, [], ...
rs_hat, ps_hat, as_hat, Ks_hat, npatches, S.onset_thr, S.flag1);

if size(x, 1) ~= numel(timevect2)
continue;
end

y = sum(real(x), 2);
totinc = [y(1,1); diff(y(:,1))];
totinc(1) = totinc(1) - (npatches - 1);
curves(:, realization) = max(totinc, 0);
kept(realization) = true;
end
curves = curves(:, kept);
if isempty(curves)
error('No valid continuous forecast curves were reconstructed from %s', modelFile);
end


forecastRows = size(curves, 1)-forecastingperiod+1:size(curves, 1);
forecastCurves = curves(forecastRows, :);
totalCurves = sum(forecastCurves, 1);
summary.annual_median = median(forecastCurves, 2, 'omitnan');
summary.annual_lb     = quantile(forecastCurves', 0.025)';
summary.annual_ub     = quantile(forecastCurves', 0.975)';
summary.total_median  = median(totalCurves, 'omitnan');
summary.total_lb      = quantile(totalCurves, 0.025);
summary.total_ub      = quantile(totalCurves, 0.975);
end

function out = safeDivide(num, den)
out = NaN(size(num));

valid = isfinite(num) & isfinite(den) & den > 0;
out(valid) = num(valid) ./ den(valid);

end
function out = safeLog(x)
out = NaN(size(x));
valid = isfinite(x) & x > 0;
out(valid) = log(x(valid));
end

function plotLogRatioPanel(states, medians, lowers, uppers, xlab, exportname, ...
stateFS, xlabFS, xtickFS, valFS, barH)
valid = isfinite(medians);
states = states(valid);
medians = medians(valid);
lowers = lowers(valid);
uppers = uppers(valid);
n = length(states);


width_inches  = 14;
height_inches = max(8, barH * n);
fig = figure('Units','inches','Position',[1 1 width_inches height_inches]);

[~, sort_idx] = sortrows([medians, uppers, lowers], [1 2 3], {'ascend','ascend','ascend'});
states  = states(sort_idx);
states  = strrep(regexprep(states, '([a-z])([A-Z])', '$1 $2'), ' Of ', ' of ');
medians = medians(sort_idx);


y_positions = 1:n;
finiteVals = medians(isfinite(medians));
lim = max(1.5, max(abs(finiteVals)) * 1.15);
x_min = -lim;
x_max = lim;
raw_span = max(abs(x_min), abs(x_max));
pos_idx = medians >= 0;
neg_idx = ~pos_idx;
hold on;
if any(pos_idx)
barh(y_positions(pos_idx), medians(pos_idx), 0.7, ...
'FaceColor', [0.30 0.60 0.80], 'EdgeColor', 'none');
end

if any(neg_idx)
barh(y_positions(neg_idx), medians(neg_idx), 0.7, ...
'FaceColor', [0.85 0.45 0.45], 'EdgeColor', 'none');
end

plot([0 0], [0.3 n+0.7], 'k-', 'LineWidth', 1.2);
set(gca,'YTick',[]);
ylim([0.3 n+0.7]);
xlim([x_min x_max]);
for i = 1:n
if medians(i) >= 0
text(-0.01*raw_span, y_positions(i), states{i}, ...
'HorizontalAlignment','right','VerticalAlignment','middle', ...
'FontSize', stateFS, 'Interpreter','latex');
else
text(0.01*raw_span, y_positions(i), states{i}, ...
'HorizontalAlignment','left','VerticalAlignment','middle', ...
'FontSize', stateFS, 'Interpreter','latex');
end

end

for i = 1:n
label = sprintf('%.2f', medians(i));
if medians(i) >= 0
xt = medians(i) + 0.02*raw_span;
text(xt, y_positions(i), label, ...
'HorizontalAlignment','left','VerticalAlignment','middle', ...
'FontSize', valFS, 'Interpreter','latex');
else
xt = medians(i) - 0.02*raw_span;
text(xt, y_positions(i), label, ...
'HorizontalAlignment','right','VerticalAlignment','middle', ...
'FontSize', valFS, 'Interpreter','latex');
end
end
xlabel(xlab, 'Interpreter','latex', 'FontSize', xlabFS);


ax = gca;
ax.XAxis.FontSize = xtickFS;
ax.XAxis.TickLabelInterpreter = 'latex';
grid off; box off;
set(gca,'LineWidth',1.2);

set(fig,'PaperUnits','inches');
set(fig,'PaperSize',[width_inches height_inches]);
set(fig,'PaperPosition',[0 0 width_inches height_inches]);
saveas(fig, exportname);
close(fig);
end

function r = interpRate(obsMap, stateName, yr)
key = normalizeStateKey(stateName);
if ~isKey(obsMap, key)
error('State "%s" not found in observed table.', stateName);
end

rec = obsMap(key);
yrs = rec.years;

rates = rec.rates;
hit = find(yrs == yr, 1);
if ~isempty(hit) && ~isnan(rates(hit))

r = rates(hit);
return;

end
valid = ~isnan(rates);
if sum(valid) < 1
error('State "%s" has no usable observed rates.', stateName);
end

if sum(valid) == 1
r = rates(find(valid, 1));
return;
end

r = interp1(yrs(valid), rates(valid), yr, 'linear', 'extrap');
end
function key = normalizeStateKey(stateName)
key = lower(regexprep(strtrim(stateName), '[\s_]', ''));

end
