function P = project_paths()

root = fileparts(mfilename('fullpath'));
P.toolbox = fullfile(root, 'toolbox');
P.out_states_cases = fullfile(root, 'output', 'states');
P.out_age = fullfile(root, 'output', 'age');
P.out_race = fullfile(root, 'output', 'race');
P.tb_states = fullfile(root, 'data', 'states');
P.tb_age = fullfile(root, 'data', 'age');
P.tb_race = fullfile(root, 'data', 'race');
P.pred = fullfile(root, 'data', 'predictors');
P.pop = fullfile(root, 'data', 'population');

P.res = fullfile(root, 'results');
if ~exist(P.res, 'dir'), mkdir(P.res); end
end
