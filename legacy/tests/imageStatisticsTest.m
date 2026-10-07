classdef imageStatisticsTest < matlab.unittest.TestCase
% imageStatisticsTest - memastikan fitur analisis cocok dengan hitungan langsung.

    properties
        RepoRoot
        Dataset
    end

    methods (TestMethodSetup)
        function addPaths(testCase)
            testCase.RepoRoot = 'C:\DATA\Projects\Tugas1-IF4073-CitraDigital-13523104';
            addpath(genpath(fullfile(testCase.RepoRoot, 'src')));
            addpath(fullfile(testCase.RepoRoot, 'gui'));
            testCase.Dataset = fullfile(testCase.RepoRoot, 'dataset');
        end
    end

    methods (Test)
        function grayscaleMatchesDirectComputation(testCase)
            img = imread(fullfile(testCase.Dataset, '5. Kasus 4', 'image_01.png'));
            s = imageStatistics(img);

            testCase.verifyFalse(s.isColor);
            testCase.verifyEmpty(s.channels);

            testCase.verifyEqual(s.grayscale.min, double(min(img(:))));
            testCase.verifyEqual(s.grayscale.max, double(max(img(:))));
            testCase.verifyEqual(s.grayscale.mean, mean(double(img(:))), 'AbsTol', 1e-9);
            testCase.verifyEqual(s.grayscale.std, std(double(img(:)), 1), 'AbsTol', 1e-9);
        end

        function colorMatchesDirectComputation(testCase)
            img = imread(fullfile(testCase.Dataset, '2. Kasus 1', 'image_01.png'));
            s = imageStatistics(img);

            testCase.verifyTrue(s.isColor);
            testCase.verifyNumElements(s.channels, 3);

            gray = rgb2gray(img);
            testCase.verifyEqual(s.grayscale.min, double(min(gray(:))));
            testCase.verifyEqual(s.grayscale.max, double(max(gray(:))));
            testCase.verifyEqual(s.grayscale.mean, mean(double(gray(:))), 'AbsTol', 1e-9);
        end

        function perChannelMinMaxCorrect(testCase)
            img = imread(fullfile(testCase.Dataset, '2. Kasus 1', 'image_01.png'));
            s = imageStatistics(img);

            for k = 1:3
                ch = img(:,:,k);
                testCase.verifyEqual(s.channels(k).min, double(min(ch(:))), ...
                    sprintf('kanal %d min salah', k));
                testCase.verifyEqual(s.channels(k).max, double(max(ch(:))), ...
                    sprintf('kanal %d max salah', k));
            end
        end

        function entropyMatchesHistogramComputation(testCase)
            img = imread(fullfile(testCase.Dataset, '2. Kasus 1', 'image_01.png'));
            s = imageStatistics(img);

            gray = rgb2gray(img);
            h = computeHistogram(gray);
            p = h(h > 0) / sum(h);
            expected = -sum(p .* log2(p));

            testCase.verifyEqual(s.entropy, expected, 'AbsTol', 1e-12);
        end

        function constantImageHasZeroStdAndEntropy(testCase)
            s = imageStatistics(uint8(200 * ones(5, 5, 3)));
            testCase.verifyEqual(s.grayscale.std, 0);
            testCase.verifyEqual(s.entropy, 0);
        end

        function entropyIsNonNegative(testCase)
            files = dir(fullfile(testCase.Dataset, '2. Kasus 1', '*.png'));
            for f = 1:numel(files)
                img = imread(fullfile(testCase.Dataset, '2. Kasus 1', files(f).name));
                testCase.verifyGreaterThanOrEqual(imageStatistics(img).entropy, 0);
            end
        end
    end
end
