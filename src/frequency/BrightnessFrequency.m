function enhanced = BrightnessFrequency(imageArray, brightness)
%BRIGHTNESSFREQUENCY Summary of this function goes here
%   Detailed explanation goes here
    image = im2double(imageArray);

    [rows, cols, channels] = size(image);
    enhanced = zeros(rows,cols,channels);
    
    for channel = 1:channels

        F = DFT2(image(:,:,channel), false);

        F(1,1) = F(1,1) + brightness * rows * cols;

        enhanced(:,:,channel) = real(DFT2(F,true));
    end

    enhanced = max(0, min(1, enhanced));
end
