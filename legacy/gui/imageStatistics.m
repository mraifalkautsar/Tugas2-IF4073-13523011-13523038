function stats = imageStatistics(img)
% imageStatistics - menghitung fitur/ukuran pendukung analisis citra
%
% img   : citra grayscale (2D) atau RGB (3D), uint8
% stats : struct dengan field
%           .grayscale  : struct .min .max .mean .std (dari citra grayscale)
%           .channels   : 1x3 struct .min .max .mean .std untuk kanal R,G,B
%                         (kosong [] kalau citra grayscale)
%           .entropy    : entropi (bit) histogram grayscale
%           .isColor    : true kalau citra RGB

isColor = (size(img, 3) == 3);

if isColor
    gray = rgb2gray(img);
else
    gray = img;
end

stats.isColor = isColor;

% fitur grayscale: kalau citra hitam/putih penuh tetap aman
[minG, maxG, meanG, stdG] = extractFeature(gray);

stats.grayscale.min  = double(minG);
stats.grayscale.max  = double(maxG);
stats.grayscale.mean = double(meanG);
stats.grayscale.std  = double(stdG);

% entropi dari histogram grayscale
h = computeHistogram(gray);
totalPiksel = sum(h);

if totalPiksel > 0
    p = h / totalPiksel;
    nz = p(p > 0);
    stats.entropy = -sum(nz .* log2(nz));
else
    stats.entropy = 0;
end

% fitur per kanal (hanya kalau RGB)
if isColor
    stats.channels = repmat(struct('min', [], 'max', [], 'mean', [], 'std', []), 1, 3);
    for k = 1:3
        [mn, mx, mv, sv] = extractFeature(img(:, :, k));
        stats.channels(k).min  = double(mn);
        stats.channels(k).max  = double(mx);
        stats.channels(k).mean = double(mv);
        stats.channels(k).std  = double(sv);
    end
else
    stats.channels = [];
end
end
