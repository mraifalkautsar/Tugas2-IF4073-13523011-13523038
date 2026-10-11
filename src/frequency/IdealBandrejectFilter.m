
function [enhanced,H] = IdealBandrejectFilter(imageArray, D0, W)
%IDEALBANDREJECTFILTER Summary of this function goes here
%   Detailed explanation goes here
image = im2double(imageArray);

[M, N, channels] = size(image);

u = -floor(N/2):ceil(N/2)-1;
v = -floor(M/2):ceil(M/2)-1;

[U, V] = meshgrid(u, v);

D = sqrt(U.^2 + V.^2);

H = ones(M, N);

lowerBound = D0 - W/2;
upperBound = D0 + W/2;

H(D >= lowerBound & D <= upperBound) = 0;

enhanced = zeros(M, N, channels);

for channel = 1:channels

    F = fft2(image(:,:,channel));

    F = fftshift(F);

    G = F .* H;

    G = ifftshift(G);

    enhanced(:,:,channel) = real(ifft2(G));

end

enhanced = max(0, min(1, enhanced));

end
