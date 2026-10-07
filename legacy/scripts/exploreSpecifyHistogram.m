imgSumber = imread(fullfile('dataset','2. Kasus 1','image_01.png'));
imgReferensi = imread(fullfile('dataset','2. Kasus 1','image_02.png'));

test = specifyHistogram(imgSumber, imgReferensi);
lib = imhistmatch(imgSumber, imgReferensi, 256); 

figure;
subplot(1,3,1); imshow(imgSumber);    title('Sumber');
subplot(1,3,2); imshow(imgReferensi); title('Referensi');
subplot(1,3,3); imshow(test); title('Hasil');

plotHistogram(imgSumber, 'Sumber');
plotHistogram(imgReferensi, 'Referensi');
plotHistogram(test, 'Hasil');
