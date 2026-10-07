img = imread(fullfile('dataset','2. Kasus 1','image_02.png'));

img1Enh = intensityTransform(img, 'power', [1.13 3.8]);
plotHistogram(img, 'image_02');
plotHistogram(img1Enh, 'image_02 enhanced');
plotHistogram(intensityTransform(img, 'power', [1 3.8]), 'image_02 enhanced');
plotHistogram(equalizeRGB(img), 'p')
