classdef tempProcessTest < matlab.unittest.TestCase
% tempProcessTest - folder hasil antara: penamaan otomatis, daftar, dan pengosongan.
% Berjalan di folder sementara karena tempProcess memakai path relatif dataset/tempProcess.

    properties
        Sandbox
        OrigDir
    end

    methods (TestMethodSetup)
        function setup(testCase)
            repoRoot = fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(repoRoot, 'gui'));

            testCase.OrigDir = pwd;
            testCase.Sandbox = tempname;
            mkdir(testCase.Sandbox);
            cd(testCase.Sandbox);
            testCase.addTeardown(@() cd(testCase.OrigDir));
            testCase.addTeardown(@() rmdir(testCase.Sandbox, 's'));
        end
    end

    methods (Test)
        function listIsEmptyWhenFolderMissing(testCase)
            testCase.verifyEqual(tempProcess('list'), {});
        end

        function saveCreatesFolderAndNumbersFromOne(testCase)
            name = tempProcess('save', uint8(magic(4)));
            testCase.verifyEqual(name, 'proc_001.png');
            testCase.verifyTrue(isfile(fullfile('dataset', 'tempProcess', name)));
        end

        function saveNeverOverwrites(testCase)
            tempProcess('save', zeros(4, 'uint8'));
            tempProcess('save', zeros(4, 'uint8'));
            testCase.verifyEqual(tempProcess('list'), {'proc_001.png', 'proc_002.png'});
        end

        function numberingContinuesAfterGap(testCase)
            tempProcess('save', zeros(4, 'uint8'));
            tempProcess('save', zeros(4, 'uint8'));
            delete(fullfile('dataset', 'tempProcess', 'proc_001.png'));
            testCase.verifyEqual(tempProcess('save', zeros(4, 'uint8')), 'proc_003.png');
        end

        function saveIsLossless(testCase)
            img = uint8(randi(255, 8, 8, 3));
            name = tempProcess('save', img);
            testCase.verifyEqual(imread(fullfile('dataset', 'tempProcess', name)), img);
        end

        function clearDeletesOnlyPngInFolder(testCase)
            tempProcess('save', zeros(4, 'uint8'));
            other = fullfile('dataset', 'tempProcess', 'catatan.txt');
            fclose(fopen(other, 'w'));
            n = tempProcess('clear');
            testCase.verifyEqual(n, 1);
            testCase.verifyEqual(tempProcess('list'), {});
            testCase.verifyTrue(isfile(other));
        end

        function saveRejectsNonUint8(testCase)
            testCase.verifyError(@() tempProcess('save', zeros(4)), 'MATLAB:tempProcess:invalidType');
        end
    end
end
