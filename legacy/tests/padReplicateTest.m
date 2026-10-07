classdef padReplicateTest < matlab.unittest.TestCase
% padReplicateTest - memastikan padReplicate identik dengan padding replikasi
% referensi (padarray bawaan toolbox, hanya dipakai sebagai pembanding).

    properties
        RepoRoot
    end

    methods (TestMethodSetup)
        function addPaths(testCase)
            testCase.RepoRoot = 'C:\DATA\Projects\Tugas1-IF4073-CitraDigital-13523104';
            addpath(genpath(fullfile(testCase.RepoRoot, 'src')));
        end
    end

    methods (Test)
        function matchesPadarrayReplicate(testCase)
            rng(20260928);
            for trial = 1:40
                h = randi([1 20]); w = randi([1 20]);
                img = uint8(randi([0 255], h, w));
                pr = randi([0 4]); pc = randi([0 4]);

                mine = padReplicate(double(img), pr, pc);
                ref  = double(padarray(img, [pr pc], 'replicate'));

                testCase.verifySize(mine, size(ref));
                testCase.verifyEqual(mine, ref);
            end
        end

        function symmetricCaseMatches(testCase)
            img = uint8(randi([0 255], 9, 9));
            testCase.verifyEqual(padReplicate(double(img), 2, 2), ...
                                 double(padarray(img, [2 2], 'replicate')));
        end

        function rectangularCaseMatches(testCase)
            img = uint8(randi([0 255], 6, 11));
            testCase.verifyEqual(padReplicate(double(img), 3, 1), ...
                                 double(padarray(img, [3 1], 'replicate')));
        end

        function zeroPaddingIsIdentity(testCase)
            img = uint8(randi([0 255], 5, 7));
            mine = padReplicate(double(img), 0, 0);
            testCase.verifySize(mine, size(img));
            testCase.verifyEqual(mine, double(img));
        end

        function returnsDoubleClass(testCase)
            out = padReplicate(uint8(ones(4, 4)), 1, 1);
            testCase.verifyClass(out, 'double');
        end

        function constantImageStaysConstant(testCase)
            img = uint8(200 * ones(4, 4));
            mine = padReplicate(double(img), 2, 2);
            testCase.verifyEqual(unique(mine(:)), 200);
        end
    end
end
