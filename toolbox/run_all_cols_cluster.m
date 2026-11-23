function run_all_cols_cluster(task_id)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CLUSTER VERSION - Processes a single column based on SLURM_ARRAY_TASK_ID
% Usage: matlab -r 'run_all_cols_cluster($SLURM_ARRAY_TASK_ID)'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ATTENTION: SETTING OPTIONS
data_file = "input/Cases_Wide.xlsx";
outbreakx = task_id; % Use the SLURM array task ID as column index

% All below values: The same as what is set in the option file
calibrationperiod = 10; 
caddatecommon = '01-01-2019';
cadregion = 'USA';
caddisease = 'tuberculosis';
datatype = 'cases';
DT = 365;
forecastingperiod = 4;
weight_type = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN CODE
fprintf('Processing column %d\n', outbreakx);

data = xlsread(data_file);
fprintf('Data size: %d rows x %d columns\n', size(data, 1), size(data, 2));
trimmed_data = data(1:calibrationperiod, :);
dateobj = datetime(caddatecommon, 'InputFormat', 'MM-dd-yyyy');

if DT == 1
    freq = 'daily';
elseif DT == 7
    freq = 'weekly';
elseif DT == 365
    freq = 'yearly';
else
    freq = 'custom';
end

filename = sprintf('input/%s-%s-%s-%s-%s-col%d', ...
    freq, caddisease, datatype, cadregion, datestr(dateobj, 'mm-dd-yyyy'), outbreakx);

txt_filename = strcat(filename, '.txt');
writematrix(trimmed_data, txt_filename, 'Delimiter', '\t');

% Fitting step
try
    Run_Fit_subepidemicFramework(outbreakx, caddatecommon);
    fprintf('Fit completed for column %d\n', outbreakx);
catch ME
    fprintf('Error at outbreakx = %d during fitting: %s\n', outbreakx, ME.message);
end

% Forecasting step
delete(txt_filename);
writematrix(data, txt_filename, 'Delimiter', '\t');

try
    plotForecast_subepidemicFramework(outbreakx, caddatecommon, ...
        forecastingperiod, weight_type);
    fprintf('Forecast completed for column %d\n', outbreakx);
catch ME
    fprintf('Error at outbreakx = %d during forecasting: %s\n', outbreakx, ME.message);
end

fprintf('Column %d processing complete.\n', outbreakx);
quit;
end
