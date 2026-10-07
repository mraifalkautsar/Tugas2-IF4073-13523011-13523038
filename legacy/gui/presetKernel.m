function kernel = presetKernel(source, ukuran, param)
% kernel bawaan berukuran ukuran x ukuran ditampilkan di grid GUI

% source : 'gaussian' | 'mean' | 'sharpen'
% ukuran : skalar ganjil
% param  : sigma (gaussian) atau bobot (sharpen); diabaikan untuk mean
%
% kernel : matriks ukuran x ukuran nilai (belum dinormalisasi), atau [] jika tidak valid
%          Normalisasi di applyEnhancement.
%          gaussian: exp(-(x^2+y^2)/(2*sigma^2)), tengah = 1
%          mean    : semua elemen 1
%          sharpen : Laplacian 3x3 seperti applyEnhancement

kernel = [];

switch lower(source)
    case 'gaussian'
        if isscalar(param) && isfinite(param) && param > 0
            kernel = gaussianKernel(ukuran, param);
            c = (ukuran + 1) / 2;
            kernel = kernel / kernel(c, c);
        end

    case {'mean', 'box', 'averaging'}
        kernel = ones(ukuran, ukuran);

    case 'sharpen'
        if isscalar(param) && isfinite(param) && param >= 0
            c = (ukuran + 1) / 2;
            kernel = zeros(ukuran, ukuran);
            kernel(c, c)     = 1 + 4 * param;
            kernel(c - 1, c) = -param;
            kernel(c + 1, c) = -param;
            kernel(c, c - 1) = -param;
            kernel(c, c + 1) = -param;
        end
end
end
