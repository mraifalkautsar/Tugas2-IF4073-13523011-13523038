img = imread(fullfile('dataset','5. Kasus 4','image_03.png'));
disp(size(img));

imgGray = img;

kernelG = gaussianKernel(3, 2); 
hasil = convolution(imgGray, kernelG);

kernelG2 = gaussianKernel(9, 1.6);  
hasil2 = convolution(imgGray, kernelG2);

hasil3 = medianFilter(imgGray, 3);

sharp = [0 -1 0; -1 3 -1; 0 -1 0]*1.2;
hasil4 = convolution(imgGray, sharp)
hasil5 = hasil2 - hasil4

subplot(2,2,1); imshow(imgGray); title("ori");
subplot(2,2,2); imshow(hasil2); title("7x / 0.6");
subplot(2,2,3); imshow(hasil4); title("sharp");
subplot(2,2,4); imshow(hasil5); title("ori-sharp");



% figure;
%// subplot(1,2,1); imshow(imgGray); title('Asli');
%/ subplot(1,2,2); imshow(hasil);   title('Gaussian Blur (sigma=1.4)');
