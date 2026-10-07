function [nilaiMin, nilaiMax, nilaiMean, nilaiStd] = extractFeature(img)
% Ambil min, max, mean, dan std dari citra grayscale

% img: citra grayscale 2D, uint8
% nilaiMin, nilaiMax: intensitas piksel terendah/tertinggi yang muncul
% nilaiMean, nilaiStd: rata-rata dan standar deviasi intensitas
    h = computeHistogram(img);
    totalPiksel = sum(h);
    nilai = 0:255;

    nilaiMin = min(img(:));      
    nilaiMax = max(img(:));

    nilaiMean = sum(nilai .* h) / totalPiksel;
    varians = sum(((nilai - nilaiMean).^2) .* h) / totalPiksel;
    nilaiStd = sqrt(varians);
end
