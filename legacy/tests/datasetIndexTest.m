classdef datasetIndexTest < matlab.unittest.TestCase
% datasetIndexTest - memastikan struktur folder citra uji terbaca benar.

    properties
        RepoRoot
    end

    methods (TestMethodSetup)
        function addPaths(testCase)
            testCase.RepoRoot = 'C:\DATA\Projects\Tugas1-IF4073-CitraDigital-13523104';
            addpath(fullfile(testCase.RepoRoot, 'gui'));
        end
    end

    methods (Test)
        function findsAllFiveFolders(testCase)
            idx = datasetIndex(fullfile(testCase.RepoRoot, 'dataset'));
            testCase.verifyNumElements(idx, 5);
        end

        function folderNamesMatch(testCase)
            idx = datasetIndex(fullfile(testCase.RepoRoot, 'dataset'));
            names = {idx.folder};
            testCase.verifyEqual(names, { ...
                '1. Histogram Citra', '2. Kasus 1', '3. Kasus 2', ...
                '4. Kasus 3', '5. Kasus 4'});
        end

        function everyFolderHasFourImages(testCase)
            idx = datasetIndex(fullfile(testCase.RepoRoot, 'dataset'));
            for k = 1:numel(idx)
                testCase.verifyNumElements(idx(k).files, 4, ...
                    sprintf('folder "%s" tidak punya 4 citra', idx(k).folder));
            end
        end

        function twentyImagesTotal(testCase)
            idx = datasetIndex(fullfile(testCase.RepoRoot, 'dataset'));
            total = sum(cellfun(@numel, {idx.files}));
            testCase.verifyEqual(total, 20);
        end

        function filesAreSorted(testCase)
            idx = datasetIndex(fullfile(testCase.RepoRoot, 'dataset'));
            for k = 1:numel(idx)
                testCase.verifyEqual(idx(k).files, sort(idx(k).files), ...
                    sprintf('file di folder "%s" tidak terurut abjad', idx(k).folder));
            end
        end

        function defaultArgumentWorks(testCase)
            orig = pwd;
            cleaner = onCleanup(@() cd(orig));
            cd(testCase.RepoRoot);
            idx = datasetIndex();
            testCase.verifyNumElements(idx, 5);
        end

        function tempProcessFolderIsIgnored(testCase)
            root = tempname;
            mkdir(fullfile(root, '1. Kasus'));
            mkdir(fullfile(root, 'tempProcess'));
            testCase.addTeardown(@() rmdir(root, 's'));
            imwrite(zeros(4, 'uint8'), fullfile(root, 'tempProcess', 'proc_001.png'));

            idx = datasetIndex(root);
            testCase.verifyEqual({idx.folder}, {'1. Kasus'});
        end

        function missingFolderThrows(testCase)
            testCase.verifyError(@() datasetIndex('folder-yang-tidak-ada'), ...
                'datasetIndex:folderTidakDitemukan');
        end
    end
end
