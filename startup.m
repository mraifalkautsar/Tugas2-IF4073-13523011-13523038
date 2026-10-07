function startup()
% Add only Tugas 2 code to the MATLAB path; never add legacy/.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'gui'));
addpath(fullfile(root, 'src', 'frequency'));
addpath(fullfile(root, 'src', 'restoration'));
addpath(fullfile(root, 'src', 'utils'));
addpath(fullfile(root, 'tests'));
end
