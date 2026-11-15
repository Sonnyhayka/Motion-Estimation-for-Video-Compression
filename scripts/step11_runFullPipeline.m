clearvars -except projectRoot
clc

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = fullfile(pwd, 'scripts');
end
addpath(fullfile(fileparts(scriptDir), 'src'));
projectRoot = setupProject();
p = hw3Params();
S = loadWalkSequence(fullfile(projectRoot, 'data', 'walk_qcif.avi'), p.frameNumbers);
referenceFrameNumber = S.frameNumbers(S.referenceIndex);
reference = S.Y(:, :, S.referenceIndex);
pIndices = find(strcmp(S.frameTypes, 'P'));
frameNumbers = S.frameNumbers(pIndices);
frameDir = fullfile(projectRoot, 'results', 'frames');
figureDir = fullfile(projectRoot, 'results', 'figures');

writeYuv420(S, fullfile(projectRoot, 'results', 'yuv', 'walk_f16_20_yuv420p.yuv'));
for j = 1:S.frameCount
    imwrite(S.Y8(:, :, j), fullfile(frameDir, sprintf('f%02d_Y.png', S.frameNumbers(j))));
    imwrite(S.rgb(:, :, :, j), fullfile(frameDir, sprintf('f%02d_RGB.png', S.frameNumbers(j))));
end

nP = numel(pIndices);
targetFrames = S.Y(:, :, pIndices);
matchedFrames = zeros(size(targetFrames));
residuals = zeros(size(targetFrames));
reconstructedFrames = zeros(size(targetFrames));
motionVectors = zeros(S.mbGrid.rows, S.mbGrid.cols, 2, nP);
minSads = zeros(S.mbGrid.rows, S.mbGrid.cols, nP);
maxErrors = zeros(nP, 1);
totalSads = zeros(nP, 1);
[x, y] = meshgrid((0:S.mbGrid.cols-1) * p.mbSize + (p.mbSize + 1) / 2, ...
    (0:S.mbGrid.rows-1) * p.mbSize + (p.mbSize + 1) / 2);

for k = 1:nP
    n = frameNumbers(k);
    target = targetFrames(:, :, k);
    [motionVectors(:, :, :, k), matchedFrames(:, :, k), ...
        minSads(:, :, k), residuals(:, :, k)] = fullSearchFrame( ...
        target, reference, p.mbSize, p.searchRadius);
    [reconstructedFrames(:, :, k), decodedPrediction] = reconstructPFrame( ...
        reference, motionVectors(:, :, :, k), residuals(:, :, k), p.mbSize);
    maxErrors(k) = max(abs(reconstructedFrames(:, :, k) - target), [], 'all');
    totalSads(k) = sum(minSads(:, :, k), 'all');
    if maxErrors(k) ~= 0 || ~isequal(decodedPrediction, matchedFrames(:, :, k))
        error('step11_runFullPipeline:mismatch', ...
            'Frame %d did not decode exactly from reference frame %d.', n, referenceFrameNumber);
    end
    if sum(abs(residuals(:, :, k)), 'all') ~= totalSads(k)
        error('step11_runFullPipeline:sadMismatch', ...
            'Frame %d residual does not agree with its block SAD values.', n);
    end

    imwrite(uint8(target), fullfile(frameDir, sprintf('target_frame_%d.png', n)));
    imwrite(uint8(round((residuals(:, :, k) + 255) / 2)), ...
        fullfile(frameDir, sprintf('residual_frame_%d.png', n)));
    imwrite(uint8(reconstructedFrames(:, :, k)), ...
        fullfile(frameDir, sprintf('reconstructed_frame_%d.png', n)));

    savePlaneFigure(target, [0 255], sprintf('Frame %d target (luma)', n), ...
        fullfile(figureDir, sprintf('target_frame_%d', n)));
    savePlaneFigure(residuals(:, :, k), [-255 255], ...
        sprintf('Frame %d residual: target - prediction (reference %d)', n, referenceFrameNumber), ...
        fullfile(figureDir, sprintf('error_frame_%d', n)), true);
    savePlaneFigure(reconstructedFrames(:, :, k), [0 255], ...
        sprintf('Frame %d reconstructed (maximum error %g)', n, maxErrors(k)), ...
        fullfile(figureDir, sprintf('reconstructed_frame_%d', n)));
    saveMotionFigure(target, x, y, motionVectors(:, :, :, k), ...
        sprintf('Frame %d motion vectors (reference frame %d)', n, referenceFrameNumber), ...
        fullfile(figureDir, sprintf('motion_vectors_frame_%d', n)));
    fprintf('[ok] P-frame %d <- I-frame %d: %d vectors, SAD %g, maximum reconstruction error %g\n', ...
        n, referenceFrameNumber, S.mbGrid.count, totalSads(k), maxErrors(k));
end

save(fullfile(frameDir, 'residual_frames.mat'), 'residuals', 'frameNumbers', 'referenceFrameNumber');
save(fullfile(frameDir, 'reconstructed_frames.mat'), 'reconstructedFrames', ...
    'frameNumbers', 'referenceFrameNumber');
save(fullfile(figureDir, 'motion_vectors.mat'), 'motionVectors', 'frameNumbers', 'referenceFrameNumber');
save(fullfile(frameDir, 'pipeline_results.mat'), 'reference', 'referenceFrameNumber', ...
    'frameNumbers', 'targetFrames', 'motionVectors', 'matchedFrames', 'minSads', ...
    'residuals', 'reconstructedFrames', 'maxErrors', 'p');
summary = table(frameNumbers(:), repmat(referenceFrameNumber, nP, 1), totalSads, maxErrors, ...
    'VariableNames', {'TargetFrame', 'ReferenceFrame', 'TotalSAD', 'MaxReconstructionError'});
writetable(summary, fullfile(frameDir, 'pipeline_summary.csv'));
fprintf('[ok] saved %d PNG figures and %d editable FIG files in results/figures/\n', 4*nP, 4*nP);
fprintf('[ok] saved source, target, residual, reconstruction and numeric results in results/frames/\n');

function savePlaneFigure(plane, limits, caption, outputBase, signedError)
if nargin < 5
    signedError = false;
end
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 800 600]);
cleanup = onCleanup(@() close(fig));
ax = axes('Parent', fig);
imagesc(ax, plane, limits);
set(ax, 'XColor', 'k', 'YColor', 'k');
colormap(ax, gray(256));
axis(ax, 'image');
title(ax, caption, 'Color', 'k');
xlabel(ax, 'Column (pixels)', 'Color', 'k');
ylabel(ax, 'Row (pixels)', 'Color', 'k');
if signedError
    bar = colorbar(ax);
    bar.Color = 'k';
    bar.Label.String = 'Signed luma difference (zero = mid-gray)';
end
exportgraphics(fig, [outputBase '.png'], 'Resolution', 150);
savefig(fig, [outputBase '.fig']);
end

function saveMotionFigure(target, x, y, vectors, caption, outputBase)
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 800 600]);
cleanup = onCleanup(@() close(fig));
ax = axes('Parent', fig);
imagesc(ax, target, [0 255]);
colormap(ax, gray(256));
axis(ax, 'image');
set(ax, 'YDir', 'reverse', 'XColor', 'k', 'YColor', 'k');
hold(ax, 'on');
quiver(ax, x, y, vectors(:, :, 1), vectors(:, :, 2), 0, 'r', 'LineWidth', 1);
title(ax, caption, 'Color', 'k');
xlabel(ax, 'Column (pixels)', 'Color', 'k');
ylabel(ax, 'Row (pixels)', 'Color', 'k');
exportgraphics(fig, [outputBase '.png'], 'Resolution', 150);
savefig(fig, [outputBase '.fig']);
end
