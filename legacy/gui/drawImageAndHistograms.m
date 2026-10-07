function drawImageAndHistograms(axImage, axGray, axChannels, img, judul, grayColor)
% drawImageAndHistograms - menggambar citra beserta histogramnya ke axes yang diberikan
%
% axImage     : axes untuk menampung citra
% axGray      : axes untuk menampung histogram grayscale
% axChannels  : array 1x3 axes untuk histogram kanal R, G, B
%               (kirim [] kalau citra grayscale)
% img         : citra grayscale (2D) atau RGB (3D), uint8
% judul       : judul untuk citra
% grayColor   : warna batang grayscale (opsional, default putih untuk script)

if nargin < 6
    grayColor = [1 1 1];
end

if size(img,3) == 3 %ada 3 chanel/rgb
    axImage.Visible = 'on';

    % Konfigurasi axes untuk mengisi panel (sudah diatur di buildRightPanel)
    axis(axImage, 'off');

    % Enable interactivity
    zoom(axImage, 'on');
    pan(axImage, 'on');

    imshow(img, 'Parent', axImage);
    title(axImage, ['Citra ' judul]);

    h = computeHistogram(rgb2gray(img));
    axGray.Visible = 'on';
    bar(axGray, 0:255, h, 'FaceColor', grayColor);
    title(axGray, 'Histogram Grayscale');
    xlabel(axGray, 'Intensitas'); ylabel(axGray, 'Jumlah Piksel');

    ch = {'R','G','B'};
    warnaBar  = {'r','g','b'};
    for k = 1:3
        h = computeHistogram(img(:,:,k));
        axChannels(k).Visible = 'on';
        bar(axChannels(k), 0:255, h, warnaBar{k});
        title(axChannels(k), ['Kanal ' ch{k}]);
        xlabel(axChannels(k), 'Intensitas'); ylabel(axChannels(k), 'Jumlah Piksel');
    end
else %gray scale
    axImage.Visible = 'on';

    % Konfigurasi axes untuk mengisi panel (sudah diatur di buildRightPanel)
    axis(axImage, 'off');

    % Enable interactivity
    zoom(axImage, 'on');
    pan(axImage, 'on');

    imshow(img, 'Parent', axImage);
    title(axImage, ['Citra ' judul]);

    h = computeHistogram(img);
    axGray.Visible = 'on';
    bar(axGray, 0:255, h, 'FaceColor', grayColor);
    title(axGray, 'Histogram Grayscale');
    xlabel(axGray, 'Intensitas'); ylabel(axGray, 'Jumlah Piksel');
end
end
