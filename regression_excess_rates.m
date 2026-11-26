clear; clc; close all;


codeDir = fileparts(mfilename('fullpath')); if ~isempty(codeDir), addpath(codeDir); end
P = project_paths();
results_path = P.res;

state_abbrev_map = containers.Map(...
{'AK','AL','AR','AZ','CA','CO','CT','DE','FL','GA','HI','IA','ID','IL','IN','KS','KY','LA','MA','MD','ME','MI','MN','MO','MS','MT','NC','ND','NE','NH','NJ','NM','NV','NY','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VA','VT','WA','WI','WV','WY'}, ...
{'Alaska','Alabama','Arkansas','Arizona','California','Colorado','Connecticut','Delaware','Florida','Georgia','Hawaii','Iowa','Idaho','Illinois','Indiana','Kansas','Kentucky','Louisiana','Massachusetts','Maryland','Maine','Michigan','Minnesota','Missouri','Mississippi','Montana','North Carolina','North Dakota','Nebraska','New Hampshire','New Jersey','New Mexico','Nevada','New York','Ohio','Oklahoma','Oregon','Pennsylvania','Rhode Island','South Carolina','South Dakota','Tennessee','Texas','Utah','Virginia','Vermont','Washington','Wisconsin','West Virginia','Wyoming'});

fprintf('Loading Excess Rates data...\n');
excess_data = readtable(fullfile(P.res, 'ExcessRates_US_States.xlsx'));

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

fprintf('\nProcessing Excess RATES...\n');
excess_rates = zeros(n_states, 1);
missing_excess_rate = {};
for i = 1:n_states
state_name_no_space = strrep(state_names{i}, ' ', '');
idx = find(strcmpi(excess_data.State, state_name_no_space));
if ~isempty(idx)
rate_val = excess_data.ExcessRate_Median(idx(1));
if isnumeric(rate_val) && ~isnan(rate_val)
excess_rates(i) = rate_val;
else
excess_rates(i) = NaN;
missing_excess_rate{end+1} = state_names{i};
end
else
excess_rates(i) = NaN;
missing_excess_rate{end+1} = state_names{i};
end
end

data_matrix.ExcessRates = excess_rates;

fprintf('Excess Rates Summary:\n');
fprintf('  Mean: %.2f per 100,000\n', mean(excess_rates, 'omitnan'));
fprintf('  Median: %.2f per 100,000\n', median(excess_rates, 'omitnan'));
fprintf('  Range: %.2f - %.2f per 100,000\n', min(excess_rates), max(excess_rates));
fprintf('  States with missing excess rates: %d\n', length(missing_excess_rate));
if ~isempty(missing_excess_rate)
fprintf('    Missing: %s\n', strjoin(missing_excess_rate, ', '));
end
fprintf('\n========================================\n');
fprintf('  DATA VERIFICATION\n');
fprintf('========================================\n');
fprintf('First 10 states - Excess Rates (verify against file):\n');
for i = 1:min(10, n_states)
fprintf('  %s: %.2f per 100,000\n', data_matrix.State{i}, data_matrix.ExcessRates(i));
end

fprintf('\nFull Data Matrix Summary:\n');
disp(data_matrix);

predictor_names = {'Density', 'ForeignBornPct', 'PovertyPct', 'HIVRate', ...
'IncarcerationRate', 'HomelessRate', 'AIANPct'};

label_map = containers.Map( ...
{'Density', 'ForeignBornPct', 'PovertyPct', 'HIVRate', 'IncarcerationRate', 'HomelessRate', 'AIANPct'}, ...
{'Population density', 'Foreign-born population (%)', 'Poverty rate (%)', 'HIV prevalence', ...
'Incarceration rate', 'Homelessness rate', 'AI/AN population (%)'});

X = table2array(data_matrix(:, predictor_names));
y = data_matrix.ExcessRates;


valid_idx = ~any(isnan(X), 2) & ~isnan(y);
X_valid = X(valid_idx, :);
y_valid = y(valid_idx);


fprintf('\n========================================\n');
fprintf('  DEBUGGING: EXCLUDED STATES\n');
fprintf('========================================\n');
excluded_states = data_matrix.State(~valid_idx);
for i = 1:length(excluded_states)
state_idx = find(strcmp(data_matrix.State, excluded_states{i}));
row_data = table2array(data_matrix(state_idx, [predictor_names, {'ExcessRates'}]));
nan_cols = find(isnan(row_data));
nan_names = [predictor_names, {'ExcessRates'}];
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

fprintf('\n=== Spearman Rank Correlations with Excess Rates ===\n');
for j = 1:length(predictor_names)
[rho, pval] = corr(X_valid(:, j), y_valid, 'Type', 'Spearman');
fprintf('  %20s: rho = %7.4f, p = %.4f\n', predictor_names{j}, rho, pval);
end


fprintf('\n=== Full Linear Regression Model ===\n');

mdl_full = fitlm(X_valid, y_valid, 'VarNames', [predictor_names, {'ExcessRates'}]);
disp(mdl_full);

fprintf('\n=== Stepwise Regression (Backward) ===\n');
mdl_step = stepwiselm(X_valid, y_valid, 'linear', 'Upper', 'linear', 'Lower', 'constant', ...
'Criterion', 'AIC', 'VarNames', [predictor_names, {'ExcessRates'}]);
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
states_valid = data_matrix.State(valid_idx);
full_names = mdl_full.CoefficientNames(2:end)';
full_idx = cellfun(@(s) find(strcmp(predictor_names, s)), full_names);
s_ratio = std(X_valid(:, full_idx))' / std(y_valid);
full_std = mdl_full.Coefficients.Estimate(2:end) .* s_ratio;
full_std_se = mdl_full.Coefficients.SE(2:end) .* s_ratio;
T_full = table(full_names, cellfun(@(s) label_map(s), full_names, 'UniformOutput', false), ...
mdl_full.Coefficients.Estimate(2:end), mdl_full.Coefficients.SE(2:end), mdl_full.Coefficients.tStat(2:end), ...
mdl_full.Coefficients.pValue(2:end), full_std, full_std - 1.96*full_std_se, full_std + 1.96*full_std_se, vif_values(full_idx), ...
'VariableNames', {'predictor', 'label', 'estimate', 'se', 'tstat', 'pvalue', 'std_coef', 'std_ci_lower', 'std_ci_upper', 'vif'});
writetable(T_full, fullfile(results_path, 'full_model_RATES.csv'));
[F_p, F_stat] = coefTest(mdl_full);
writetable(table(mdl_full.NumObservations, mdl_full.Rsquared.Ordinary, mdl_full.Rsquared.Adjusted, F_stat, F_p, ...
'VariableNames', {'n', 'R2', 'adjR2', 'F', 'F_pvalue'}), fullfile(results_path, 'full_model_stats_RATES.csv'));
fprintf('\n=== Full model (all seven predictors), standardized coefficients ===\n');
disp(T_full(:, {'label', 'estimate', 'pvalue', 'std_coef', 'std_ci_lower', 'std_ci_upper', 'vif'}));

final_names = mdl_step.CoefficientNames(2:end)';
final_idx = cellfun(@(s) find(strcmp(predictor_names, s)), final_names);

Xf = X_valid(:, final_idx);
n_obs = numel(y_valid);
stud_res = mdl_step.Residuals.Studentized;
cooks_d = mdl_step.Diagnostics.CooksDistance;
lev = mdl_step.Diagnostics.Leverage;
[~, i_out] = max(abs(stud_res));
out_state = states_valid{i_out};
fprintf('\n=== Influential observations, final model ===\n');
fprintf('  Largest |studentized residual|: %s (%.2f); Cook''s distance %.3f (4/n = %.3f); leverage %.3f\n', ...
out_state, stud_res(i_out), cooks_d(i_out), 4/n_obs, lev(i_out));
for k = find(cooks_d > 4/n_obs)'
fprintf('  Cook''s distance > 4/n: %s (%.3f)\n', states_valid{k}, cooks_d(k));
end
writetable(table(states_valid, y_valid, stud_res, cooks_d, lev, ...
'VariableNames', {'State', 'ExcessRate', 'studentized_residual', 'cooks_distance', 'leverage'}), ...
fullfile(results_path, 'influence_RATES.csv'));


keep = true(n_obs, 1);

keep(i_out) = false;
mdl_wo  = fitlm(Xf(keep, :), y_valid(keep), 'VarNames', [final_names', {'ExcessRates'}]);
mdl_rob = fitlm(Xf, y_valid, 'RobustOpts', 'on', 'VarNames', [final_names', {'ExcessRates'}]);
mdl_step_wo = stepwiselm(X_valid(keep, :), y_valid(keep), 'linear', 'Upper', 'linear', 'Lower', 'constant', ...
'Criterion', 'AIC', 'VarNames', [predictor_names, {'ExcessRates'}], 'Verbose', 0);
rob_w = mdl_rob.Robust.Weights;

sens = table(final_names, cellfun(@(s) label_map(s), final_names, 'UniformOutput', false), ...
'VariableNames', {'predictor', 'label'});
fits = {mdl_step, mdl_wo, mdl_rob};
tags = {'all', 'without', 'robust'};
for m = 1:3
sr = std(Xf)' / std(y_valid);
bm = fits{m}.Coefficients.Estimate(2:end) .* sr;
sem = fits{m}.Coefficients.SE(2:end) .* sr;
sens.(['std_' tags{m}]) = bm;

sens.(['lo_' tags{m}]) = bm - 1.96*sem;
sens.(['hi_' tags{m}]) = bm + 1.96*sem;
sens.(['p_' tags{m}]) = fits{m}.Coefficients.pValue(2:end);
end
writetable(sens, fullfile(results_path, 'outlier_sensitivity_RATES.csv'));
kept_wo = strjoin(mdl_step_wo.CoefficientNames(2:end), ', ');
writetable(table({out_state}, stud_res(i_out), cooks_d(i_out), lev(i_out), mdl_step.Rsquared.Adjusted, ...
mdl_wo.Rsquared.Adjusted, rob_w(i_out), {kept_wo}, ...
'VariableNames', {'state', 'studentized_residual', 'cooks_distance', 'leverage', 'adjR2_all', ...
'adjR2_without', 'robust_weight', 'stepwise_without_keeps'}), ...
fullfile(results_path, 'outlier_sensitivity_stats_RATES.csv'));
fprintf('  Final model without %s: adj. R^2 = %.3f (all states: %.3f)\n', out_state, mdl_wo.Rsquared.Adjusted, mdl_step.Rsquared.Adjusted);
fprintf('  Robust (bisquare) fit with all states: weight of %s = %.3f\n', out_state, rob_w(i_out));
fprintf('  Stepwise selection without %s keeps: %s\n', out_state, kept_wo);

disp(sens);

fprintf('\n=== Pearson correlations in paper Fig 4 ===\n');
nf = numel(final_names);

r_all = zeros(nf, 1); p_all = r_all; r_wo = r_all; p_wo = r_all;
for k = 1:nf
[r_all(k), p_all(k)] = corr(Xf(:, k), y_valid);
[r_wo(k), p_wo(k)] = corr(Xf(keep, k), y_valid(keep));
fprintf('  %28s: r = %6.3f (p = %.3f); without %s: r = %6.3f (p = %.3f)\n', ...
label_map(final_names{k}), r_all(k), p_all(k), out_state, r_wo(k), p_wo(k));
end
writetable(table(final_names, r_all, p_all, r_wo, p_wo, ...
'VariableNames', {'predictor', 'r_all', 'p_all', 'r_without', 'p_without'}), ...
fullfile(results_path, 'scatter_correlations_RATES.csv'));

fig1 = figure('Position', [50, 50, 800, 700], 'Color', 'w');
y_pred_step = predict(mdl_step, X_valid);
residuals = y_valid - y_pred_step;

subplot(2,2,1);
scatter(y_valid, y_pred_step, 60, [0.2 0.4 0.8], 'filled', 'MarkerEdgeColor', 'k');
hold on;
plot([0, max(y_valid)*1.1], [0, max(y_valid)*1.1], 'r--', 'LineWidth', 2);
xlabel('Excess TB incidence rate (per 100,000)', 'FontSize', 11);
ylabel('Fitted Values', 'FontSize', 11);
title('Estimated vs Fitted', 'FontSize', 12, 'FontWeight', 'normal');
xlim([0, max(y_valid)*1.1]); ylim([0, max(y_valid)*1.1]);
text(0.05, 0.92, sprintf('Adj. R^2 = %.3f', mdl_step.Rsquared.Adjusted), ...
'Units', 'normalized', 'FontSize', 10);
text(y_valid(i_out), y_pred_step(i_out), [out_state '  '], 'FontSize', 10, 'HorizontalAlignment', 'right');
axis square; grid on; box on;

subplot(2,2,2);
scatter(y_pred_step, residuals, 60, [0.2 0.4 0.8], 'filled', 'MarkerEdgeColor', 'k');
hold on;
yline(0, 'r--', 'LineWidth', 2);
xlabel('Fitted Values', 'FontSize', 11);
ylabel('Residuals', 'FontSize', 11);
title('Residuals vs Fitted', 'FontSize', 12, 'FontWeight', 'normal');
text(y_pred_step(i_out), residuals(i_out), [out_state '  '], 'FontSize', 10, 'HorizontalAlignment', 'right');
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

exportgraphics(fig1, fullfile(results_path, 'regression_diagnostics_RATES.pdf'), 'ContentType', 'vector', 'Resolution', 300);


fig2 = figure('Position', [100, 100, 1000, 450], 'Color', 'w');


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
std_lo = std_coefs - 1.96*std_se;
std_hi = std_coefs + 1.96*std_se;


step_coef_labels = cellfun(@(s) label_map(s), step_coef_names, 'UniformOutput', false);
[~, wo_idx] = ismember(step_coef_names, sens.predictor);
wo_coefs = sens.std_without(wo_idx);
wo_lo = sens.lo_without(wo_idx);
wo_hi = sens.hi_without(wo_idx);


fprintf('\n=== Standardized coefficients, final model (paper Fig 3) ===\n');
for k = 1:numel(std_coefs)
fprintf('  %28s: %.3f (95%% CI %.3f to %.3f)\n', step_coef_labels{k}, std_coefs(k), std_lo(k), std_hi(k));
end
writetable(table(step_coef_names(:), step_coef_labels(:), std_coefs, std_se, std_lo, std_hi, ...
'VariableNames', {'predictor', 'label', 'std_coef', 'std_se', 'ci_lower', 'ci_upper'}), ...
fullfile(results_path, 'standardized_coefficients_RATES.csv'));

n_coef = length(std_coefs);
y_pos = 1:n_coef;


plot_color = [0.2 0.4 0.7];


ax2 = axes(fig2, 'Position', [0.20 0.15 0.77 0.78]);
hold(ax2, 'on');
for k = 1:n_coef
errorbar(ax2, std_coefs(k), y_pos(k), 0, 0, 1.96*std_se(k), 1.96*std_se(k), ...
'Color', plot_color, 'LineWidth', 2, 'CapSize', 8);
scatter(ax2, std_coefs(k), y_pos(k), 150, plot_color, 'filled', 'MarkerEdgeColor', 'k');
errorbar(ax2, wo_coefs(k), y_pos(k) - 0.25, 0, 0, wo_coefs(k) - wo_lo(k), wo_hi(k) - wo_coefs(k), 'Color', plot_color, 'LineWidth', 1, 'CapSize', 6);
scatter(ax2, wo_coefs(k), y_pos(k) - 0.25, 90, plot_color, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', plot_color, 'LineWidth', 1.5);
end


x_text = max([std_hi; wo_hi]) + 0.05;
lbl = @(v) sprintf('%.*f', 2 + (abs(v) < 0.005 && v ~= 0), v);
for k = 1:n_coef
text(ax2, x_text, y_pos(k), sprintf('%s (%s, %s)', lbl(std_coefs(k)), lbl(std_lo(k)), lbl(std_hi(k))), ...
'FontSize', 12, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
end
text(ax2, x_text, n_coef + 0.55, 'Coefficient (95% CI)', 'FontSize', 12, 'FontWeight', 'bold', ...
'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');


xline(ax2, 0, 'k--', 'LineWidth', 1.5);
x_min = min(0, floor(min([std_lo; wo_lo]) * 10) / 10);
x_max_tick = ceil(max([std_hi; wo_hi]) * 10) / 10;
set(ax2, 'YTick', y_pos, 'YTickLabel', step_coef_labels, 'FontSize', 12, ...
'XTick', x_min:0.1:x_max_tick);
xlim(ax2, [x_min - 0.02, x_text + 0.40]);
ylim(ax2, [0.5, n_coef + 0.9]);
xlabel(ax2, 'Standardized Coefficient (95% CI)', 'FontSize', 14);
ax2.XGrid = 'on'; ax2.YGrid = 'off'; box(ax2, 'on');

exportgraphics(fig2, fullfile(results_path, 'regression_forest_plot_RATES.pdf'), 'ContentType', 'vector', 'Resolution', 300);

fig3 = figure('Color', 'w');

sig_predictors = step_coef_names;
n_sig = length(sig_predictors);
set(fig3, 'Position', [100, 100, 250*n_sig, 340]);
tl = tiledlayout(fig3, 1, n_sig, 'TileSpacing', 'compact', 'Padding', 'compact');
y_top = 2*ceil(max(y_valid)/2);
xlab_map = containers.Map( ...
{'Density', 'ForeignBornPct', 'PovertyPct', 'HIVRate', 'IncarcerationRate', 'HomelessRate', 'AIANPct'}, ...
{{'Population density', '(per sq mi)'}, {'Foreign-born population', '(%)'}, {'Poverty rate', '(%)'}, ...
{'HIV prevalence', '(per 100,000)'}, {'Incarceration rate', '(per 100,000)'}, ...
{'Homelessness rate', '(per 100,000)'}, {'AI/AN population', '(%)'}});


for k = 1:n_sig
ax = nexttile(tl);
ax.FontSize = 14;
pred_idx = find(strcmp(predictor_names, sig_predictors{k}));
x_pred = X_valid(:, pred_idx);

scatter(ax, x_pred, y_valid, 50, [0.2 0.4 0.8], 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.7);
hold(ax, 'on');
p = polyfit(x_pred, y_valid, 1);
x_line = linspace(min(x_pred), max(x_pred), 100);
plot(ax, x_line, polyval(p, x_line), 'r-', 'LineWidth', 2);
p_wo = polyfit(x_pred(keep), y_valid(keep), 1);
x_line_wo = linspace(min(x_pred(keep)), max(x_pred(keep)), 100);
plot(ax, x_line_wo, polyval(p_wo, x_line_wo), 'r--', 'LineWidth', 1.5);

if x_pred(i_out) > mean([min(x_pred), max(x_pred)])
text(ax, x_pred(i_out), y_valid(i_out), [out_state '  '], 'FontSize', 13, 'HorizontalAlignment', 'right');
else
text(ax, x_pred(i_out), y_valid(i_out), ['  ' out_state], 'FontSize', 13, 'HorizontalAlignment', 'left');
end
r = corr(x_pred, y_valid);


xlabel(ax, xlab_map(sig_predictors{k}), 'FontSize', 15);
if k == 1
ylabel(ax, {'Excess TB incidence rate', ['(per 100,000, 2020' char(8211) '2023)']}, 'FontSize', 15);
else
ax.YTickLabel = [];
end
ylim(ax, [0 y_top]);
title(ax, sprintf('r = %.3f', r), 'FontSize', 15, 'FontWeight', 'normal');
grid(ax, 'on'); box(ax, 'on');
end
exportgraphics(fig3, fullfile(results_path, 'regression_scatterplots_RATES.pdf'), 'ContentType', 'vector', 'Resolution', 300);
fprintf('\n========================================\n');
fprintf('  REGRESSION ANALYSIS SUMMARY (RATES)\n');
fprintf('========================================\n');
fprintf('Total states: %d\n', n_states);
fprintf('Valid observations: %d\n', sum(valid_idx));
fprintf('\nFull Model:\n');
fprintf('  R-squared (adj): %.3f\n', mdl_full.Rsquared.Adjusted);
fprintf('\nStepwise Model (%s):\n', step_method);
fprintf('  R-squared (adj): %.3f\n', mdl_step.Rsquared.Adjusted);
fprintf('\nFinal Model Predictors:\n');
for j = 1:length(step_coef_names)
cidx = find(strcmp(mdl_step.CoefficientNames, step_coef_names{j}));
fprintf('  - %s (beta=%.4g, p=%.4f)\n', ...
step_coef_names{j}, mdl_step.Coefficients.Estimate(cidx), mdl_step.Coefficients.pValue(cidx));
end
fprintf('\nFigures saved to: %s\n', results_path);
fprintf('========================================\n');
