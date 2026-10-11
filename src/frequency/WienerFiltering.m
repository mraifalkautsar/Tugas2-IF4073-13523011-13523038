
function enhanced = WienerFiltering(imageArray, L, A, K)
%WIENERFILTERING Summary of this function goes here
%   Detailed explanation goes here
image = im2double(imageArray);

[M, N, channels] = size(image);

H = PSFmotionBlur(image, L, A);

gain = conj(H) ./ (abs(H).^2 + K);
enhanced = zeros(M, N, channels);

for channel = 1:channels
    G = DFT2(image(:,:,channel), false);
    f = gain .* G;

    enhanced(:,:,channel) = ...
        real(DFT2(f, true));

end

enhanced = max(0, min(1, enhanced));

end
