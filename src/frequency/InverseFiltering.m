function enhanced = InverseFiltering(imageArray, L, A, threshold)
%INVERSEFILTERING Summary of this function goes here
%   Detailed explanation goes here
image = im2double(imageArray);

[M, N, channels] = size(image);

H = PSFmotionBlur(image, L, A);

gain = zeros(size(H));

valid = abs(H) >= threshold;

gain(valid) = 1 ./ H(valid);

enhanced = zeros(M, N, channels);

for channel = 1:channels

    G = DFT2(image(:,:,channel), false);

    f = G .* gain;

    enhanced(:,:,channel) = ...
        real(DFT2(f, true));

end

enhanced = max(0, min(1, enhanced));

end