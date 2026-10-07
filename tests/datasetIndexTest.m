classdef datasetIndexTest < matlab.unittest.TestCase
    methods (Test)
        function missingDatasetHasFiveEmptySections(testCase)
            index = datasetIndex(fullfile(tempdir, 'if4073-not-installed'));
            testCase.verifyEqual({index.section}, {'B', 'C', 'D', 'E', 'F'});
            for k = 1:5
                testCase.verifyEmpty(index(k).input);
                testCase.verifyEmpty(index(k).reference);
            end
        end

        function onlyInputImagesAreIndexed(testCase)
            root = tempname;
            in = fullfile(root, 'E_periodic_noise_restoration', 'input');
            ref = fullfile(root, 'E_periodic_noise_restoration', 'reference');
            mkdir(in);
            mkdir(ref);
            testCase.addTeardown(@() rmdir(root, 's'));
            imwrite(zeros(3, 'uint8'), fullfile(in, 'b.PNG'));
            imwrite(zeros(3, 'uint8'), fullfile(in, 'a.png'));
            imwrite(zeros(3, 'uint8'), fullfile(ref, 'target.png'));
            fid = fopen(fullfile(in, 'notes.txt'), 'w');
            fclose(fid);

            index = datasetIndex(root);
            testCase.verifyEqual(cellfun(@(p) fileName(p), index(4).input, ...
                'UniformOutput', false), {'a.png', 'b.PNG'});
            testCase.verifyNumElements(index(4).reference, 1);
            testCase.verifyEmpty(index(1).input);
        end
    end
end

function name = fileName(path)
[~, base, ext] = fileparts(path);
name = [base ext];
end
