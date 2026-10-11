function H = PSFmotionBlur(imageArray, L, A)
%PSFMOTIONBLUR Summary of this function goes here
%   Detailed explanation goes here
    [M,N,~] = size(imageArray);

    radius = ceil(L/2) + 2;
    K = 2*radius + 1;
    center = radius + 1;
    psf = zeros(K,K);

    motion = max(101,ceil(20*L));
    dx = cosd(A);
    dy = sind(A);
    for s = 0:motion-1
        t = (s/(motion-1) - 0.5) * max(L-1,0);
        x = center + t*dx;
        y = center + t*dy;

        c0 = floor(x);
        r0 = floor(y);
        wx = x - c0;
        wy = y - r0;

        psf(r0,c0) = psf(r0,c0) + (1-wx)*(1-wy);
        psf(r0,c0+1) = psf(r0,c0+1) + wx*(1-wy);
        psf(r0+1,c0) = psf(r0+1,c0) + (1-wx)*wy;
        psf(r0+1,c0+1) = psf(r0+1,c0+1) + wx*wy;
    end
    psf = psf / sum(psf(:));
    kernelImage = zeros(M,N);
    for row = 1:K
        for col = 1:K
            if psf(row,col) ~= 0
                outRow = mod(row-center,M) + 1;
                outCol = mod(col-center,N) + 1;
                kernelImage(outRow,outCol) = ...
                    kernelImage(outRow,outCol) + psf(row,col);
            end
        end
    end

    H = DFT2(kernelImage,false);
    H = H / H(1,1);
end
