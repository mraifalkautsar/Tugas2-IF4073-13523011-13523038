function plotHistogram(img, judul)
% Tampilkan citra + histogramnya di figure baru

% img: citra grayscale (2D) atau RGB (3D), uint8
% judul: judul figure-nya, boleh dikosongkan

if nargin < 2, judul = ''; end

if size(img,3) == 3 %ada 3 chanel/rgb
    figure('Name', judul);
    axImage = subplot(2,3,1);
    axGray  = subplot(2,3,2);
    axChannels = gobjects(1,3);
    for k = 1:3
        axChannels(k) = subplot(2,3,k+3);
    end

    drawImageAndHistograms(axImage, axGray, axChannels, img, judul);
else %gray scale
    figure('Name', judul);
    axImage = subplot(1,2,1);
    axGray  = subplot(1,2,2);

    drawImageAndHistograms(axImage, axGray, [], img, judul);
end
end
