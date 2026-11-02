function bytesWritten = writeYuv420(S, yuvPath, options)
arguments
    S struct
    yuvPath (1, :) char
    options.Verbose (1, 1) logical = true
end

frameCount = size(S.Y8, 3);
Cb8 = uint8(round(S.Cb420));
Cr8 = uint8(round(S.Cr420));
yBytes = size(S.Y8, 1) * size(S.Y8, 2);
cbBytes = size(Cb8, 1) * size(Cb8, 2);
crBytes = size(Cr8, 1) * size(Cr8, 2);
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
    fprintf('[ok] written     %s\n', yuvPath);
    fprintf('                %d frames x %d bytes (%d Y + %d Cb + %d Cr)\n', ...
        frameCount, planeBytes, yBytes, cbBytes, crBytes);
end
end
