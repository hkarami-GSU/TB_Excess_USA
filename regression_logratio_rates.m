clear; clc; close all;

codeDir = fileparts(mfilename('fullpath')); if ~isempty(codeDir), addpath(codeDir); end

P = project_paths();
results_path = P.res;
state_abbrev_map = containers.Map(...
{'AK','AL','AR','AZ','CA','CO','CT','DE','FL','GA','HI','IA','ID','IL','IN','KS','KY','LA','MA','MD','ME','MI','MN','MO','MS','MT','NC','ND','NE','NH','NJ','NM','NV','NY','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VA','VT','WA','WI','WV','WY'}, ...
{'Alaska','Alabama','Arkansas','Arizona','California','Colorado','Connecticut','Delaware','Florida','Georgia','Hawaii','Iowa','Idaho','Illinois','Indiana','Kansas','Kentucky','Louisiana','Massachusetts','Maryland','Maine','Michigan','Minnesota','Missouri','Mississippi','Montana','North Carolina','North Dakota','Nebraska','New Hampshire','New Jersey','New Mexico','Nevada','New York','Ohio','Oklahoma','Oregon','Pennsylvania','Rhode Island','South Carolina','South Dakota','Tennessee','Texas','Utah','Virginia','Vermont','Washington','Wisconsin','West Virginia','Wyoming'});

fprintf('Loading log(Observed/Expected) rates data...\n');
logratio_data = readtable(fullfile(P.res, 'LogRatioRates_US_States.xlsx'));
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
'Colorado', 'Connecticut', 'Delaware', 'Florida', ...
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

fprintf('\nProcessing log(Observed/Expected) RATES...\n');
logratio_rates = zeros(n_states, 1);
missing_logratio_rate = {};
logratio_state_keys = cellfun(@normalizeStateKey, cellstr(string(logratio_data.State)), 'UniformOutput', false);

for i = 1:n_states
state_key = normalizeStateKey(state_names{i});
idx = find(strcmpi(logratio_state_keys, state_key));
if ~isempty(idx)
rate_val = logratio_data.LogRatio_Total_2020_2023_Median(idx(1));
if isnumeric(rate_val) && isfinite(rate_val)
logratio_rates(i) = rate_val;
else
logratio_rates(i) = NaN;
missing_logratio_rate{end+1} = state_names{i};
end
else
logratio_rates(i) = NaN;

missing_logratio_rate{end+1} = state_names{i};
end

end
data_matrix.LogRatioOE = logratio_rates;


fprintf('log(O/E) Rates Summary:\n');
fprintf('  Mean: %.3f\n', mean(logratio_rates, 'omitnan'));
fprintf('  Median: %.3f\n', median(logratio_rates, 'omitnan'));
fprintf('  Range: %.3f - %.3f\n', min(logratio_rates), max(logratio_rates));
fprintf('  States with missing log(O/E) rates: %d\n', length(missing_logratio_rate));
if ~isempty(missing_logratio_rate)
fprintf('    Missing: %s\n', strjoin(missing_logratio_rate, ', '));
end

fprintf('\n========================================\n');
fprintf('  DATA VERIFICATION\n');
fprintf('========================================\n');
fprintf('First 10 states - log(O/E) rates (verify against file):\n');

for i = 1:min(10, n_states)
fprintf('  %s: %.3f\n', data_matrix.State{i}, data_matrix.LogRatioOE(i));
end

fprintf('\nFull Data Matrix Summary:\n');
disp(data_matrix);
writetable(data_matrix, fullfile(results_path, 'merged_regression_data_LOGRATIO_RATES.csv'));

predictor_names = {'Density', 'ForeignBornPct', 'PovertyPct', 'HIVRate', ...
'IncarcerationRate', 'HomelessRate', 'AIANPct'};


X = table2array(data_matrix(:, predictor_names));
y = data_matrix.LogRatioOE;

valid_idx = ~any(isnan(X), 2) & ~isnan(y);
X_valid = X(valid_idx, :);
y_valid = y(valid_idx);

fprintf('\n========================================\n');
fprintf('  DEBUGGING: EXCLUDED STATES\n');

fprintf('========================================\n');
excluded_states = data_matrix.State(~valid_idx);
for i = 1:length(excluded_states)
state_idx = find(strcmp(data_matrix.State, excluded_states{i}));

row_data = table2array(data_matrix(state_idx, [predictor_names, {'LogRatioOE'}]));
nan_cols = find(isnan(row_data));
nan_names = [predictor_names, {'LogRatioOE'}];
fprintf('%s: Missing %s\n', excluded_states{i}, strjoin(nan_names(nan_cols), ', '));
end


fprintf('\n========================================\n');
fprintf('  REGRESSION DATA PREPARATION\n');
fprintf('========================================\n');
fprintf('Total states: %d\n', n_states);
fprintf('Valid observations: %d\n', sum(valid_idx));
fprintf('States excluded (missing data): %d\n', n_states - sum(valid_idx));
fprintf('Excluded states: %s\n', strjoin(excluded_states, ', '));
corr_matrix = corrcoef([X_valid, y_valid]);

fprintf('\n=== Spearman Rank Correlations with log(O/E) Rates ===\n');
spearman_r = zeros(length(predictor_names), 1);
spearman_p = zeros(length(predictor_names), 1);

for j = 1:length(predictor_names)

[rho, pval] = corr(X_valid(:, j), y_valid, 'Type', 'Spearman');
spearman_r(j) = rho;
spearman_p(j) = pval;
fprintf('  %20s: rho = %7.4f, p = %.4f\n', predictor_names{j}, rho, pval);
end

spearman_table = table(predictor_names', spearman_r, spearman_p, ...
'VariableNames', {'Predictor', 'Spearman_r', 'p_value'});
writetable(spearman_table, fullfile(results_path, 'table_spearman_correlations_LOGRATIO_RATES.csv'));


fprintf('\n=== Full Linear Regression Model ===\n');
mdl_full = fitlm(X_valid, y_valid, 'VarNames', [predictor_names, {'LogRatioOE'}]);
disp(mdl_full);
coef_full = mdl_full.Coefficients;
coef_full.predictor = coef_full.Properties.RowNames;
writetable(coef_full(:, {'predictor', 'Estimate', 'SE', 'tStat', 'pValue'}), ...
fullfile(results_path, 'model_coefficients_full_LOGRATIO_RATES.csv'));

fprintf('\n=== Stepwise Regression (Backward) ===\n');
mdl_step = stepwiselm(X_valid, y_valid, 'linear', 'Upper', 'linear', 'Lower', 'constant', ...
'Criterion', 'AIC', 'VarNames', [predictor_names, {'LogRatioOE'}]);
step_method = 'Backward';
disp(mdl_step);
fprintf('\n=== Variance Inflation Factors (VIF) ===\n');
vif_values = zeros(size(X_valid, 2), 1);
for j = 1:size(X_valid, 2)
other_idx = setdiff(1:size(X_valid,2), j);
mdl_vif = fitlm(X_valid(:, other_idx), X_valid(:, j));
r2 = mdl_vif.Rsquared.Ordinary;

vif_values(j) = 1 / (1 - r2);
fprintf('  %20s: VIF = %6.2f', predictor_names{j}, vif_values(j));
if vif_values(j) > 3
fprintf(' (High!)');
end
fprintf('\n');
end
vif_table = table(predictor_names', vif_values, 'VariableNames', {'Predictor', 'VIF'});
writetable(vif_table, fullfile(results_path, 'table_vif_LOGRATIO_RATES.csv'));

full_model_stats = table(mdl_full.Rsquared.Ordinary, mdl_full.Rsquared.Adjusted, ...
coefTest(mdl_full), mdl_full.ModelCriterion.AIC, mdl_full.NumObservations, ...
'VariableNames', {'R2', 'Adjusted_R2', 'F_p_value', 'AIC', 'N'});
step_model_stats = table(mdl_step.Rsquared.Ordinary, mdl_step.Rsquared.Adjusted, ...
coefTest(mdl_step), mdl_step.ModelCriterion.AIC, mdl_step.NumObservations, ...
'VariableNames', {'R2', 'Adjusted_R2', 'F_p_value', 'AIC', 'N'});
writetable(full_model_stats, fullfile(results_path, 'model_stats_full_LOGRATIO_RATES.csv'));
writetable(step_model_stats, fullfile(results_path, 'model_stats_stepwise_LOGRATIO_RATES.csv'));

coef_table = mdl_step.Coefficients;
coef_table.Predictor = coef_table.Properties.RowNames;
coef_table = movevars(coef_table, 'Predictor', 'Before', 1);
writetable(coef_table, fullfile(results_path, 'model_coefficients_stepwise_LOGRATIO_RATES.csv'));

fig1 = figure('Position', [50, 50, 800, 700], 'Color', 'w');

y_pred_step = predict(mdl_step, X_valid);
residuals = y_valid - y_pred_step;
subplot(2,2,1);
scatter(y_valid, y_pred_step, 60, [0.2 0.4 0.8], 'filled', 'MarkerEdgeColor', 'k');
hold on;
axis_min = min([y_valid; y_pred_step]);
axis_max = max([y_valid; y_pred_step]);
pad = 0.08 * max(axis_max - axis_min, eps);
axis_limits = [axis_min - pad, axis_max + pad];
plot(axis_limits, axis_limits, 'r--', 'LineWidth', 2);
xlabel('Estimated log(O/E)', 'FontSize', 11);
ylabel('Fitted Values', 'FontSize', 11);
title('Estimated vs Fitted', 'FontSize', 12, 'FontWeight', 'normal');
xlim(axis_limits); ylim(axis_limits);
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

exportgraphics(fig1, fullfile(results_path, 'regression_diagnostics_LOGRATIO_RATES.pdf'), 'ContentType', 'vector', 'Resolution', 300);

if mdl_step.NumCoefficients > 1
fig2 = figure('Position', [100, 100, 800, 450], 'Color', 'w');

step_coef_names = mdl_step.CoefficientNames(2:end);
step_coefs = mdl_step.Coefficients.Estimate(2:end);
step_se = mdl_step.Coefficients.SE(2:end);

step_coef_idx = zeros(length(step_coef_names), 1);
for k = 1:length(step_coef_names)
step_coef_idx(k) = find(strcmp(predictor_names, step_coef_names{k}));
end

sd_y = std(y_valid);
std_coefs = step_coefs .* std(X_valid(:, step_coef_idx))' / sd_y;
std_se = step_se .* std(X_valid(:, step_coef_idx))' / sd_y;

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

exportgraphics(fig2, fullfile(results_path, 'regression_forest_plot_LOGRATIO_RATES.pdf'), 'ContentType', 'vector', 'Resolution', 300);


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
ylabel('Estimated log(O/E)', 'FontSize', 12);
title(sprintf('r = %.3f', r), 'FontSize', 12, 'FontWeight', 'normal');
grid on; box on;
end
exportgraphics(fig3, fullfile(results_path, 'regression_scatterplots_LOGRATIO_RATES.pdf'), 'ContentType', 'vector', 'Resolution', 300);
else
fprintf(2, ['\nThe stepwise log(O/E) model kept no predictor (intercept only): forest plot and scatter plots\n' ...
'are not drawn. Any regression_forest_plot_LOGRATIO_RATES.pdf / regression_scatterplots_LOGRATIO_RATES.pdf\n' ...
'in %s are from an earlier run.\n'], results_path);
end

fprintf('\n========================================\n');
fprintf('  REGRESSION ANALYSIS SUMMARY (LOG O/E RATES)\n');
fprintf('========================================\n');
fprintf('Total states: %d\n', n_states);
fprintf('Valid observations: %d\n', sum(valid_idx));
fprintf('\nFull Model:\n');
fprintf('  R-squared (adj): %.3f\n', mdl_full.Rsquared.Adjusted);

fprintf('\nStepwise Model (%s):\n', step_method);
fprintf('  R-squared (adj): %.3f\n', mdl_step.Rsquared.Adjusted);
fprintf('\nFinal Model Predictors:\n');
for j = 2:length(mdl_step.CoefficientNames)
fprintf('  - %s (beta=%.3f, p=%.4f)\n', ...
mdl_step.CoefficientNames{j}, mdl_step.Coefficients.Estimate(j), mdl_step.Coefficients.pValue(j));
end
fprintf('\nFigures saved to: %s\n', results_path);
fprintf('========================================\n');

function key = normalizeStateKey(stateName)
key = lower(regexprep(char(string(stateName)), '[\s_]', ''));
end
