img1 = imread(fullfile('dataset','2. Kasus 1','image_01.png'));
disp(size(img1));
imgGray1 = rgb2gray(img1);  
minVal = min(imgGray1(:));
maxVal = max(imgGray1(:));
fprintf('Min = %d, Max = %d\n', minVal, maxVal);

img1Enh = intensityTransform(img1, 'stretch', [84 140 0 255]);
img1EnhHisteq = equalizeRGB(img1);
plotHistogram(img1, 'image_01');
plotHistogram(img1Enh, 'image_01 enhanced');
plotHistogram(img1EnhHisteq, 'image_01 enhanced Histeq'); %test doang sebagus apa klo pake histeq

imgGray1 = rgb2gray(img1Enh);  
minVal = min(imgGray1(:));
maxVal = max(imgGray1(:));
fprintf('Enhanced Min = %d, Max = %d\n', minVal, maxVal);
