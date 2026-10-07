function spectrum = magnitudeSpectrum(img)
%MAGNITUDESPECTRUM Log magnitude of centered 2-D FFT for display only.
% For RGB visualization, average the channels; processing methods will
% specify their own channel policy when implemented.
validateattributes(img, {'numeric', 'logical'}, {'nonempty', 'real'}, ...
    'magnitudeSpectrum', 'img');
if ~(ismatrix(img) || (ndims(img) == 3 && size(img, 3) == 3))
    error('magnitudeSpectrum:channels', 'Image must be grayscale or RGB.');
end
if size(img, 3) == 3
    gray = mean(double(img), 3);
else
    gray = double(img);
end
spectrum = log1p(abs(fftshift(fft2(gray))));
end
