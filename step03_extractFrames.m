clearvars -except projectRoot
clc

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end
projectRoot = scriptDir;
addpath(fullfile(projectRoot, 'src'));

projectRoot = setupProject();
videoPath = fullfile(projectRoot, 'data', 'walk_qcif.avi');

tic;
p = hw3Params();
S = loadWalkSequence(videoPath, p.frameNumbers);
elapsed = toc;

info = S.videoInfo;

fprintf('\nSource\n');
fprintf('[ok] source      %s\n', relativePath(info.path, projectRoot));
fprintf('                %d frames, %g fps, %.2f s, %dx%d, %s (bpp %d)\n', ...
    info.numFrames, info.frameRate, info.duration, ...
    info.width, info.height, info.videoFormat, info.bitsPerPixel);

fprintf('\nExtracted frames\n');
fprintf('[ok] extracted   frames %s, %d frames, %dx%d each\n', ...
    mat2str(S.frameNumbers), S.frameCount, info.height, info.width);
fprintf('[ok] structure   %s (GOP %d anchored at frame %d)\n', ...
    strjoin(S.frameTypes, ''), p.gopSize, p.gopAnchor);
fprintf('[ok] i frame     frame %s, reference for every P frame\n', ...
    mat2str(S.iFrame));
fprintf('[ok] p frames    frames %s, all predicted from frame %d\n', ...
    mat2str(S.pFrames), S.iFrame(1));
fprintf('[ok] luma        Y  : %dx%d double, range %g to %g\n', ...
    size(S.Y, 1), size(S.Y, 2), min(S.Y, [], 'all'), max(S.Y, [], 'all'));
fprintf('[ok] chroma      Cb : %dx%d   Cr : %dx%d  (%s)\n', ...
    size(S.Cb420, 1), size(S.Cb420, 2), ...
    size(S.Cr420, 1), size(S.Cr420, 2), p.chromaFormat);
fprintf('[ok] mb grid     %d cols x %d rows = %d macroblocks per frame (%dx%d)\n', ...
    S.mbGrid.cols, S.mbGrid.rows, S.mbGrid.count, p.mbSize, p.mbSize);

fprintf('\nFrame types\n');
fprintf(' frame   type   reference\n');
for j = 1:S.frameCount
    if strcmp(S.frameTypes{j}, 'I')
        ref = 'none';
    else
        ref = sprintf('%d', S.iFrame(1));
    end
    fprintf(' %5d   %-4s   %s\n', S.frameNumbers(j), S.frameTypes{j}, ref);
end

yuvDir = fullfile(projectRoot, 'results', 'yuv');
yuvPath = fullfile(yuvDir, sprintf('walk_f%d_%d_yuv420p.yuv', ...
    S.frameNumbers(1), S.frameNumbers(end)));
bytesWritten = writeYuv420(S, yuvPath);

expectedBytes = size(S.Y, 1) * size(S.Y, 2) * 1.5 * S.frameCount;
if bytesWritten ~= expectedBytes
    error('step03_extractFrames:byteCount', ...
        'Expected %d bytes for %d QCIF frames, wrote %d.', ...
        expectedBytes, S.frameCount, bytesWritten);
end

fprintf('[ok] yuv420p     %s\n', relativePath(yuvPath, projectRoot));
fprintf('[ok] bytes       %d total = %d bytes per frame x %d frames\n', ...
    bytesWritten, bytesWritten / S.frameCount, S.frameCount);

fprintf('\nNext: exhaustive search over a %dx%d window with %dx%d macroblocks.\n\n', ...
    p.searchWindow, p.searchWindow, p.mbSize, p.mbSize);

function p = relativePath(absPath, root)
p = absPath;
prefix = [root filesep];
if strncmpi(absPath, prefix, numel(prefix))
    p = absPath(numel(prefix) + 1:end);
end
p = strrep(p, filesep, '/');
end
