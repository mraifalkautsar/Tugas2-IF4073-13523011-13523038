function result = clipToUint8(result)
% membatasi nilai ke rentang 0-255, lalu menjadikan uint8

% result: citra 2D/3D bertipe double (atau numerik lain)

%clip
result(result < 0)   = 0;
result(result > 255) = 255;
result = uint8(round(result));
end
