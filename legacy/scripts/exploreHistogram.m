folderPath = fullfile('dataset', '1. Histogram Citra');
files = dir(fullfile(folderPath, '*.png'));

for k = 1:length(files)
    namaFile = files(k).name;
    fullPath = fullfile(folderPath, namaFile);
    img = imread(fullPath);

    if size(img,3) == 3
        imgGray = rgb2gray(img);
    else
        imgGray = img;
    end

    plotHistogram(imgGray, namaFile);

    %cek vs imhist bawaan
    myHist = computeHistogram(imgGray);
    libHist = imhist(imgGray);
    cocok = isequal(myHist(:), libHist(:));
    fprintf('%s -> hasil compare = %d\n', namaFile, cocok);
end

%uji RGB
imgPertama = imread(fullfile(folderPath, files(4).name));
plotHistogram(imgPertama, ['RGB - ' files(1).name]);
