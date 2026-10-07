function runAllTests()
% runAllTests - jalankan seluruh unit test project dari command window.
%
%   Menjalankan semua file *Test.m di folder tests/ dan menampilkan ringkasan.
%   Cocok untuk pengecekan cepat sebelum commit.
%
%   Contoh:
%       startup
%       runAllTests

% testsDir = folder tempat file ini berada (yaitu <repo>/tests)
testsDir  = fileparts(mfilename('fullpath'));
repoRoot  = fileparts(testsDir);

addpath(genpath(fullfile(repoRoot, 'src')));
addpath(fullfile(repoRoot, 'gui'));

results = runtests(testsDir);

nPass = sum([results.Passed]);
nFail = sum([results.Failed]);
nInc  = sum([results.Incomplete]);

fprintf('\n===== RINGKASAN UNIT TEST =====\n');
fprintf('Lulus      : %d\n', nPass);
fprintf('Gagal      : %d\n', nFail);
fprintf('Tidak jalan: %d\n', nInc);

if nFail > 0 || nInc > 0
    fprintf('\nDetail kegagalan:\n');
    table(results)
end
end
