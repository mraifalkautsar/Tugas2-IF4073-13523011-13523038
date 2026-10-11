function frequency = DFT2(imageArray, inverse)
%DFT2 Summary of this function goes here
%   Detailed explanation goes here
    image = double(imageArray);
    [M, N] = size(image);

    sign = -1;
    if inverse
        sign = 1;
    end

    rowIndex = (0:M-1)';
    colIndex = (0:N-1)';

    rowBasis = exp(sign * 2*pi*1i/M * (rowIndex * rowIndex.'));
    colBasis = exp(sign * 2*pi*1i/N * (colIndex * colIndex.'));

    frequency = rowBasis * image * colBasis.';

    if inverse
        frequency = frequency / (M * N);
    end
end
