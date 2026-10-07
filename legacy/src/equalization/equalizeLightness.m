function result = equalizeLightness(img)
% Perataan histogram pada channel lightness, jadi warna asli tidak berubah

% img: citra grayscale (2D) atau RGB (3D), uint8
% result: citra hasil equalization, uint8

if size(img,3) == 3
    labImg = rgb2lab(img);
    Lskala = getLightnessChannel(img);
    LhasilSkala = equalizeGrayscale(Lskala);

    labImg(:,:,1) = double(LhasilSkala) / 255 * 100;  %convert lagi ke ke 0-100
    result = im2uint8(lab2rgb(labImg));
    return;
end

result = equalizeGrayscale(img);
end
