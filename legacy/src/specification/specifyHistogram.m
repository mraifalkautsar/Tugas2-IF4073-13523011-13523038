function result = specifyHistogram(img, ref)
% Cocokkan histogram img ke histogram ref

% img: citra sumber (grayscale 2D atau RGB 3D), uint8
% ref: citra referensi sebagai histogram tujuannya, uint8
% result: citra img yang histogramnya sudah di-matching, uint8

if size(img,3) == 3
    Limg = getLightnessChannel(img);
    Lref = getLightnessChannel(ref);           % ref RGB atau gray, sama-sama aman

    Lhasil = specifyGrayscale(Limg, Lref);

    labImg = rgb2lab(img);
    labImg(:,:,1) = double(Lhasil) / 255 * 100;
    result = im2uint8(lab2rgb(labImg));
    return;
end

result = specifyGrayscale(img, ref);
end
