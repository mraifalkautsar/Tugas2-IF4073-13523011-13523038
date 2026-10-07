function startup()
% Script otomatis biar semua folder kebaca

root = fileparts(mfilename('fullpath'));

addpath(genpath(fullfile(root, 'src')));       % Implementasi teknik enhancement
addpath(fullfile(root, 'gui'));                % Pembantu GUI
addpath(fullfile(root, 'scripts'));            % Skrip eksplorasi & validasi
addpath(genpath(fullfile(root, 'tests')));     % Unit test
addpath(fullfile(root, 'config'));             % Registrasi kasus (jika ada)

cd(root);
end
