function padded = padReplicate(img, padRows, padCols)
% Padding dengan mereplikasi piksel tepi

% padRows, padCols: jumlah baris/kolom padding, tidak harus sama
% padded: citra 2D yang tepinya sudah direplikasi, kelas double

%padding replikasi piksel
[tinggi, lebar] = size(img);

imgPad = zeros(tinggi + 2*padRows, lebar + 2*padCols);
imgPad(padRows+1:padRows+tinggi, padCols+1:padCols+lebar) = img;

imgPad(1:padRows, padCols+1:padCols+lebar) = repmat(img(1,:), padRows, 1);   %atas
imgPad(padRows+tinggi+1:end, padCols+1:padCols+lebar) = repmat(img(end,:), padRows, 1); %bawah
imgPad(:, 1:padCols) = repmat(imgPad(:, padCols+1), 1, padCols);       %kiri (include sudut)
imgPad(:, padCols+lebar+1:end) = repmat(imgPad(:, padCols+lebar), 1, padCols);   %kanan (include sudut)

padded = imgPad;
end
