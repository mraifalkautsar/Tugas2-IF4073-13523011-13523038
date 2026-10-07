function result = convolution(img, kernel)
% Konvolusi 2D dengan kernel apapun

% img: citra grayscale (2D) atau RGB (3D), uint8
% kernel: kernel ganjil x ganjil, dinormalisasikan dulu sebelum dipanggil
% result: citra hasil, ukuran sama dengan input, uint8

if size(img,3) == 3
    R = convolution(img(:,:,1), kernel); %layer depth ke 1
    G = convolution(img(:,:,2), kernel);
    B = convolution(img(:,:,3), kernel);
    result = cat(3, R, G, B);
    return;
end

img = double(img);
[tinggi, lebar] = size(img);
[kh, kw] = size(kernel);

if mod(kh,2) == 0 || mod(kw,2) == 0
    error('Ukuran kernel harus ganjil:');
end

padH = (kh - 1) / 2;
padW = (kw - 1) / 2;

imgPad = padReplicate(img, padH, padW);

result = zeros(tinggi, lebar);

for i = 1:tinggi
    for j = 1:lebar
        region = imgPad(i:i+kh-1, j:j+kw-1);      %window seukuran kernel
        result(i,j) = sum(sum(region .* kernel));   %konvolusi
    end
end

%clip
result = clipToUint8(result);
end
