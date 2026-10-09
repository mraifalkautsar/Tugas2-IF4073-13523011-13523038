function [result, H, before, after] = radialFilter(img, pass, family, cutoff, order)
% RADIALFILTER Ideal, Gaussian or Butterworth LPF/HPF in the Fourier domain.
% [result, H, before, after] = radialFilter(img,pass,family,cutoff,order)
% pass: 'low' or 'high'; family: 'Ideal', 'Gaussian', 'Butterworth'.

if nargin < 5, order = 2; end
validateattributes(img, {'uint8', 'uint16', 'single', 'double'}, ...
    {'nonempty', 'real', 'finite'}, mfilename, 'img');
if ~(ismatrix(img) || (ndims(img) == 3 && size(img, 3) == 3))
    error('radialFilter:channels', 'Image must be grayscale or RGB.');
end
validateattributes(cutoff, {'numeric'}, {'scalar', 'real', 'finite', 'positive'}, ...
    mfilename, 'cutoff');
pass = lower(char(pass));
family = lower(char(family));
if strcmp(family, 'butterworth')
    validateattributes(order, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'integer', 'positive'}, mfilename, 'order');
end

[rows, cols, ~] = size(img);
[v, u] = meshgrid(-floor(cols/2):ceil(cols/2)-1, ...
                  -floor(rows/2):ceil(rows/2)-1);
D = hypot(u, v);
switch family
    case 'ideal'
        low = double(D <= cutoff);
    case 'gaussian'
        low = exp(-D.^2 / (2 * cutoff^2));
    case 'butterworth'
        low = 1 ./ (1 + (D / cutoff).^(2 * order));
    otherwise
        error('radialFilter:family', 'Unknown filter family: %s.', family);
end
switch pass
    case 'low'
        H = low;
    case 'high'
        H = 1 - low;
    otherwise
        error('radialFilter:pass', 'Pass must be low or high.');
end

F = fftshift(fftshift(fft2(im2double(img)), 1), 2);
G = F .* H;
result = real(ifft2(ifftshift(ifftshift(G, 1), 2)));
before = log1p(abs(mean(F, 3)));
after = log1p(abs(mean(G, 3)));
end
