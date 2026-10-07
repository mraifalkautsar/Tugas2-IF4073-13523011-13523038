classdef imageArithmeticTest < matlab.unittest.TestCase
% imageArithmeticTest - memastikan tambah/kurang citra benar dan aman dari overflow.

    methods (TestMethodSetup)
        function setup(~)
            repoRoot = fileparts(fileparts(mfilename('fullpath')));
            addpath(genpath(fullfile(repoRoot, 'src')));
        end
    end

    methods (Test)
        function addMatchesManualSum(testCase)
            a = uint8([10 20; 30 40]);
            b = uint8([1 2; 3 4]);
            testCase.verifyEqual(imageArithmetic(a, b, 'add'), uint8([11 22; 33 44]));
        end

        function subtractMatchesManualDifference(testCase)
            a = uint8([10 20; 30 40]);
            b = uint8([1 2; 3 4]);
            testCase.verifyEqual(imageArithmetic(a, b, 'subtract'), uint8([9 18; 27 36]));
        end

        function reverseIsOperandMinusImage(testCase)
            a = uint8([1 2; 3 4]);
            b = uint8([10 20; 30 40]);
            testCase.verifyEqual(imageArithmetic(a, b, 'reverse'), uint8([9 18; 27 36]));
        end

        function negativeIsClippedToZero(testCase)
            a = uint8([5 100]);
            b = uint8([50 10]);
            testCase.verifyEqual(imageArithmetic(a, b, 'subtract'), uint8([0 90]));
        end

        function overflowIsClippedTo255(testCase)
            a = uint8([200 10]);
            b = uint8([100 10]);
            testCase.verifyEqual(imageArithmetic(a, b, 'add'), uint8([255 20]));
        end

        function worksOnRgb(testCase)
            a = uint8(200 * ones(2, 2, 3));
            b = uint8(50 * ones(2, 2, 3));
            out = imageArithmetic(a, b, 'subtract');
            testCase.verifyEqual(out, uint8(150 * ones(2, 2, 3)));
            testCase.verifyClass(out, 'uint8');
        end

        function differentSizeThrows(testCase)
            testCase.verifyError(@() imageArithmetic(zeros(2, 2, 'uint8'), zeros(3, 3, 'uint8'), 'add'), ...
                'imageArithmetic:ukuranBeda');
        end

        function grayVsRgbThrows(testCase)
            testCase.verifyError(@() imageArithmetic(zeros(2, 2, 'uint8'), zeros(2, 2, 3, 'uint8'), 'add'), ...
                'imageArithmetic:kanalBeda');
        end

        function unknownOperationThrows(testCase)
            testCase.verifyError(@() imageArithmetic(zeros(2, 2, 'uint8'), zeros(2, 2, 'uint8'), 'kali'), ...
                'imageArithmetic:operasiTidakDikenal');
        end
    end
end
