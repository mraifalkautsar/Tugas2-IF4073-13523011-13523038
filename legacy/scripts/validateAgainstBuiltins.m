folderPath = fullfile('dataset', '1. Histogram Citra');
files = dir(fullfile(folderPath, '*.png'));

for k = 1:length(files)
    namaFile = files(k).name;
    fullPath = fullfile(folderPath, namaFile);
    img = imread(fullPath);
    disp(size(img)); %buat confirm doang

    %cek vs imhist bawaan, per kanal 
    jumlahKanal = size(img,3);
    myHist = zeros(256, jumlahKanal);
    libHist = zeros(256, jumlahKanal);
    for c = 1:jumlahKanal
        myHist(:,c) = computeHistogram(img(:,:,c));
        libHist(:,c) = imhist(img(:,:,c));
    end
    cocok = isequal(myHist, libHist);
    fprintf('%s -> hasil compare = %d\n', namaFile, cocok);

    figure('Name', namaFile);
    subplot(2,2,[1 2]); imshow(img); title(namaFile);
    subplot(2,2,3); barOverlap(myHist); title('computeHistogram.m');
    xlabel('Intensitas'); ylabel('Jumlah Piksel');
    subplot(2,2,4); barOverlap(libHist); title('imhist');
    xlabel('Intensitas'); ylabel('Jumlah Piksel');
end

function barOverlap(h)
if size(h,2) == 3
    warna = {'r', 'g', 'b'};
    hold on;
    for c = 1:3
        bar(0:255, h(:,c), 'FaceColor', warna{c}, 'FaceAlpha', 0.5, 'EdgeColor', 'none');
    end
    hold off;
    xlim([0 255]);
else
    bar(0:255, h);
end
end
