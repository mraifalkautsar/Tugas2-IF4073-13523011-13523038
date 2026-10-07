classdef appendRecordCsvTest < matlab.unittest.TestCase
% appendRecordCsvTest - memastikan penulisan CSV tampil dan bisa dibaca lagi.

    properties
        RepoRoot
        TmpDir
        CsvPath
    end

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.RepoRoot = 'C:\DATA\Projects\Tugas1-IF4073-CitraDigital-13523104';
            addpath(genpath(fullfile(testCase.RepoRoot, 'src')));

            testCase.TmpDir = fullfile(tempdir, 'opencode_csv_uji');
            if isfolder(testCase.TmpDir), rmdir(testCase.TmpDir, 's'); end
            testCase.CsvPath = fullfile(testCase.TmpDir, 'rekapan.csv');
        end
    end

    methods (TestMethodTeardown)
        function cleanup(testCase)
            if isfolder(testCase.TmpDir), rmdir(testCase.TmpDir, 's'); end
        end
    end

    methods (Test)
        function createsFileWithHeader(testCase)
            appendRecordCsv(testCase.CsvPath, {'a', 'b'}, {'1', '2'});
            testCase.verifyTrue(isfile(testCase.CsvPath));
            lines = readLines(testCase.CsvPath);
            testCase.verifyNumElements(lines, 2);
            testCase.verifyEqual(lines{1}, 'a,b');
            testCase.verifyEqual(lines{2}, '1,2');
        end

        function appendsWithoutRewritingHeader(testCase)
            appendRecordCsv(testCase.CsvPath, {'a', 'b'}, {'1', '2'});
            appendRecordCsv(testCase.CsvPath, {'a', 'b'}, {'3', '4'});
            lines = readLines(testCase.CsvPath);
            testCase.verifyNumElements(lines, 3);
            testCase.verifyEqual(lines{1}, 'a,b');
            testCase.verifyEqual(lines{2}, '1,2');
            testCase.verifyEqual(lines{3}, '3,4');
        end

        function quotesValuesWithComma(testCase)
            appendRecordCsv(testCase.CsvPath, {'param'}, {'r1 = 0, r2 = 255'});
            baris = readLines(testCase.CsvPath);
            testCase.verifyEqual(baris{2}, '"r1 = 0, r2 = 255"');
        end

        function escapesEmbeddedQuotes(testCase)
            appendRecordCsv(testCase.CsvPath, {'teks'}, {'saya bilang "hai"'});
            baris = readLines(testCase.CsvPath);
            testCase.verifyEqual(baris{2}, '"saya bilang ""hai"""');
        end

        function roundTripsThroughReadtable(testCase)
            header = {'folder', 'file', 'metode', 'parameter'};
            appendRecordCsv(testCase.CsvPath, header, {'2. Kasus 1', 'img.png', 'stretch', 'a, b'});
            appendRecordCsv(testCase.CsvPath, header, {'3. Kasus 2', 'x.png', 'gaussian', 's=2'});

            t = readtable(testCase.CsvPath, 'VariableNamingRule', 'preserve', ...
                'TextType', 'string');
            testCase.verifySize(t, [2 4]);
            testCase.verifyEqual(t.folder(1), "2. Kasus 1");
            testCase.verifyEqual(t.parameter(1), "a, b");   % koma harus utuh
            testCase.verifyEqual(t.folder(2), "3. Kasus 2");
        end

        function numericAndLogicalValuesAllowed(testCase)
            % nilai numerik dan logical dikonversi jadi teks apa adanya
            appendRecordCsv(testCase.CsvPath, {'n', 'b', 'k'}, {12, true, 'x'});
            baris = readLines(testCase.CsvPath);
            testCase.verifyEqual(baris{2}, '12,true,x');
        end

        function mismatchedColumnCountThrows(testCase)
            testCase.verifyError( ...
                @() appendRecordCsv(testCase.CsvPath, {'a', 'b'}, {'1'}), ...
                'appendRecordCsv:jumlahKolomTidakCocok');
        end

        function createsMissingFolder(testCase)
            nested = fullfile(testCase.TmpDir, 'inti', 'rekapan.csv');
            appendRecordCsv(nested, {'a'}, {'1'});
            testCase.verifyTrue(isfile(nested));
        end

        function nonCellArgumentsThrow(testCase)
            testCase.verifyError( ...
                @() appendRecordCsv(testCase.CsvPath, 'a,b', '1,2'), ...
                'appendRecordCsv:argBukanCell');
        end

        function emptyPathThrows(testCase)
            testCase.verifyError( ...
                @() appendRecordCsv('', {'a'}, {'1'}), ...
                'MATLAB:appendRecordCsv:expectedNonempty');
        end
    end
end

function lines = readLines(path)
% readLines - baca baris non-kosong sebagai cell array char
txt = fileread(path);
txt = strrep(txt, [char(13) newline], newline);
raw = strsplit(txt, newline);
raw = raw(~cellfun(@isempty, raw));
lines = raw;
end



