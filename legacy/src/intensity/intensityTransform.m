function result = intensityTransform(img, mode, param)
% Transformasi intensitas piksel

% img: citra grayscale (2D) atau RGB (3D), uint8
% mode: negative / log / power / stretch / stretchrgb
% param: tergantung mode
% result: citra hasil, uint8

img = double(img);

%hasil = s, img = r kalau ngikutin ppt
switch lower(mode)
    case 'negative'
        result = 255 - img;

    case 'log'
        %memperdetail daerah gelap (mirip gamma < 1)
        if nargin < 3 || isempty(param) %cek var param
            c = 255 / log(1 + max(img(:))); %default biar max 255
        else
            c = param;
        end
        result = c * log(1 + img);

    case 'power'
        %gamma correction: param = [c, gamma]
        %gamma < 1 -> mencerahkan citra gelap
        %gamma > 1 -> menggelapkan citra terang
        c = param(1);
        gamma = param(2);
        result = c * (img / 255).^gamma * 255;

    case 'stretch'
        %contrast stretching linear: param = [rMin, rMax, sMin, sMax]
        %memetakan rentang input [rMin, rMax] jadi rentang target [sMin, sMax].
        rMin = param(1);
        rMax = param(2);
        sMin = param(3);
        sMax = param(4);
        result = (img - rMin) / (rMax - rMin) * (sMax - sMin) + sMin;

    case 'stretchrgb'
        %contrast stretching per kanal: param = 4x3, kolom = kanal R,G,B,
        %baris = [rMin; rMax; sMin; sMax]
        if size(img, 3) ~= 3
            error('intensityTransform:butuhRGB', 'stretchRGB hanya untuk citra RGB.');
        end
        result = zeros(size(img));
        for k = 1:3
            rMin = param(1, k);
            rMax = param(2, k);
            sMin = param(3, k);
            sMax = param(4, k);
            result(:, :, k) = (img(:, :, k) - rMin) / (rMax - rMin) * (sMax - sMin) + sMin;
        end

    otherwise
        error('P ga ada dipilihan: %s', mode);
end
%clip
result = clipToUint8(result);
end
