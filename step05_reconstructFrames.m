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
reconstructedFrames = zeros(size(S.Y, 1), size(S.Y, 2), numel(pIndices));
outputDir = fullfile(projectRoot, 'results', 'frames');

for k = 1:numel(pIndices)
    target = S.Y(:, :, pIndices(k));
    [vectors, ~, ~, residual] = fullSearchFrame(target, reference);
    reconstructedFrames(:, :, k) = reconstructPFrame(reference, vectors, residual);
    maxError = max(abs(reconstructedFrames(:, :, k) - double(target)), [], 'all');
    if maxError ~= 0
        error('step05_reconstructFrames:mismatch', ...
            'Frame %d reconstruction differs from the target by up to %g.', frameNumbers(k), maxError);
    end
    imwrite(uint8(reconstructedFrames(:, :, k)), ...
        fullfile(outputDir, sprintf('reconstructed_frame_%d.png', frameNumbers(k))));
    fprintf('[ok] reconstructed frame %d, maximum error %g\n', frameNumbers(k), maxError);
end
save(fullfile(outputDir, 'reconstructed_frames.mat'), 'reconstructedFrames', 'frameNumbers');
