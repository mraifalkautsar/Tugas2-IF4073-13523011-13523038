function result = imageArithmetic(a, b, operation)
% Tambah/kurang dua citra berukuran sama, per piksel

% a: citra pertama (grayscale 2D atau RGB 3D), uint8
% b: citra kedua, ukuran dan jumlah kanalnya sama dengan a
% operation: 'add' -> a+b, 'subtract' -> a-b, 'reverse' -> b-a
% result: citra uint8, nilai di luar 0-255 di-clip

if ~isequal(size(a), size(b))
    if size(a, 3) ~= size(b, 3)
        error('imageArithmetic:kanalBeda', ...
            'Jumlah kanal citra berbeda (%d dan %d).', size(a, 3), size(b, 3));
    end
    error('imageArithmetic:ukuranBeda', ...
        'Ukuran citra berbeda (%dx%d dan %dx%d).', ...
        size(a, 1), size(a, 2), size(b, 1), size(b, 2));
end

% hitung dalam double supaya uint8 tidak saturasi sebelum selisih/jumlah selesai
a = double(a);
b = double(b);

switch lower(operation)
    case 'add'
        result = a + b;
    case 'subtract'
        result = a - b;
    case 'reverse'
        result = b - a;
    otherwise
        error('imageArithmetic:operasiTidakDikenal', ...
            'Operasi tidak dikenal: %s. Pilih add, subtract, atau reverse.', operation);
end

%clip
result = clipToUint8(result);
end
