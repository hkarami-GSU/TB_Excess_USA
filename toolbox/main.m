function main(outbreakx)
commonCaddate = '01-01-2019'; 
% <============================================================================>
% <=================== Parallel Loop Over Each Outbreak Index =================>
% <============================================================================>
for i = outbreakx
    fprintf('Running analysis for outbreak %d...\n', i);
    % Call the function for the current outbreak index with the common caddate
    try
        % Here, `i` is used as the current outbreak index
        Run_Fit_subepidemicFramework(i, commonCaddate);
        % plotForecast_subepidemicFramework(i, commonCaddate, 4, 0);
        fprintf('Successfully processed outbreak %d.\n', i);
    catch ME
        fprintf('Error processing outbreak %d: %s\n', i, ME.message);
    end
end
% <============================================================================>
% <============================ End of Script =================================>
% <============================================================================>
end