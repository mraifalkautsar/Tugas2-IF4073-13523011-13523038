function [result, methodName, paramText] = applyEnhancement(img, technique, params)
% applyEnhancement - titik masuk tunggal semua teknik enhancement
%
% img       : citra grayscale (2D) atau RGB (3D), uint8
% technique : 'intensity' | 'equalization' | 'specification' | 'filtering' | 'arithmetic'
% params    : struct field sesuai teknik (lihat daftar di bawah)
%
% result     : citra hasil enhancement (uint8, dimensi sama dengan img)
% methodName : nama metode yang benar-benar dipakai (untuk laporan)
% paramText  : string parameter efektif yang dipakai (untuk laporan)
%
% Daftar field params per technique:
%   intensity     .mode .c .gamma .r1 .r2 .s1 .s2
%                 mode 'negative'  : tidak butuh param
%                 mode 'log'       : .c (opsional, otomatis kalau kosong)
%                 mode 'power'     : .c dan .gamma
%                 mode 'stretch'   : .r1 dan .r2 (rentang input), .s1 dan .s2
%                                    (rentang target, default 0 dan 255)
%                 mode 'stretchRGB': .r1rgb .r2rgb (input) dan .s1rgb .s2rgb
%                                    (target, default 0 dan 255), masing-masing
%                                    vektor 1x3 untuk kanal R,G,B; hanya citra RGB
%   equalization  .variant                % 'grayscale' | 'rgb' | 'lightness'
%   specification .reference              % citra array atau path file
%   filtering     .jenis .kernelSource .kernelSize .sigma .sharpWeight
%                 .kernel .normalizeKernel .windowSize
%                 jenis 'linear'  : .kernelSource + param kernel terkait
%                 jenis 'median'  : .windowSize
%   arithmetic    .operation .operand .operandName .imageName
%                 operation 'add' (img + operand) | 'subtract' (img - operand)
%                           | 'reverse' (operand - img)
%                 operand   : citra uint8 dengan ukuran dan jumlah kanal sama dengan img

if nargin < 2 || isempty(technique)
    error('applyEnhancement:teknikKosong', 'Teknik enhancement belum dipilih.');
end

if ~isstruct(params)
    error('applyEnhancement:paramsBukanStruct', 'Parameter enhancement harus berupa struct.');
end

switch lower(technique)
    case 'intensity'
        [result, methodName, paramText] = applyIntensity(img, params);

    case 'equalization'
        [result, methodName, paramText] = applyEqualization(img, params);

    case 'specification'
        [result, methodName, paramText] = applySpecification(img, params);

    case 'filtering'
        [result, methodName, paramText] = applyFiltering(img, params);

    case 'arithmetic'
        [result, methodName, paramText] = applyArithmetic(img, params);

    otherwise
        error('applyEnhancement:teknikTidakDikenal', 'Teknik enhancement tidak dikenal: %s', technique);
end

% jaga-jaga: keluaran harus sejenis dan seukuran dengan masukan
validateattributes(result, {'uint8'}, {'size', size(img)}, ...
    'applyEnhancement', 'result');

fprintf('Metode dipakai: %s | Parameter: %s\n', methodName, paramText);
end

% ---------------------------------------------------------------------------
function [result, methodName, paramText] = applyIntensity(img, params)

mode = lower(getText(params, 'mode', 'negative'));

switch mode
    case 'negative'
        result = intensityTransform(img, 'negative', []);
        methodName = 'Intensity Transformation - negative';
        paramText  = '-';

    case 'log'
        mx = double(max(img(:)));
        if mx == 0
            error('applyEnhancement:citraHitamPenuh', ...
                ['Transformasi log tidak dapat diterapkan: seluruh piksel citra bernilai 0 ' ...
                 '(citra hitam penuh), sehingga skala c = 255 / log(1 + maks) tidak terdefinisi ' ...
                 '(hasilnya NaN). Pilih teknik lain, misalnya negative.']);
        end
        c = getScalar(params, 'c', []);
        if isempty(c)
            cAuto = 255 / log(1 + mx);      % sama seperti default intensityTransform
            result = intensityTransform(img, 'log', []);
            methodName = 'Intensity Transformation - log';
            paramText  = sprintf('c = %.2f (otomatis, dari maks citra = %d)', cAuto, mx);
        else
            checkPositiveScalar(c, 'c');
            result = intensityTransform(img, 'log', c);
            methodName = 'Intensity Transformation - log';
            paramText  = sprintf('c = %.2f', c);
        end

    case 'power'
        c     = getScalar(params, 'c', []);
        gamma = getScalar(params, 'gamma', []);
        if isempty(c) || isempty(gamma)
            error('applyEnhancement:paramKurang', 'Mode power butuh parameter .c dan .gamma.');
        end
        checkPositiveScalar(c, 'c');
        checkPositiveScalar(gamma, 'gamma');
        result = intensityTransform(img, 'power', [c gamma]);
        methodName = 'Intensity Transformation - power (gamma)';
        paramText  = sprintf('c = %.2f, gamma = %.2f', c, gamma);

    case 'stretch'
        r1 = getScalar(params, 'r1', []);
        r2 = getScalar(params, 'r2', []);
        s1 = getScalar(params, 's1', 0);      % default target 0..255
        s2 = getScalar(params, 's2', 255);
        if isempty(r1) || isempty(r2)
            error('applyEnhancement:paramKurang', 'Mode stretch butuh parameter .r1 dan .r2. Tekan "Ambil min/maks citra" untuk mengisinya.');
        end
        checkRangeScalar(r1, 'r1');
        checkRangeScalar(r2, 'r2');
        checkRangeScalar(s1, 's1');
        checkRangeScalar(s2, 's2');
        if r1 >= r2
            error('applyEnhancement:rentangTidakValid', ...
                ['Batas rentang contrast stretching tidak valid: r1 (%g) harus lebih kecil ' ...
                 'dari r2 (%g). Ambil min/maks citra dulu supaya r1 < r2.'], r1, r2);
        end
        if s1 >= s2
            error('applyEnhancement:rentangTargetTidakValid', ...
                'Rentang target tidak valid: s1 (%g) harus lebih kecil dari s2 (%g).', s1, s2);
        end
        result = intensityTransform(img, 'stretch', [r1 r2 s1 s2]);
        methodName = 'Intensity Transformation - contrast stretching';
        paramText  = sprintf('input [%g, %g] -> target [%g, %g]', r1, r2, s1, s2);

    case 'stretchrgb'
        if size(img, 3) ~= 3
            error('applyEnhancement:butuhRGB', 'Mode stretchRGB hanya untuk citra berwarna (RGB).');
        end
        r1 = getChannelVector(params, 'r1rgb', []);
        r2 = getChannelVector(params, 'r2rgb', []);
        s1 = getChannelVector(params, 's1rgb', [0 0 0]);
        s2 = getChannelVector(params, 's2rgb', [255 255 255]);
        if isempty(r1) || isempty(r2)
            error('applyEnhancement:paramKurang', 'Mode stretchRGB butuh parameter .r1rgb dan .r2rgb (masing-masing 3 nilai R,G,B).');
        end
        nama = 'RGB';
        for k = 1:3
            checkRangeScalar(r1(k), ['r1rgb ' nama(k)]);
            checkRangeScalar(r2(k), ['r2rgb ' nama(k)]);
            checkRangeScalar(s1(k), ['s1rgb ' nama(k)]);
            checkRangeScalar(s2(k), ['s2rgb ' nama(k)]);
            if r1(k) >= r2(k)
                error('applyEnhancement:rentangTidakValid', ...
                    'Rentang input kanal %s tidak valid: min (%g) harus lebih kecil dari maks (%g).', ...
                    nama(k), r1(k), r2(k));
            end
            if s1(k) >= s2(k)
                error('applyEnhancement:rentangTargetTidakValid', ...
                    'Rentang target kanal %s tidak valid: min (%g) harus lebih kecil dari maks (%g).', ...
                    nama(k), s1(k), s2(k));
            end
        end
        result = intensityTransform(img, 'stretchRGB', [r1; r2; s1; s2]);
        methodName = 'Intensity Transformation - contrast stretching per kanal (RGB)';
        paramText  = sprintf('R [%g,%g]->[%g,%g]; G [%g,%g]->[%g,%g]; B [%g,%g]->[%g,%g]', ...
            r1(1), r2(1), s1(1), s2(1), r1(2), r2(2), s1(2), s2(2), r1(3), r2(3), s1(3), s2(3));

    otherwise
        error('applyEnhancement:modeTidakDikenal', 'Mode intensity tidak dikenal: %s. Pilih negative, log, power, stretch, atau stretchRGB.', mode);
end
end

% ---------------------------------------------------------------------------
function [result, methodName, paramText] = applyArithmetic(img, params)

operation = lower(getText(params, 'operation', 'subtract'));
operand   = getValue(params, 'operand', []);
name      = getText(params, 'operandName', 'operan');
nameImg   = getText(params, 'imageName', 'citra');   % nama citra pertama (img)

if isempty(operand)
    error('applyEnhancement:operanKosong', ...
        'Citra kedua belum dipilih. Simpan hasil ke temp dulu, atau pilih citra masukan asli.');
end
validateattributes(operand, {'uint8'}, {'nonempty'}, 'applyEnhancement:arithmetic', 'operand');

% cek size
if size(img, 3) ~= size(operand, 3)
    error('applyEnhancement:kanalBeda', ...
        ['Jumlah kanal berbeda: "%s" %d kanal, "%s" %d kanal. ' ...
         'Kedua citra harus sama-sama berwarna atau sama-sama abu-abu.'], ...
        nameImg, size(img, 3), name, size(operand, 3));
end
if size(img, 1) ~= size(operand, 1) || size(img, 2) ~= size(operand, 2)
    error('applyEnhancement:ukuranBeda', ...
        'Ukuran citra berbeda: "%s" %dx%d, "%s" %dx%d. Operasi hanya untuk ukuran yang sama.', ...
        nameImg, size(img, 1), size(img, 2), name, size(operand, 1), size(operand, 2));
end

switch operation
    case 'add'
        methodName = 'Image Arithmetic - penjumlahan';
        paramText  = sprintf('%s + %s', nameImg, name);
    case 'subtract'
        methodName = 'Image Arithmetic - pengurangan';
        paramText  = sprintf('%s - %s', nameImg, name);
    case 'reverse'
        methodName = 'Image Arithmetic - pengurangan terbalik';
        paramText  = sprintf('%s - %s', name, nameImg);
    otherwise
        error('applyEnhancement:operasiTidakDikenal', ...
            'Operasi tidak dikenal: %s. Pilih add, subtract, atau reverse.', operation);
end

result = imageArithmetic(img, operand, operation);
end

% ---------------------------------------------------------------------------
function [result, methodName, paramText] = applyEqualization(img, params)

isColor = (size(img, 3) == 3);
variant = lower(getText(params, 'variant', 'lightness'));

% Aturan penanganan warna: keluaran citra berwarna harus tetap berwarna(spec. bagian B),
% jadi varian grayscale tidak dipakai apa adanya pada citra RGB tetapi dinaikkan ke lightness.
if isColor
    switch variant
        case {'lightness', 'lab'}
            result = equalizeLightness(img);
            methodName = 'Histogram Equalization - kanal lightness (Lab)';
        case {'rgb', 'perchannel'}
            result = equalizeRGB(img);
            methodName = 'Histogram Equalization - per kanal R,G,B';
        case {'grayscale', 'gray'}
            result = equalizeLightness(img);
            methodName = ['Histogram Equalization - kanal lightness (Lab) ' ...
                          '(varian grayscale dipakai agar citra tetap berwarna)'];
        otherwise
            error('Varian equalization tidak dikenal: %s. Pilih grayscale, rgb, atau lightness.', variant);
    end
else
    % Citra abu-abu: varian rgb/lightness tidak punya arti, jadi dipakai grayscale.
    switch variant
        case {'grayscale', 'gray'}
            result = equalizeGrayscale(img);
            methodName = 'Histogram Equalization - grayscale';
        case {'lightness', 'lab', 'rgb', 'perchannel'}
            result = equalizeGrayscale(img);
            methodName = 'Histogram Equalization - grayscale (dipakai karena citra masukan abu-abu)';
        otherwise
            error('Varian equalization tidak dikenal: %s. Pilih grayscale, rgb, atau lightness.', variant);
    end
end

paramText = '-';
end

% ---------------------------------------------------------------------------
function [result, methodName, paramText] = applySpecification(img, params)

ref = getValue(params, 'reference', []);
if isempty(ref)
    error('applyEnhancement:referensiKosong', 'Citra referensi belum dipilih untuk histogram specification/matching.');
end

if ischar(ref) || isstring(ref)
    if exist(ref, 'file') ~= 2
        error('applyEnhancement:referensiTidakDitemukan', 'File citra referensi tidak ditemukan: %s', ref);
    end
    ref = imread(ref);
end

validateattributes(ref, {'uint8', 'double', 'logical'}, {'nonempty'}, ...
    'applyEnhancement:specification', 'reference');

srcIsColor  = (size(img, 3) == 3);
refIsColor  = (size(ref, 3) == 3);

% Referensi harus 2D kalau citra sumber 2D, karena computeHistogram hanya
% menangani masukan 2D; kalau dibiarkan, specifyGrayscale akan salah diam.
if ~srcIsColor && refIsColor
    ref = rgb2gray(ref);
    refIsColor = false;
end

result = specifyHistogram(img, ref);

if srcIsColor
    if refIsColor
        methodName = 'Histogram Specification/Matching - kanal lightness (Lab), referensi RGB';
    else
        methodName = 'Histogram Specification/Matching - kanal lightness (Lab), referensi abu-abu';
    end
else
    methodName = 'Histogram Specification/Matching - grayscale';
end

paramText = sprintf('referensi %s', describeImage(ref));
end

% ---------------------------------------------------------------------------
function [result, methodName, paramText] = applyFiltering(img, params)

jenis = lower(getText(params, 'jenis', 'linear'));

switch jenis
    case {'linear', 'konvolusi'}
        [result, methodName, paramText] = applyLinearFilter(img, params);

    case {'median', 'nonlinear'}
        [result, methodName, paramText] = applyMedianFilter(img, params);

    otherwise
        error('applyEnhancement:jenisTidakDikenal', 'Jenis filtering tidak dikenal: %s. Pilih linear atau median.', jenis);
end
end

% ---------------------------------------------------------------------------
function [result, methodName, paramText] = applyLinearFilter(img, params)

kernelSource = lower(getText(params, 'kernelSource', 'gaussian'));

switch kernelSource
    case 'gaussian'
        n     = getScalar(params, 'kernelSize', []);
        sigma = getScalar(params, 'sigma', []);
        if isempty(n) || isempty(sigma)
            error('applyEnhancement:paramKurang', 'Kernel Gaussian butuh parameter .kernelSize dan .sigma.');
        end
        n = round(n);
        checkKernelSize(n);
        checkPositiveScalar(sigma, 'sigma');
        kernel = gaussianKernel(n, sigma);
        methodName = 'Image Filtering - linear (konvolusi), kernel Gaussian';
        paramText  = sprintf('ukuran = %dx%d, sigma = %.2f, ternormalisasi', n, n, sigma);

    case {'mean', 'box', 'averaging'}
        n = getScalar(params, 'kernelSize', []);
        if isempty(n)
            error('applyEnhancement:paramKurang', 'Kernel mean butuh parameter .kernelSize.');
        end
        n = round(n);
        checkKernelSize(n);
        kernel = ones(n, n) / (n * n);
        methodName = 'Image Filtering - linear (konvolusi), kernel mean';
        paramText  = sprintf('ukuran = %dx%d, ternormalisasi', n, n);

    case 'sharpen'
        w = getScalar(params, 'sharpWeight', []);
        if isempty(w)
            error('applyEnhancement:paramKurang', 'Kernel sharpen butuh parameter .sharpWeight.');
        end
        if w < 0
            error('applyEnhancement:bobotNegatif', 'Bobot sharpen tidak boleh negatif.');
        end
        kernel = [0 -w 0; -w 1 + 4 * w -w; 0 -w 0];
        methodName = 'Image Filtering - linear (konvolusi), kernel sharpen (Laplacian)';
        paramText  = sprintf('bobot = %.2f', w);

    case {'custom', 'kustom'}
        kernel = getValue(params, 'kernel', []);
        if isempty(kernel)
            error('applyEnhancement:paramKurang', 'Kernel kustom belum diisi.');
        end
        validateattributes(kernel, {'numeric'}, {'nonempty', 'finite'}, ...
            'applyEnhancement:filtering', 'kernel');
        if ~ismatrix(kernel)
            error('applyEnhancement:kernelBukan2D', 'Kernel harus berupa matriks 2D, sekarang berdimensi %d.', ndims(kernel));
        end
        [kh, kw] = size(kernel);
        if kh ~= kw
            error('applyEnhancement:kernelTidakPersegi', 'Kernel harus berbentuk persegi, sekarang %dx%d.', kh, kw);
        end
        if mod(kh, 2) == 0
            error('applyEnhancement:ukuranGenap', 'Ukuran kernel harus ganjil, sekarang %d.', kh);
        end

        normalize = getLogical(params, 'normalizeKernel', true);
        kernelAsli = kernel;
        if normalize
            total = sum(kernel(:));
            if total == 0
                error('applyEnhancement:kernelTakDapatDinormalisasi', ...
                    ['Total elemen kernel nol, tidak bisa dinormalisasi. ' ...
                     'Isi kernel dulu atau matikan opsi normalisasi.']);
            end
            kernel = kernel / total;
        end

        if all(kernelAsli(:) == 0)
            error('applyEnhancement:kernelNol', 'Kernel kustom seluruh elemennya nol, hasilnya akan hitam semua.');
        end

        methodName = 'Image Filtering - linear (konvolusi), kernel kustom';
        paramText  = describeKernel(kernelAsli, normalize);

    otherwise
        error('applyEnhancement:sumberKernelTidakDikenal', 'Sumber kernel tidak dikenal: %s. Pilih gaussian, mean, sharpen, atau custom.', kernelSource);
end

result = convolution(img, kernel);
end

% ---------------------------------------------------------------------------
function [result, methodName, paramText] = applyMedianFilter(img, params)

n = getScalar(params, 'windowSize', []);
if isempty(n)
    error('applyEnhancement:paramKurang', 'Median filter butuh parameter .windowSize.');
end
n = round(n);
checkWindowSize(n);

result = medianFilter(img, n);
methodName = 'Image Filtering - non-linear (median)';
paramText  = sprintf('ukuran window = %dx%d', n, n);
end

% ---------------------------------------------------------------------------
% helper

function v = getValue(s, name, default)
if isfield(s, name) && ~isempty(s.(name))
    v = s.(name);
else
    v = default;
end
end

function v = getScalar(s, name, default)
if ~isfield(s, name) || isempty(s.(name))
    v = default;
    return;
end
v = s.(name);
validateattributes(v, {'numeric'}, {'finite', 'scalar'}, 'applyEnhancement', name);
end

function v = getChannelVector(s, name, default)
% vektor baris 1x3 (nilai kanal R,G,B)
if ~isfield(s, name) || isempty(s.(name))
    v = default;
    return;
end
v = s.(name);
validateattributes(v, {'numeric'}, {'finite', 'numel', 3}, 'applyEnhancement', name);
v = double(v(:)');
end

function v = getText(s, name, default)
if ~isfield(s, name) || isempty(s.(name))
    v = default;
    return;
end
v = char(s.(name));
end

function v = getLogical(s, name, default)
if ~isfield(s, name) || isempty(s.(name))
    v = default;
    return;
end
v = logical(s.(name));
end

function checkPositiveScalar(v, name)
validateattributes(v, {'numeric'}, {'positive', 'finite', 'scalar'}, ...
    'applyEnhancement', name);
end

function checkRangeScalar(v, name)
validateattributes(v, {'numeric'}, {'>=', 0, '<=', 255}, ...
    'applyEnhancement', name);
end

function checkKernelSize(n)
validateattributes(n, {'numeric'}, {'finite', 'scalar'}, ...
    'applyEnhancement', 'kernelSize');
if mod(n, 2) == 0
    error('applyEnhancement:ukuranGenap', ...
        'Ukuran kernel harus ganjil, sekarang %d.', n);
end
if n < 3 || n > 15
    error('applyEnhancement:ukuranLuarbatas', ...
        'Ukuran kernel harus antara 3 dan 15, sekarang %d.', n);
end
end

function checkWindowSize(n)
validateattributes(n, {'numeric'}, {'finite', 'scalar'}, ...
    'applyEnhancement', 'windowSize');
if mod(n, 2) == 0
    error('applyEnhancement:ukuranGenap', ...
        'Ukuran window median harus ganjil, sekarang %d.', n);
end
if n < 3 || n > 15
    error('applyEnhancement:ukuranLuarbatas', ...
        'Ukuran window median harus antara 3 dan 15, sekarang %d.', n);
end
end

function t = describeImage(img)
if size(img, 3) == 3
    t = sprintf('RGB %dx%d', size(img, 1), size(img, 2));
else
    t = sprintf('abu-abu %dx%d', size(img, 1), size(img, 2));
end
end

function t = describeKernel(kernel, normalized)
s = mat2str(kernel, 3);
if numel(s) > 60
    s = [s(1:57) '...'];
end
if normalized
    t = sprintf('kernel = %s (sebelum normalisasi), ternormalisasi', s);
else
    t = sprintf('kernel = %s (apa adanya)', s);
end
end
