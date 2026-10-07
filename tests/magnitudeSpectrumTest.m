classdef magnitudeSpectrumTest < matlab.unittest.TestCase
    methods (Test)
        function constantImageHasCenteredPeak(testCase)
            s = magnitudeSpectrum(ones(5, 7, 'uint8'));
            testCase.verifySize(s, [5 7]);
            testCase.verifyEqual(s(3, 4), log1p(35), 'AbsTol', 1e-10);
            testCase.verifyLessThan(max(abs(s([1:2 4:5], :)), [], 'all'), 1e-10);
        end

        function rgbUsesAveragedChannels(testCase)
            img = cat(3, ones(4, 6), zeros(4, 6), 2 * ones(4, 6));
            testCase.verifyEqual(magnitudeSpectrum(img), ...
                magnitudeSpectrum(ones(4, 6)), 'AbsTol', 1e-10);
        end

        function invalidChannelsRejected(testCase)
            testCase.verifyError(@() magnitudeSpectrum(ones(3, 4, 2)), ...
                'magnitudeSpectrum:channels');
        end
    end
end
