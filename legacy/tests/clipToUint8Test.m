classdef clipToUint8Test < matlab.unittest.TestCase
% clipToUint8Test - memastikan pembulatan dan pemangkasan nilai benar.

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
        function clipsBelowAndAbove(testCase)
            out = clipToUint8([-50 0 0.4 255 300]);
            testCase.verifyEqual(out, uint8([0 0 0 255 255]));
        end

        function roundsHalfUp(testCase)
            out = clipToUint8([0.5 1.5 2.5 127.4 127.5]);
            testCase.verifyEqual(out, uint8([1 2 3 127 128]));
        end

        function returnsUint8(testCase)
            testCase.verifyClass(clipToUint8([1 2 3]), 'uint8');
        end

        function preservesShape(testCase)
            in = reshape(1:12, [3 4]);
            testCase.verifySize(clipToUint8(in), [3 4]);
        end

        function inRangeValuesUnchanged(testCase)
            rng(1);
            v = randi([0 255], 1, 50);
            testCase.verifyEqual(clipToUint8(double(v)), uint8(v));
        end
    end
end
