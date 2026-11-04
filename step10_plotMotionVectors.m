clearvars -except projectRoot
clc

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end
addpath(fullfile(scriptDir, 'src'));
projectRoot = setupProject();
p = hw3Params();
S = loadWalkSequence(fullfile(projectRoot, 'data', 'walk_qcif.avi'), p.frameNumbers);
reference = S.Y(:, :, S.referenceIndex);
pIndices = find(strcmp(S.frameTypes, 'P'));
frameNumbers = S.frameNumbers(pIndices);
outputDir = fullfile(projectRoot, 'results', 'figures');
mbRows = size(reference, 1) / p.mbSize;
mbCols = size(reference, 2) / p.mbSize;
motionVectors = zeros(mbRows, mbCols, 2, numel(pIndices));
[x, y] = meshgrid((0:mbCols-1) * p.mbSize + (p.mbSize + 1) / 2, ...
    (0:mbRows-1) * p.mbSize + (p.mbSize + 1) / 2);

for k = 1:numel(pIndices)
    target = S.Y(:, :, pIndices(k));
    motionVectors(:, :, :, k) = fullSearchFrame(target, reference);
    fig = figure('Visible', 'off', 'Color', 'w');
    ax = axes('Parent', fig);
    imagesc(ax, target, [0 255]);
    colormap(ax, gray(256));
    axis(ax, 'image');
    set(ax, 'YDir', 'reverse');
    hold(ax, 'on');
    quiver(ax, x, y, motionVectors(:, :, 1, k), motionVectors(:, :, 2, k), ...
        0, 'r', 'LineWidth', 1);
    title(ax, sprintf('Frame %d motion vectors (reference frame %d)', ...
        frameNumbers(k), S.frameNumbers(S.referenceIndex)));
    xlabel(ax, 'Column (pixels)');
    ylabel(ax, 'Row (pixels)');
    exportgraphics(fig, fullfile(outputDir, ...
        sprintf('motion_vectors_frame_%d.png', frameNumbers(k))), 'Resolution', 150);
    close(fig);
    fprintf('[ok] plotted motion vectors for frame %d\n', frameNumbers(k));
end
save(fullfile(outputDir, 'motion_vectors.mat'), 'motionVectors', 'frameNumbers');
