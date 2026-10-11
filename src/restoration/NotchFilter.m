function enhanced = NotchFilter(imageArray, u0, v0, D0)
%NOTCHFILTER Summary of this function goes here
%   Detailed explanation goes here
    image = im2double(imageArray);

    [M, N, channels] = size(image);

    u = -floor(N/2):ceil(N/2)-1;
    v = -floor(M/2):ceil(M/2)-1;

    [U, V] = meshgrid(u, v);

    D1 = sqrt((U - u0).^2 + (V - v0).^2);

    D2 = sqrt((U + u0).^2 + (V + v0).^2);

    H = ones(M, N);

    H(D1 <= D0 | D2 <= D0) = 0;

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
