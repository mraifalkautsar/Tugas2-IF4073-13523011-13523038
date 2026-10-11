function [enhanced, H] = ButterworthBandrejectFilter(imageArray, D0, W, n)
%BUTTERWORTHBANDREJECTFILTER Summary of this function goes here
%   Detailed explanation goes here
    image = im2double(imageArray);

    [M, N, channels] = size(image);
    u = -floor(N/2):ceil(N/2)-1;
    v = -floor(M/2):ceil(M/2)-1;

    [U, V] = meshgrid(u, v);
    D = sqrt(U.^2 + V.^2);

    H = zeros(M, N);
    valid = abs(D - D0) > 1e-12;
    ratio = (D(valid) * W) ./ ...
        abs(D(valid).^2 - D0^2);

    H(valid) = 1 ./ (1 + ratio.^(2*n));
    enhanced= zeros(M, N, channels);

    for channel = 1:channels
        F = fft2(image(:,:,channel));
        F = fftshift(F);
        G = F .* H;
        G = ifftshift(G);
        enhanced(:,:,channel) = real(ifft2(G));

    end
    enhanced = max(0, min(1, enhanced));

end
