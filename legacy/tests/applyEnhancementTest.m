classdef applyEnhancementTest < matlab.unittest.TestCase
% applyEnhancementTest - memastikan dispatcher menangani warna dan parameter dengan benar.

    properties
        RepoRoot
        Dataset
        Rgb
        Gray
        Ref
    end

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.RepoRoot = 'C:\DATA\Projects\Tugas1-IF4073-CitraDigital-13523104';
            addpath(genpath(fullfile(testCase.RepoRoot, 'src')));
            addpath(fullfile(testCase.RepoRoot, 'gui'));

            testCase.Dataset = fullfile(testCase.RepoRoot, 'dataset');
            testCase.Rgb  = imread(fullfile(testCase.Dataset, '2. Kasus 1', 'image_01.png'));
            testCase.Gray = imread(fullfile(testCase.Dataset, '5. Kasus 4', 'image_01.png'));
            testCase.Ref  = imread(fullfile(testCase.Dataset, '2. Kasus 1', 'image_02.png'));
        end
    end

    % ---------- bentuk keluaran ----------
    methods (Test)
        function allTechniquesPreserveShapeAndClass(testCase)
            cases = { ...
                {'intensity',      struct('mode', 'negative')}, ...
                {'intensity',      struct('mode', 'log')}, ...
                {'intensity',      struct('mode', 'power', 'c', 1.1, 'gamma', 2.5)}, ...
                {'intensity',      struct('mode', 'stretch', 'r1', 84, 'r2', 140)}, ...
                {'equalization',   struct('variant', 'grayscale')}, ...
                {'equalization',   struct('variant', 'rgb')}, ...
                {'equalization',   struct('variant', 'lightness')}, ...
                {'specification',  struct('reference', testCase.Ref)}, ...
                {'filtering',      struct('jenis', 'linear', 'kernelSource', 'gaussian', ...
                                          'kernelSize', 3, 'sigma', 1.5)}, ...
                {'filtering',      struct('jenis', 'linear', 'kernelSource', 'mean', ...
                                          'kernelSize', 3)}, ...
                {'filtering',      struct('jenis', 'linear', 'kernelSource', 'sharpen', ...
                                          'sharpWeight', 1)}, ...
                {'filtering',      struct('jenis', 'linear', 'kernelSource', 'custom', ...
                                          'kernel', [0 -1 0; -1 6 -1; 0 -1 0], 'normalizeKernel', true)}, ...
                {'filtering',      struct('jenis', 'median', 'windowSize', 3)} ...
            };

            for c = 1:numel(cases)
                tech = cases{c}{1};
                p    = cases{c}{2};

                outRgb  = applyEnhancement(testCase.Rgb,  tech, p);
                outGray = applyEnhancement(testCase.Gray, tech, p);

                testCase.verifySize(outRgb, size(testCase.Rgb), ...
                    sprintf('%s: ukuran RGB berubah', tech));
                testCase.verifySize(outGray, size(testCase.Gray), ...
                    sprintf('%s: ukuran grayscale berubah', tech));

                testCase.verifyClass(outRgb, 'uint8', sprintf('%s: kelas RGB salah', tech));
                testCase.verifyClass(outGray, 'uint8', sprintf('%s: kelas grayscale salah', tech));

                % keluaran harus 3D kalau masukan 3D, dan 2D kalau masukan 2D
                testCase.verifyEqual(ndims(outRgb), 3, ...
                    sprintf('%s: keluaran RGB bukan 3D', tech));
                testCase.verifyEqual(ndims(outGray), 2, ...
                    sprintf('%s: keluaran grayscale bukan 2D', tech));
            end
        end

        function methodNameAndParamsReportedForEveryTechnique(testCase)
            cases = { ...
                {'intensity',     struct('mode', 'stretch', 'r1', 84, 'r2', 140)}, ...
                {'equalization',  struct('variant', 'rgb')}, ...
                {'specification', struct('reference', testCase.Ref)}, ...
                {'filtering',     struct('jenis', 'median', 'windowSize', 3)} ...
            };
            names = {'contrast stretching', 'kanal', 'Histogram Specification', 'median'};
            for c = 1:numel(cases)
                [~, name, ptext] = applyEnhancement(testCase.Rgb, cases{c}{1}, cases{c}{2});
                testCase.verifyNotEmpty(name);
                testCase.verifyNotEmpty(ptext);
                testCase.verifyNotEmpty(names{c});
                testCase.verifySubstring(name, names{c});
            end
        end

        function paramTextShowsActualParameterValues(testCase)
            [~, ~, ptext] = applyEnhancement(testCase.Rgb, 'intensity', ...
                struct('mode', 'power', 'c', 1.13, 'gamma', 3.8));
            testCase.verifySubstring(ptext, '1.13');
            testCase.verifySubstring(ptext, '3.8');
        end

        function logAutoScaleReportsCorrectMaximum(testCase)
            mx = double(max(testCase.Rgb(:)));
            [out, name, ptext] = applyEnhancement(testCase.Rgb, 'intensity', ...
                struct('mode', 'log'));
            testCase.verifyClass(out, 'uint8');
            testCase.verifySize(out, size(testCase.Rgb));
            testCase.verifySubstring(lower(name), 'log');
            testCase.verifySubstring(ptext, 'otomatis');
            testCase.verifySubstring(ptext, sprintf('%d', mx));
            % bandingkan dengan panggilan fungsi src langsung
            testCase.verifyEqual(out, intensityTransform(testCase.Rgb, 'log', []));
        end

        function matchesDirectFunctionCalls(testCase)
            % dispatcher harus menghasilkan citra sama persis dengan panggilan langsung
            [out, ~, ~] = applyEnhancement(testCase.Rgb, 'filtering', ...
                struct('jenis', 'linear', 'kernelSource', 'gaussian', ...
                       'kernelSize', 3, 'sigma', 2));
            k = gaussianKernel(3, 2);
            testCase.verifyEqual(out, convolution(testCase.Rgb, k));

            [out2, ~, ~] = applyEnhancement(testCase.Rgb, 'filtering', ...
                struct('jenis', 'median', 'windowSize', 3));
            testCase.verifyEqual(out2, medianFilter(testCase.Rgb, 3));

            [out3, ~, ~] = applyEnhancement(testCase.Gray, 'equalization', ...
                struct('variant', 'grayscale'));
            testCase.verifyEqual(out3, equalizeGrayscale(testCase.Gray));
        end
    end

    % ---------- aturan penanganan warna ----------
    methods (Test)
        function grayVariantOnColorImageStaysColor(testCase)
            % varian grayscale dipilih tapi citra RGB -> harus tetap berwarna
            [out, name, ~] = applyEnhancement(testCase.Rgb, 'equalization', ...
                struct('variant', 'grayscale'));
            testCase.verifyEqual(ndims(out), 3, 'keluaran harus tetap 3D');
            testCase.verifySubstring(name, 'lightness');
        end

        function colorVariantOnGrayImageFallsBackToGray(testCase)
            for v = {'rgb', 'lightness'}
                [out, name, ~] = applyEnhancement(testCase.Gray, 'equalization', ...
                    struct('variant', v{1}));
                testCase.verifyEqual(ndims(out), 2, 'keluaran harus 2D');
                testCase.verifyEqual(out, equalizeGrayscale(testCase.Gray));
                testCase.verifySubstring(name, 'grayscale');
            end
        end

        function rgbReferenceOnGraySourceIsConverted(testCase)
            % sumber abu-abu + referensi RGB: dispatcher harus konversi referensi
            [out, ~, ~] = applyEnhancement(testCase.Gray, 'specification', ...
                struct('reference', testCase.Ref));
            testCase.verifyEqual(ndims(out), 2);
            refGray = rgb2gray(testCase.Ref);
            testCase.verifyEqual(out, specifyHistogram(testCase.Gray, refGray));
        end

        function referenceAsFilePathWorks(testCase)
            refPath = fullfile(testCase.Dataset, '2. Kasus 1', 'image_02.png');
            [outPath, ~, ~] = applyEnhancement(testCase.Rgb, 'specification', ...
                struct('reference', refPath));
            [outArr, ~, ~] = applyEnhancement(testCase.Rgb, 'specification', ...
                struct('reference', testCase.Ref));
            testCase.verifyEqual(outPath, outArr);
        end
    end

    % ---------- validasi parameter ----------
    methods (Test)
        function stretchEqualBoundsThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'intensity', ...
                struct('mode', 'stretch', 'r1', 100, 'r2', 100)), 'applyEnhancement:rentangTidakValid');
        end

        function stretchReversedBoundsThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'intensity', ...
                struct('mode', 'stretch', 'r1', 200, 'r2', 100)), 'applyEnhancement:rentangTidakValid');
        end

        function arithmeticSubtractMatchesManual(testCase)
            operand = uint8(testCase.Rgb / 2);
            [out, ~, txt] = applyEnhancement(testCase.Rgb, 'arithmetic', ...
                struct('operation', 'subtract', 'operand', operand, 'operandName', 'proc_001.png'));
            testCase.verifyEqual(out, testCase.Rgb - operand);
            testCase.verifyTrue(contains(txt, 'proc_001.png'));
        end

        function arithmeticParamTextNamesBothImages(testCase)
            [~, ~, txt] = applyEnhancement(testCase.Rgb, 'arithmetic', ...
                struct('operation', 'subtract', 'operand', testCase.Rgb, ...
                       'operandName', 'proc_002.png', 'imageName', 'proc_001.png'));
            testCase.verifyEqual(txt, 'proc_001.png - proc_002.png');
        end

        function arithmeticSizeMismatchNamesBothImages(testCase)
            small = testCase.Rgb(1:10, 1:10, :);
            try
                applyEnhancement(testCase.Rgb, 'arithmetic', struct('operation', 'add', ...
                    'operand', small, 'operandName', 'kecil.png', 'imageName', 'besar.png'));
                testCase.verifyFail('seharusnya melempar error ukuranBeda');
            catch ex
                testCase.verifyEqual(ex.identifier, 'applyEnhancement:ukuranBeda');
                testCase.verifySubstring(ex.message, 'kecil.png');
                testCase.verifySubstring(ex.message, 'besar.png');
            end
        end

        function arithmeticReverseIsOperandMinusImage(testCase)
            operand = testCase.Rgb;
            img = uint8(testCase.Rgb / 2);
            out = applyEnhancement(img, 'arithmetic', ...
                struct('operation', 'reverse', 'operand', operand));
            testCase.verifyEqual(out, operand - img);
        end

        function arithmeticMissingOperandThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'arithmetic', ...
                struct('operation', 'add')), 'applyEnhancement:operanKosong');
        end

        function arithmeticSizeMismatchThrows(testCase)
            small = testCase.Rgb(1:10, 1:10, :);
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'arithmetic', ...
                struct('operation', 'add', 'operand', small)), 'applyEnhancement:ukuranBeda');
        end

        function arithmeticChannelMismatchThrows(testCase)
            gray = testCase.Rgb(:, :, 1);
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'arithmetic', ...
                struct('operation', 'add', 'operand', gray)), 'applyEnhancement:kanalBeda');
        end

        function arithmeticUnknownOperationThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'arithmetic', ...
                struct('operation', 'kali', 'operand', testCase.Rgb)), 'applyEnhancement:operasiTidakDikenal');
        end

        function stretchRgbKeepsRgbUint8(testCase)
            out = applyEnhancement(testCase.Rgb, 'intensity', struct('mode', 'stretchRGB', ...
                'r1rgb', [10 20 30], 'r2rgb', [200 210 220]));
            testCase.verifyClass(out, 'uint8');
            testCase.verifySize(out, size(testCase.Rgb));
        end

        function stretchRgbOnGrayThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Gray, 'intensity', ...
                struct('mode', 'stretchRGB', 'r1rgb', [0 0 0], 'r2rgb', [255 255 255])), ...
                'applyEnhancement:butuhRGB');
        end

        function stretchRgbBadChannelRangeThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'intensity', ...
                struct('mode', 'stretchRGB', 'r1rgb', [0 50 0], 'r2rgb', [255 50 255])), ...
                'applyEnhancement:rentangTidakValid');
        end

        function stretchMissingBoundsThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'intensity', ...
                struct('mode', 'stretch')), 'applyEnhancement:paramKurang');
        end

        function powerMissingGammaThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'intensity', ...
                struct('mode', 'power', 'c', 1.0)), 'applyEnhancement:paramKurang');
        end

        function unknownIntensityModeThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'intensity', ...
                struct('mode', 'bogus')), 'applyEnhancement:modeTidakDikenal');
        end

        function unknownTechniqueThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'telepathy', ...
                struct()), 'applyEnhancement:teknikTidakDikenal');
        end

        function missingReferenceThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'specification', ...
                struct()), 'applyEnhancement:referensiKosong');
        end

        function missingReferenceFileThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'specification', ...
                struct('reference', 'tidak-ada.png')), 'applyEnhancement:referensiTidakDitemukan');
        end

        function unknownKernelSourceThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'filtering', ...
                struct('jenis', 'linear', 'kernelSource', 'bambang')), 'applyEnhancement:sumberKernelTidakDikenal');
        end

        function evenKernelSizeThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'filtering', ...
                struct('jenis', 'linear', 'kernelSource', 'gaussian', ...
                       'kernelSize', 4, 'sigma', 1)), 'applyEnhancement:ukuranGenap');
        end

        function evenWindowThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'filtering', ...
                struct('jenis', 'median', 'windowSize', 4)), 'applyEnhancement:ukuranGenap');
        end

        function zeroKernelThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'filtering', ...
                struct('jenis', 'linear', 'kernelSource', 'custom', ...
                       'kernel', zeros(3, 3), 'normalizeKernel', true)), ...
                'applyEnhancement:kernelTakDapatDinormalisasi');
        end

        function nonSquareKernelThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'filtering', ...
                struct('jenis', 'linear', 'kernelSource', 'custom', ...
                       'kernel', ones(3, 5), 'normalizeKernel', false)), 'applyEnhancement:kernelTidakPersegi');
        end

        function emptyKernelThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'filtering', ...
                struct('jenis', 'linear', 'kernelSource', 'custom')), 'applyEnhancement:paramKurang');
        end

        function nonStructParamsThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, 'intensity', 'ugly'), 'applyEnhancement:paramsBukanStruct');
        end

        function emptyTechniqueThrows(testCase)
            testCase.verifyError(@() applyEnhancement(testCase.Rgb, '', struct()), 'applyEnhancement:teknikKosong');
        end
    end

    % ---------- kasus tepi ----------
    methods (Test)
        function logOnAllBlackImageIsRejected(testCase)
            % c = 255/log(1+maks) tak terdefinisi kalau maks = 0, jadi harus
            % ditolak dengan pesan jelas, bukan menghasilkan citra sampah.
            black = uint8(zeros(8, 8));
            err = '';
            try
                applyEnhancement(black, 'intensity', struct('mode', 'log'));
            catch ex
                err = ex.message;
            end
            testCase.verifyNotEmpty(err, 'transformasi log pada citra hitam seharusnya error');
            testCase.verifySubstring(lower(err), 'hitam');
        end

        function logOnExplicitParameterOverridesAuto(testCase)
            [out, name, ptext] = applyEnhancement(testCase.Rgb, 'intensity', ...
                struct('mode', 'log', 'c', 40));
            testCase.verifyClass(out, 'uint8');
            testCase.verifySize(out, size(testCase.Rgb));
            testCase.verifySubstring(lower(name), 'log');
            testCase.verifySubstring(ptext, '40');
            % c eksplisit harus dipakai, bukan c otomatis
            testCase.verifyEqual(out, intensityTransform(testCase.Rgb, 'log', 40));
        end

        function negativeIsInvolution(testCase)
            [once, ~, ~] = applyEnhancement(testCase.Gray, 'intensity', struct('mode', 'negative'));
            [twice, ~, ~] = applyEnhancement(once, 'intensity', struct('mode', 'negative'));
            testCase.verifyEqual(twice, testCase.Gray);
        end

        function customKernelNormalizationAffectsOutput(testCase)
            % kernel berjumlah 2 supaya normalisasi benar-benar mengubah hasil
            k = [0 -1 0; -1 6 -1; 0 -1 0];
            pOff = struct('jenis', 'linear', 'kernelSource', 'custom', ...
                          'kernel', k, 'normalizeKernel', false);
            pOn  = struct('jenis', 'linear', 'kernelSource', 'custom', ...
                          'kernel', k, 'normalizeKernel', true);
            [a, ~, ta] = applyEnhancement(testCase.Rgb, 'filtering', pOff);
            [b, ~, tb] = applyEnhancement(testCase.Rgb, 'filtering', pOn);
            testCase.verifyNotEqual(a, b);
            testCase.verifySubstring(ta, 'apa adanya');
            testCase.verifySubstring(tb, 'ternormalisasi');
            testCase.verifyEqual(a, convolution(testCase.Rgb, double(k)));
            testCase.verifyEqual(b, convolution(testCase.Rgb, double(k) / sum(k(:))));
        end
    end

    % ---------- helper ----------
    methods
        function out = applyToBoth(testCase, tech, p)
            out.rgb  = applyEnhancement(testCase.Rgb,  tech, p);
            out.gray = applyEnhancement(testCase.Gray, tech, p);
        end
    end
end
