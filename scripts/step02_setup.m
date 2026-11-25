clearvars -except projectRoot
clc

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = fullfile(pwd, 'scripts');
end
addpath(fullfile(fileparts(scriptDir), 'src'));
projectRoot = setupProject();
videoPath = fullfile(projectRoot, 'data', 'walk_qcif.avi');

tic;
p = hw3Params();
S = loadWalkSequence(videoPath, p.frameNumbers);
elapsed = toc;

info = S.videoInfo;

fprintf('\nSource\n');
fprintf('[ok] source %s\n', relativePath(info.path, projectRoot));
fprintf('%d frames, %g fps, %.2f s, %dx%d, %s (bpp %d)\n', ...
    info.numFrames, info.frameRate, info.duration, ...
    info.width, info.height, info.videoFormat, info.bitsPerPixel);

fprintf('\nExtracted frames\n');
fprintf('[ok] extracted frames %s, %d frames, %dx%d each\n', ...
    mat2str(S.frameNumbers), S.frameCount, info.height, info.width);
fprintf('[ok] luma Y: %dx%d double, range %g to %g\n', ...
    size(S.Y, 1), size(S.Y, 2), min(S.Y, [], 'all'), max(S.Y, [], 'all'));
fprintf('[ok] chroma Cb: %dx%d Cr: %dx%d (%s)\n', ...
    size(S.Cb420, 1), size(S.Cb420, 2), ...
    size(S.Cr420, 1), size(S.Cr420, 2), p.chromaFormat);
fprintf('[ok] mb grid %d cols x %d rows = %d macroblocks per frame (%dx%d)\n', ...
    S.mbGrid.cols, S.mbGrid.rows, S.mbGrid.count, p.mbSize, p.mbSize);

fprintf('\nSpec from CompE 565_HW3.pdf\n');
fprintf('[spec] window %dx%d centered, so w = %g\n', ...
    p.searchWindow, p.searchWindow, p.searchRadius);
fprintf('[spec] candidates (2w+1)^2 = %d per macroblock\n', p.candidates);
fprintf('[spec] cost %d x %d = %d adds per macroblock\n', ...
    p.candidates, p.addsPerCandidate, p.candidates * p.addsPerCandidate);
fprintf('[spec] structure I%s, GOP %d\n', ...
    repmat('P', 1, p.gopSize - 1), p.gopSize);
fprintf('[spec] reference all P frames predicted from the I frame (frame %d)\n', ...
    p.frameNumbers(p.iFrameIndex));

fprintf('\nPer frame luma\n');
fprintf('frame mean std min max\n');
for j = 1:S.frameCount
    y = S.Y(:, :, j);
    fprintf('%d %.2f %.2f %.0f %.0f\n', ...
        S.frameNumbers(j), mean(y, 'all'), std(y, 0, 'all'), ...
        min(y, [], 'all'), max(y, [], 'all'));
end

frameDir = fullfile(projectRoot, 'results', 'frames');

for j = 1:S.frameCount
    n = S.frameNumbers(j);
    imwrite(S.Y8(:, :, j), fullfile(frameDir, sprintf('f%02d_Y.png', n)));
    imwrite(S.rgb(:, :, :, j), fullfile(frameDir, sprintf('f%02d_RGB.png', n)));
end

fprintf('\n[ok] written results/frames/f%02d_Y.png to f%02d_Y.png plus RGB\n', ...
    S.frameNumbers(1), S.frameNumbers(end));
fprintf('[ok] loaded %d frames in %.3f s\n', S.frameCount, elapsed);
