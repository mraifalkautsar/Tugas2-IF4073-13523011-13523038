function result = equalizeRGB(img)
% Equalization per kanal R, G, B (warna ikut berubah)

% img: citra RGB (3D), uint8
% result: citra hasil equalization, uint8

result = zeros(size(img), 'uint8');
for channelIndex = 1:3
    result(:,:,channelIndex) = equalizeGrayscale(img(:,:,channelIndex));
end
end
