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
reference = S.Y(:, :, S.referenceIndex);
pIndices = find(strcmp(S.frameTypes, 'P'));
frameNumbers = S.frameNumbers(pIndices);
residuals = zeros(size(S.Y, 1), size(S.Y, 2), numel(pIndices));
outputDir = fullfile(projectRoot, 'results', 'frames');

for k = 1:numel(pIndices)
    target = S.Y(:, :, pIndices(k));
    [~, ~, ~, residuals(:, :, k)] = fullSearchFrame(target, reference);
    % Fixed display scale only; the MAT file retains the signed differences.
    preview = uint8(round((residuals(:, :, k) + 255) / 2));
    imwrite(preview, fullfile(outputDir, sprintf('residual_frame_%d.png', frameNumbers(k))));
    fprintf('[ok] residual frame %d, range %g to %g\n', frameNumbers(k), ...
        min(residuals(:, :, k), [], 'all'), max(residuals(:, :, k), [], 'all'));
end

save(fullfile(outputDir, 'residual_frames.mat'), 'residuals', 'frameNumbers');
