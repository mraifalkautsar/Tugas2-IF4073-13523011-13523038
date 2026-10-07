function Lskala = getLightnessChannel(img)
% mengambil channel lightness (Lab) lalu diskalakan ke 0-255

% img: citra grayscale (2D) atau RGB (3D), uint8
% Lskala: citra 2D uint8 dalam rentang 0-255

if size(img,3) == 3
    lab = rgb2lab(img);
    L = lab(:,:,1);   %rentang asli Lab: 0-100
    Lskala = uint8(round(L / 100 * 255));
else
    Lskala = img;
end
end
