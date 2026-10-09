classdef radialFilterTest < matlab.unittest.TestCase
    methods (Test)
        function maskFormulasAtCenterAndCutoff(testCase)
            img = uint8(zeros(9, 11));
            for family = {'Ideal', 'Gaussian', 'Butterworth'}
                [~, low] = radialFilter(img, 'low', family{1}, 2, 2);
                [~, high] = radialFilter(img, 'high', family{1}, 2, 2);
                testCase.verifyEqual(low + high, ones(9, 11), 'AbsTol', 1e-12);
                testCase.verifyEqual(low(5, 6), 1);
                testCase.verifyEqual(high(5, 6), 0);
                testCase.verifyEqual(low(5, 8), expected(family{1}), 'AbsTol', 1e-12);
            end
        end

        function constantInputPreservesDCAndHighPassIsZero(testCase)
            img = uint8(127 * ones(7, 10));
            for family = {'Ideal', 'Gaussian', 'Butterworth'}
                low = radialFilter(img, 'low', family{1}, 3, 2);
                high = radialFilter(img, 'high', family{1}, 3, 2);
                testCase.verifyEqual(low, im2double(img), 'AbsTol', 1e-12);
                testCase.verifyLessThan(max(abs(high(:))), 1e-12);
            end
        end

        function rgbIsFilteredPerChannelWithoutChangingDimensions(testCase)
            img = uint8(randi([0 255], 8, 7, 3));
            for pass = {'low', 'high'}
                for family = {'Ideal', 'Gaussian', 'Butterworth'}
                    [out, H, before, after] = radialFilter(img, pass{1}, family{1}, 2, 3);
                    testCase.verifySize(out, size(img));
                    testCase.verifySize(H, [8 7]);
                    testCase.verifySize(before, [8 7]);
                    testCase.verifySize(after, [8 7]);
                    for c = 1:3
                        expectedChannel = radialFilter(img(:, :, c), pass{1}, family{1}, 2, 3);
                        testCase.verifyEqual(out(:, :, c), expectedChannel, 'AbsTol', 1e-12);
                    end
                end
            end
        end

        function rawHighPassIsComplementOfLowPass(testCase)
            img = uint8(randi([0 255], 7, 8));
            low = radialFilter(img, 'low', 'Gaussian', 2);
            high = radialFilter(img, 'high', 'Gaussian', 2);
            testCase.verifyEqual(low + high, im2double(img), 'AbsTol', 1e-12);
        end

        function rejectsBadParameters(testCase)
            testCase.verifyError(@() radialFilter(zeros(5), 'low', 'Ideal', 0), ...
                'MATLAB:radialFilter:expectedPositive');
            testCase.verifyError(@() radialFilter(zeros(5), 'low', 'Butterworth', 2, 1.5), ...
                'MATLAB:radialFilter:expectedInteger');
            testCase.verifyError(@() radialFilter(zeros(5, 5, 2), 'low', 'Ideal', 2), ...
                'radialFilter:channels');
            testCase.verifyError(@() radialFilter(zeros(5), 'low', 'Unknown', 2), ...
                'radialFilter:family');
        end
    end
end

function value = expected(family)
switch family
    case 'Ideal', value = 1;
    case 'Gaussian', value = exp(-0.5);
    case 'Butterworth', value = 0.5;
end
end
