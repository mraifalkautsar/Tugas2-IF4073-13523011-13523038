function result = medianFilter(img, ukuranWindow)
% Filter median, bagus untuk menghilangkan noise bintik

% img: citra grayscale (2D) atau RGB (3D), uint8
% ukuranWindow: panjang sisi window, harus ganjil
% result: citra hasil, uint8

if size(img,3) == 3
    R = medianFilter(img(:,:,1), ukuranWindow);
    G = medianFilter(img(:,:,2), ukuranWindow);
    B = medianFilter(img(:,:,3), ukuranWindow);
    result = cat(3, R, G, B);
    return;
end

if mod(ukuranWindow, 2) == 0
    error('Ukuran harus ganjil');
end

img = double(img);
[tinggi, lebar] = size(img);
pad = (ukuranWindow - 1) / 2;

imgPad = padReplicate(img, pad, pad);

result = zeros(tinggi, lebar);

for i = 1:tinggi
    for j = 1:lebar
        region    = imgPad(i:i+ukuranWindow-1, j:j+ukuranWindow-1);
        nilaiUrut = sort(region(:));                          %sort nilai dalam window
        result(i,j) = nilaiUrut(ceil(numel(nilaiUrut)/2));
    end
end

result = uint8(round(result));
end
