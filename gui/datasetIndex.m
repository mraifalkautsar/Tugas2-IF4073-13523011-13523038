function index = datasetIndex(rootFolder)
%DATASETINDEX Index input/reference images for each of the five sections.
% Missing dataset/section folders return empty lists so the GUI still opens.
if nargin < 1 || isempty(rootFolder)
    rootFolder = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'dataset');
end

folders = { ...
    'B_smoothing_blurring_frequency', ...
    'C_high_pass_filtering_frequency', ...
    'D_brightness_frequency', ...
    'E_periodic_noise_restoration', ...
    'F_motion_blur_restoration'};

index = repmat(struct('section', '', 'folder', '', 'input', {{}}, ...
    'reference', {{}}), 1, numel(folders));
for k = 1:numel(folders)
    index(k).section = char('A' + k); % B, C, D, E, F
    index(k).folder = fullfile(rootFolder, folders{k});
    index(k).input = imagePaths(fullfile(index(k).folder, 'input'));
    index(k).reference = imagePaths(fullfile(index(k).folder, 'reference'));
end
end

function paths = imagePaths(folder)
paths = {};
if ~isfolder(folder)
    return;
end
entries = dir(folder);
entries = entries(~[entries.isdir]);
names = {entries.name};
valid = false(size(names));
for k = 1:numel(names)
    [~, ~, ext] = fileparts(names{k});
    valid(k) = any(strcmpi(ext, {'.png', '.jpg', '.jpeg', '.bmp', '.tif', '.tiff'}));
end
names = sort(names(valid));
paths = cellfun(@(name) fullfile(folder, name), names, 'UniformOutput', false);
end
