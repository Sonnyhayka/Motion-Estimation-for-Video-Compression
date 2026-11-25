function bytesWritten = writeYuv420(S, yuvPath, options)
arguments
    S struct
    yuvPath (1, :) char
    options.Verbose (1, 1) logical = true
end

frameCount = size(S.Y8, 3);
height = size(S.Y8, 1);
width = size(S.Y8, 2);
if isempty(S.Y8) || ndims(S.Y8) > 3 || ...
        mod(height, 2) ~= 0 || mod(width, 2) ~= 0 || ...
        ndims(S.Cb420) > 3 || ndims(S.Cr420) > 3 || ...
        ~isequal(size(S.Cb420, 1), height / 2, size(S.Cr420, 1)) || ...
        ~isequal(size(S.Cb420, 2), width / 2, size(S.Cr420, 2)) || ...
        ~isequal(size(S.Cb420, 3), frameCount, size(S.Cr420, 3))
    error('writeYuv420:badGeometry', ...
        'Y must have even dimensions, with half-size Cb and Cr planes and matching frame counts.');
end
Cb8 = uint8(round(S.Cb420));
Cr8 = uint8(round(S.Cr420));
yBytes = height * width;
cbBytes = yBytes / 4;
crBytes = yBytes / 4;
planeBytes = yBytes + cbBytes + crBytes;
bytesWritten = planeBytes * frameCount;

folder = fileparts(yuvPath);
if ~isempty(folder) && ~isfolder(folder)
    [ok, msg] = mkdir(folder);
    if ~ok
        error('writeYuv420:badPath', ...
            'Could not create the output folder:\n %s\n%s', folder, msg);
    end
end

fid = fopen(yuvPath, 'w');
if fid < 0
    error('writeYuv420:badPath', ...
        'Could not open the output file for writing:\n %s', yuvPath);
end

closer = onCleanup(@() fclose(fid));

% fwrite is column-major; planar YUV is raster (row-major), so transpose.
written = 0;
for j = 1:frameCount
    written = written + fwrite(fid, S.Y8(:, :, j).', 'uint8');
    written = written + fwrite(fid, Cb8(:, :, j).', 'uint8');
    written = written + fwrite(fid, Cr8(:, :, j).', 'uint8');
end
clear closer

if written ~= bytesWritten
    error('writeYuv420:shortWrite', ...
        'Expected to write %d bytes to %s, wrote %d.', ...
        bytesWritten, yuvPath, written);
end

if options.Verbose
    fprintf('[ok] written %s\n', yuvPath);
    fprintf('%d frames x %d bytes (%d Y + %d Cb + %d Cr)\n', ...
        frameCount, planeBytes, yBytes, cbBytes, crBytes);
end
end
