function counts = computeHistogram(image)
% Histogram manual: hitung frekuensi tiap tingkat intensitas 0-255

% image: citra grayscale 2D, uint8
% counts: vektor 1x256, counts(k) = jumlah piksel bernilai k-1

counts = zeros(1, 256);
[height, width] = size(image);

for i = 1:height
    for j = 1:width
        level = double(image(i,j));
        counts(level + 1) = counts(level + 1) + 1;
    end
end
end
