clear; clc; close all;

codeDir = fileparts(mfilename('fullpath')); if ~isempty(codeDir), addpath(codeDir); end
P = project_paths();
results_path = P.res;

state_abbrev_map = containers.Map(...
{'AK','AL','AR','AZ','CA','CO','CT','DC','DE','FL','GA','HI','IA','ID','IL','IN','KS','KY','LA','MA','MD','ME','MI','MN','MO','MS','MT','NC','ND','NE','NH','NJ','NM','NV','NY','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VA','VT','WA','WI','WV','WY'}, ...
{'Alaska','Alabama','Arkansas','Arizona','California','Colorado','Connecticut','District of Columbia','Delaware','Florida','Georgia','Hawaii','Iowa','Idaho','Illinois','Indiana','Kansas','Kentucky','Louisiana','Massachusetts','Maryland','Maine','Michigan','Minnesota','Missouri','Mississippi','Montana','North Carolina','North Dakota','Nebraska','New Hampshire','New Jersey','New Mexico','Nevada','New York','Ohio','Oklahoma','Oregon','Pennsylvania','Rhode Island','South Carolina','South Dakota','Tennessee','Texas','Utah','Virginia','Vermont','Washington','Wisconsin','West Virginia','Wyoming'});

fprintf('Loading Excess Cases data...\n');
excess_data = readtable(fullfile(P.res, 'ExcessCases_US_States.xlsx'));

fprintf('Loading Population Density data...\n');
density_data = readtable(fullfile(P.pred, 'state_population_density.csv'));
fprintf('Loading Foreign-born data...\n');
foreign_data = readtable(fullfile(P.pred, 'ACSDP5Y2023.DP02-Data_total_foreign_born.csv'));

fprintf('Loading Poverty data...\n');
poverty_data = readtable(fullfile(P.pred, 'ACSDP5Y2023.DP03-Data.csv'));

fprintf('Loading Population data...\n');
pop_data = readtable(fullfile(P.pred, 'ACSDP5Y2023.DP05-Data_total_population.csv'));

fprintf('Loading AI/AN data...\n');
aian_data = readtable(fullfile(P.pred, 'ACSDP5Y2023.DP05-Data_AIAN.csv'));

fprintf('Loading HIV data...\n');
hiv_data = readtable(fullfile(P.pred, 'AtlasPlusTableData.csv'));

fprintf('Loading Prisoners data...\n');

prisoners_data = readtable(fullfile(P.pred, 'prisoners.csv'));

fprintf('Loading Homeless data...\n');
homeless_file = fullfile(P.pred, '2007-2023-PIT-Counts-by-State.xlsx');
homeless_data = readtable(homeless_file, 'Sheet', '2023');
fprintf('Homeless data columns: ');

disp(homeless_data.Properties.VariableNames);


state_names = {'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', ...
'Colorado', 'Connecticut', 'Delaware', 'District of Columbia', 'Florida', ...
'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', ...
'Iowa', 'Kansas', 'Kentucky', 'Louisiana', 'Maine', ...
'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', ...
'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', ...
'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota', ...
'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', ...
'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', ...
'Vermont', 'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming'};

n_states = length(state_names);

data_matrix = table();
data_matrix.State = state_names';


fprintf('\nProcessing Density...\n');
density_vec = zeros(n_states, 1);

for i = 1:n_states
idx = find(strcmpi(density_data.State, state_names{i}));
if ~isempty(idx)

density_vec(i) = density_data.Density(idx(1));
else
density_vec(i) = NaN;
end
end
data_matrix.Density = density_vec;

fprintf('Processing Population...\n');
pop_vec = zeros(n_states, 1);
for i = 1:n_states
idx = find(strcmpi(strtrim(pop_data.NAME), state_names{i}));
if ~isempty(idx)
pop_vec(i) = pop_data.DP05_0001E(idx(1));
else

pop_vec(i) = NaN;
end
end
data_matrix.Population = pop_vec;


fprintf('Processing Foreign-born...\n');
foreign_vec = zeros(n_states, 1);
for i = 1:n_states
idx = find(strcmpi(strtrim(foreign_data.NAME), state_names{i}));
if ~isempty(idx)
fb_count = foreign_data.DP02_0094E(idx(1));
if isnumeric(fb_count)
foreign_vec(i) = (fb_count / pop_vec(i)) * 100;
else

foreign_vec(i) = NaN;
end
else
foreign_vec(i) = NaN;
end
end
data_matrix.ForeignBornPct = foreign_vec;

fprintf('Processing Poverty...\n');
poverty_vec = zeros(n_states, 1);
for i = 1:n_states
idx = find(strcmpi(strtrim(poverty_data.NAME), state_names{i}));
if ~isempty(idx)
pov_val = poverty_data.DP03_0119PE(idx(1));

if isnumeric(pov_val)
poverty_vec(i) = pov_val;
else
poverty_vec(i) = NaN;
end
else
poverty_vec(i) = NaN;
end

end
data_matrix.PovertyPct = poverty_vec;

fprintf('Processing HIV...\n');
hiv_vec = zeros(n_states, 1);
for i = 1:n_states
idx = find(strcmpi(strtrim(regexprep(hiv_data.Geography, '[\^\*]+$', '')), state_names{i}));
if ~isempty(idx)
rates = hiv_data.RatePer100000(idx);
if isnumeric(rates)
hiv_vec(i) = mean(rates, 'omitnan');
else
hiv_vec(i) = NaN;
end
else
hiv_vec(i) = NaN;
end
end
data_matrix.HIVRate = hiv_vec;

fprintf('Processing Incarceration...\n');
prison_vec = zeros(n_states, 1);
for i = 1:n_states
idx = find(strcmpi(strtrim(regexprep(prisoners_data.state, '/.*$', '')), state_names{i}));

if ~isempty(idx)
prison_str = prisoners_data.Total{idx(1)};

prison_num = str2double(strrep(prison_str, ',', ''));

if ~isnan(prison_num) && pop_vec(i) > 0
prison_vec(i) = (prison_num / pop_vec(i)) * 100000;
else
prison_vec(i) = NaN;

end
else

prison_vec(i) = NaN;
end
end
data_matrix.IncarcerationRate = prison_vec;
fprintf('Processing Homelessness (Overall Homeless)...\n');
homeless_vec = zeros(n_states, 1);

state_col_name = homeless_data.Properties.VariableNames{1};

for i = 1:n_states
state_full = state_names{i};

idx = find(strcmpi(strtrim(string(homeless_data.(state_col_name))), state_full));

if isempty(idx)
abbrevs = keys(state_abbrev_map);

for k = 1:length(abbrevs)
if strcmpi(state_abbrev_map(abbrevs{k}), state_full)
idx = find(strcmpi(string(homeless_data.(state_col_name)), abbrevs{k}));
break;
end
end

end


if ~isempty(idx)
oh_col_idx = find(contains(homeless_data.Properties.VariableNames, 'OverallHomeless', 'IgnoreCase', true));
if isempty(oh_col_idx)
oh_col_idx = find(contains(homeless_data.Properties.VariableNames, 'Overall', 'IgnoreCase', true));
end
if ~isempty(oh_col_idx)
val = homeless_data{idx(1), oh_col_idx(1)};
if isnumeric(val)
homeless_vec(i) = val;

elseif ischar(val) || isstring(val)
homeless_vec(i) = str2double(strrep(char(val), ',', ''));
end
end
end
end

homeless_rate = (homeless_vec ./ pop_vec) * 100000;
data_matrix.HomelessRate = homeless_rate;

fprintf('Homeless data summary:\n');

fprintf('  States with data: %d\n', sum(homeless_vec > 0));
fprintf('  Range: %.0f - %.0f\n', min(homeless_vec(homeless_vec > 0)), max(homeless_vec));

fprintf('\nProcessing AI/AN Percentage...\n');
aian_vec = zeros(n_states, 1);
for i = 1:n_states
idx = find(strcmpi(strtrim(aian_data.NAME), state_names{i}));
if ~isempty(idx)
if ismember('DP05_0039PE', aian_data.Properties.VariableNames)
val = aian_data.DP05_0039PE(idx(1));
if isnumeric(val) && ~isnan(val)
aian_vec(i) = val;
end
end
end
end
data_matrix.AIANPct = aian_vec;

fprintf('AI/AN data summary:\n');
fprintf('  States with data: %d\n', sum(aian_vec > 0));
fprintf('  Range: %.2f%% - %.2f%%\n', min(aian_vec(aian_vec > 0)), max(aian_vec));

fprintf('\nProcessing Excess Cases...\n');

excess_vec = zeros(n_states, 1);
state_col_idx = find(contains(excess_data.Properties.VariableNames, 'State', 'IgnoreCase', true) | ...
contains(excess_data.Properties.VariableNames, 'Area', 'IgnoreCase', true));
if ~isempty(state_col_idx)
state_col = excess_data.Properties.VariableNames{state_col_idx(1)};
excess_col_idx = find(contains(excess_data.Properties.VariableNames, 'Median', 'IgnoreCase', true));
if ~isempty(excess_col_idx)

excess_col = excess_data.Properties.VariableNames{excess_col_idx(1)};
for i = 1:n_states

idx = find(strcmpi(strrep(string(excess_data.(state_col)), ' ', ''), strrep(state_names{i}, ' ', '')));
if ~isempty(idx)
val = excess_data.(excess_col)(idx(1));
if isnumeric(val)
excess_vec(i) = val;
end
end
end
end
end
data_matrix.ExcessCases = excess_vec;
fprintf('\n=== Merged Data Matrix ===\n');
disp(data_matrix);
writetable(data_matrix, fullfile(results_path, 'merged_regression_data.csv'));
fprintf('\nMerged data saved to: %s\n', fullfile(results_path, 'merged_regression_data.csv'));
fprintf('\n=== Preparing Regression Analysis ===\n');

predictor_names = {'Density', 'ForeignBornPct', 'PovertyPct', 'HIVRate', 'IncarcerationRate', 'HomelessRate', 'AIANPct'};
X = [data_matrix.Density, data_matrix.ForeignBornPct, data_matrix.PovertyPct, ...
data_matrix.HIVRate, data_matrix.IncarcerationRate, data_matrix.HomelessRate, data_matrix.AIANPct];
y = data_matrix.ExcessCases;


valid_idx = ~any(isnan(X), 2) & ~isnan(y) & (X(:,6) > 0) & (X(:,7) >= 0);
X_valid = X(valid_idx, :);
y_valid = y(valid_idx);

states_valid = data_matrix.State(valid_idx);


fprintf('Valid observations: %d out of %d\n', sum(valid_idx), n_states);


if sum(valid_idx) < 10

fprintf('\nWarning: Not enough valid observations for regression.\n');
fprintf('Summary of missing data:\n');
for j = 1:length(predictor_names)
fprintf('  %s: %d missing/zero\n', predictor_names{j}, sum(isnan(X(:,j)) | X(:,j)==0));
end
return;
end

fprintf('\n=== TABLE 1: Descriptive Statistics ===\n');
fprintf('%-20s %10s %10s %10s %10s\n', 'Predictor', 'Mean', 'Median', 'Min', 'Max');
fprintf('%s\n', repmat('-', 1, 62));


predictor_descriptions = {'Pop. density (per sq mi)', 'Foreign-born (%)', ...
'Poverty rate (%)', 'HIV rate (per 100k)', 'Incarceration (per 100k)', 'Homeless (per 100k)', 'AI/AN population (%)'};
predictor_sources = {'Census ACS', 'Census ACS', 'Census ACS', 'CDC AtlasPlus', 'BJS', 'HUD AHAR', 'Census ACS'};


desc_stats = zeros(length(predictor_names), 4);
for j = 1:length(predictor_names)
desc_stats(j, 1) = mean(X_valid(:, j));
desc_stats(j, 2) = median(X_valid(:, j));
desc_stats(j, 3) = min(X_valid(:, j));
desc_stats(j, 4) = max(X_valid(:, j));
fprintf('%-20s %10.2f %10.2f %10.2f %10.2f\n', predictor_names{j}, ...
desc_stats(j,1), desc_stats(j,2), desc_stats(j,3), desc_stats(j,4));
end

fprintf('%-20s %10.2f %10.2f %10.2f %10.2f\n', 'ExcessCases', ...
mean(y_valid), median(y_valid), min(y_valid), max(y_valid));


desc_table = table(predictor_names', predictor_descriptions', ...
desc_stats(:,1), desc_stats(:,2), desc_stats(:,3), desc_stats(:,4), predictor_sources', ...
'VariableNames', {'Variable', 'Description', 'Mean', 'Median', 'Min', 'Max', 'Source'});
writetable(desc_table, fullfile(results_path, 'table_descriptive_stats.csv'));
fprintf('\nDescriptive statistics saved to: %s\n', fullfile(results_path, 'table_descriptive_stats.csv'));

fprintf('\n=== TABLE 2: Univariate Spearman Correlations ===\n');
fprintf('%-20s %12s %12s\n', 'Predictor', 'Spearman r', 'p-value');
fprintf('%s\n', repmat('-', 1, 46));

spearman_r = zeros(length(predictor_names), 1);
spearman_p = zeros(length(predictor_names), 1);
for j = 1:length(predictor_names)
[rho, pval] = corr(X_valid(:, j), y_valid, 'Type', 'Spearman');
spearman_r(j) = rho;
spearman_p(j) = pval;
sig_star = '';
if pval < 0.001
sig_star = '***';
elseif pval < 0.01
sig_star = '**';
elseif pval < 0.05
sig_star = '*';
end
fprintf('%-20s %12.3f %12.4f %s\n', predictor_names{j}, rho, pval, sig_star);
end

spearman_table = table(predictor_names', spearman_r, spearman_p, ...
'VariableNames', {'Predictor', 'Spearman_r', 'p_value'});
writetable(spearman_table, fullfile(results_path, 'table_spearman_correlations.csv'));
fprintf('\nSpearman correlations saved to: %s\n', fullfile(results_path, 'table_spearman_correlations.csv'));
fprintf('Significance: * p<0.05, ** p<0.01, *** p<0.001\n');

fprintf('\n=== Pearson Correlation Matrix ===\n');
all_vars = [X_valid, y_valid];
var_names = [predictor_names, {'ExcessCases'}];
corr_matrix = corrcoef(all_vars);


fprintf('\n');
fprintf('%20s', '');
for j = 1:length(var_names)
fprintf('%15s', var_names{j}(1:min(12,length(var_names{j}))));
end
fprintf('\n');
for i = 1:length(var_names)
fprintf('%20s', var_names{i});
for j = 1:length(var_names)
fprintf('%15.3f', corr_matrix(i,j));
end
fprintf('\n');
end


X_std = zscore(X_valid);

fprintf('\n=== Full OLS Regression ===\n');
mdl_full = fitlm(X_valid, y_valid, 'VarNames', [predictor_names, {'ExcessCases'}]);
disp(mdl_full);

fprintf('\n=== Stepwise Regression (Backward) ===\n');
mdl_backward = stepwiselm(X_valid, y_valid, 'linear', 'Upper', 'linear', 'Lower', 'constant', ...
'Criterion', 'AIC', 'VarNames', [predictor_names, {'ExcessCases'}]);
disp(mdl_backward);


fprintf('\n=== Stepwise Regression (Forward) ===\n');
mdl_forward = stepwiselm(X_valid, y_valid, 'constant', 'Upper', 'linear', 'Lower', 'constant', ...
'Criterion', 'AIC', 'VarNames', [predictor_names, {'ExcessCases'}]);
disp(mdl_forward);
if mdl_backward.Rsquared.Adjusted >= mdl_forward.Rsquared.Adjusted
mdl_step = mdl_backward;
step_method = 'Backward';
else
mdl_step = mdl_forward;
step_method = 'Forward';
end

fprintf('\n=== LASSO Regression ===\n');
[B_lasso, FitInfo] = lasso(X_std, y_valid, 'CV', 5);
lambda_min_idx = FitInfo.IndexMinMSE;
lasso_coefs = B_lasso(:, lambda_min_idx);
fprintf('LASSO Coefficients (standardized, at lambda_min):\n');
for j = 1:length(predictor_names)
fprintf('  %20s: %10.4f\n', predictor_names{j}, lasso_coefs(j));
end

fprintf('\n=== Variance Inflation Factors (VIF) ===\n');
vif_values = zeros(size(X_valid, 2), 1);
for j = 1:size(X_valid, 2)
other_idx = setdiff(1:size(X_valid,2), j);
mdl_vif = fitlm(X_valid(:, other_idx), X_valid(:, j));
r2 = mdl_vif.Rsquared.Ordinary;
vif_values(j) = 1 / (1 - r2);
fprintf('  %20s: VIF = %6.2f', predictor_names{j}, vif_values(j));
if vif_values(j) > 5
fprintf(' (High!)');
end
fprintf('\n');
end

fig1 = figure('Position', [50, 50, 800, 700], 'Color', 'w');


y_pred_step = predict(mdl_step, X_valid);
residuals = y_valid - y_pred_step;

subplot(2,2,1);
scatter(y_valid, y_pred_step, 60, [0.2 0.4 0.8], 'filled', 'MarkerEdgeColor', 'k');

hold on;
plot([0, max(y_valid)*1.1], [0, max(y_valid)*1.1], 'r--', 'LineWidth', 2);
xlabel('Estimated Excess Cases', 'FontSize', 11);

ylabel('Fitted Values', 'FontSize', 11);

title('Estimated vs Fitted', 'FontSize', 12, 'FontWeight', 'normal');
xlim([0, max(y_valid)*1.1]); ylim([0, max(y_valid)*1.1]);
text(0.05, 0.92, sprintf('Adj. R^2 = %.3f', mdl_step.Rsquared.Adjusted), ...
'Units', 'normalized', 'FontSize', 10);
axis square; grid on; box on;


subplot(2,2,2);
scatter(y_pred_step, residuals, 60, [0.2 0.4 0.8], 'filled', 'MarkerEdgeColor', 'k');
hold on;
yline(0, 'r--', 'LineWidth', 2);
xlabel('Fitted Values', 'FontSize', 11);
ylabel('Residuals', 'FontSize', 11);
title('Residuals vs Fitted', 'FontSize', 12, 'FontWeight', 'normal');
grid on; box on;

subplot(2,2,3);
qqplot(residuals);
h = findobj(gca, 'Type', 'Line');
set(h(1), 'MarkerFaceColor', [0.2 0.4 0.8], 'MarkerEdgeColor', 'k', 'MarkerSize', 6);
title('Normal Q-Q Plot', 'FontSize', 12, 'FontWeight', 'normal');
xlabel('Theoretical Quantiles', 'FontSize', 11);
ylabel('Sample Quantiles', 'FontSize', 11);
grid on; box on;

subplot(2,2,4);
histogram(residuals, 12, 'FaceColor', [0.2 0.4 0.8], 'EdgeColor', 'w');
xlabel('Residuals', 'FontSize', 11);
ylabel('Frequency', 'FontSize', 11);
title('Residual Distribution', 'FontSize', 12, 'FontWeight', 'normal');
grid on; box on;

exportgraphics(fig1, fullfile(results_path, 'regression_diagnostics.pdf'), 'ContentType', 'vector', 'Resolution', 300);


fig2 = figure('Position', [100, 100, 800, 450], 'Color', 'w');
step_coef_names = mdl_step.CoefficientNames(2:end);
step_coefs = mdl_step.Coefficients.Estimate(2:end);

step_se = mdl_step.Coefficients.SE(2:end);


step_coef_idx = zeros(length(step_coef_names), 1);
for k = 1:length(step_coef_names)
step_coef_idx(k) = find(strcmp(predictor_names, step_coef_names{k}));
end
std_coefs = step_coefs .* std(X_valid(:, step_coef_idx))';
std_se = step_se .* std(X_valid(:, step_coef_idx))';

[~, sort_idx] = sort(std_coefs, 'descend');
std_coefs = std_coefs(sort_idx);
std_se = std_se(sort_idx);
step_coef_names = step_coef_names(sort_idx);

n_coef = length(std_coefs);
y_pos = 1:n_coef;


plot_color = [0.2 0.4 0.7];

hold on;
for k = 1:n_coef
errorbar(std_coefs(k), y_pos(k), 0, 0, 1.96*std_se(k), 1.96*std_se(k), ...
'Color', plot_color, 'LineWidth', 2, 'CapSize', 8);
scatter(std_coefs(k), y_pos(k), 150, plot_color, 'filled', 'MarkerEdgeColor', 'k');
end

xline(0, 'k--', 'LineWidth', 1.5);
set(gca, 'YTick', y_pos, 'YTickLabel', step_coef_names, 'FontSize', 12);
xlabel('Standardized Coefficient (95% CI)', 'FontSize', 14);
ylim([0.5, n_coef + 0.5]);
grid on; box on;


exportgraphics(fig2, fullfile(results_path, 'regression_forest_plot.pdf'), 'ContentType', 'vector', 'Resolution', 300);


fig3 = figure('Position', [100, 100, 1200, 400], 'Color', 'w');
sig_predictors = step_coef_names;
n_sig = length(sig_predictors);
n_cols = min(n_sig, 4);
for k = 1:n_sig
subplot(1, n_cols, k);

pred_idx = find(strcmp(predictor_names, sig_predictors{k}));
x_pred = X_valid(:, pred_idx);
scatter(x_pred, y_valid, 60, [0.2 0.4 0.8], 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.7);
hold on;
p = polyfit(x_pred, y_valid, 1);
x_line = linspace(min(x_pred), max(x_pred), 100);
y_line = polyval(p, x_line);
plot(x_line, y_line, 'r-', 'LineWidth', 2);
r = corr(x_pred, y_valid);

xlabel(sig_predictors{k}, 'FontSize', 12);

ylabel('Estimated Excess Cases', 'FontSize', 12);
title(sprintf('r = %.3f', r), 'FontSize', 12, 'FontWeight', 'normal');
grid on; box on;
end
exportgraphics(fig3, fullfile(results_path, 'regression_scatterplots.pdf'), 'ContentType', 'vector', 'Resolution', 300);
fig4 = figure('Position', [100, 100, 700, 500], 'Color', 'w');

corr_with_excess = corr_matrix(1:end-1, end);

[~, sort_idx] = sort(abs(corr_with_excess), 'descend');
corr_sorted = corr_with_excess(sort_idx);
names_sorted = predictor_names(sort_idx);


y_pos = 1:length(corr_sorted);
bar_colors = zeros(length(corr_sorted), 3);
for k = 1:length(corr_sorted)
if corr_sorted(k) > 0
bar_colors(k,:) = [0.2 0.5 0.8];
else
bar_colors(k,:) = [0.8 0.3 0.2];
end
end

barh(y_pos, corr_sorted, 0.6, 'FaceColor', 'flat', 'CData', bar_colors, 'EdgeColor', 'k');
hold on;
xline(0, 'k-', 'LineWidth', 1.5);
set(gca, 'YTick', y_pos, 'YTickLabel', names_sorted, 'FontSize', 12);
xlabel('Correlation with Excess TB Cases', 'FontSize', 13, 'FontWeight', 'bold');
title('Predictor Correlations with Excess Cases (2020-2023)', 'FontSize', 14, 'FontWeight', 'bold');
xlim([-0.6, 0.6]);
grid on; box on;
for k = 1:length(corr_sorted)
if corr_sorted(k) >= 0
text(corr_sorted(k) + 0.03, y_pos(k), sprintf('%.2f', corr_sorted(k)), ...
'FontSize', 11, 'FontWeight', 'bold', 'VerticalAlignment', 'middle');
else
text(corr_sorted(k) - 0.03, y_pos(k), sprintf('%.2f', corr_sorted(k)), ...
'FontSize', 11, 'FontWeight', 'bold', 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right');
end
end
exportgraphics(fig4, fullfile(results_path, 'correlation_barchart.pdf'), 'ContentType', 'vector', 'Resolution', 300);
fprintf('\n========================================\n');
fprintf('       REGRESSION ANALYSIS SUMMARY\n');
fprintf('========================================\n');
fprintf('Total states: %d\n', n_states);
fprintf('Valid observations: %d\n', sum(valid_idx));
fprintf('\nFull Model:\n');
fprintf('  R-squared (adj): %.3f\n', mdl_full.Rsquared.Adjusted);
fprintf('  F-statistic p-value: %.4f\n', coefTest(mdl_full));
fprintf('\nStepwise Model (%s):\n', step_method);
fprintf('  R-squared (adj): %.3f\n', mdl_step.Rsquared.Adjusted);
fprintf('  F-statistic p-value: %.4f\n', coefTest(mdl_step));

fprintf('\nFinal Model Predictors:\n');
for j = 1:length(step_coef_names)
fprintf('  - %s (beta=%.3f, p=%.4f)\n', ...
mdl_step.CoefficientNames{j+1}, mdl_step.Coefficients.Estimate(j+1), mdl_step.Coefficients.pValue(j+1));
end
fprintf('\nFigures saved to: %s\n', results_path);
fprintf('========================================\n');
function cmap = redblue(m)
if nargin < 1, m = 64; end
r = [linspace(0.2, 1, m/2), ones(1, m/2)];
g = [linspace(0.2, 1, m/2), linspace(1, 0.2, m/2)];
b = [ones(1, m/2), linspace(1, 0.2, m/2)];
cmap = [r', g', b'];
end
