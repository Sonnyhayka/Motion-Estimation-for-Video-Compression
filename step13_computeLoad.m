clearvars -except projectRoot
clc

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end
addpath(fullfile(scriptDir, 'src'));
projectRoot = setupProject();
p = hw3Params();
video = VideoReader(fullfile(projectRoot, 'data', 'walk_qcif.avi'));
loadCounts = fullSearchLoad([video.Height video.Width], p.mbSize, p.searchRadius);

% Per-block CSV follows the same row/column grid as the motion vectors.
[rows, cols] = ndgrid(1:loadCounts.mbGrid(1), 1:loadCounts.mbGrid(2));
b = loadCounts.perMB;
perMB = table(rows(:), cols(:), b.candidates(:), b.multiplications(:), ...
    b.additions(:), b.comparisons(:), b.minimumComparisons(:), b.absoluteValues(:), ...
    'VariableNames', {'MBRow', 'MBCol', 'Candidates', 'Multiplications', ...
    'AdditionsSubtractions', 'Comparisons', 'MinimumComparisons', 'AbsoluteValues'});
models = {'Full-window SAD'; 'Clipped SAD'; 'Clipped SAD plus tie selection'};
counts = [loadCounts.fullWindow.perFrame; loadCounts.perFrame; ...
    addMinimumField(loadCounts.implementation.perFrame)];
perFrame = table(models, [counts.candidates].', [counts.multiplications].', ...
    [counts.additions].', [counts.comparisons].', [counts.absoluteValues].', ...
    'VariableNames', {'Model', 'Candidates', 'Multiplications', ...
    'AdditionsSubtractions', 'Comparisons', 'AbsoluteValues'});
disp(perFrame);
fprintf('Per P-frame: %d x %d macroblocks = %d (Y only).\n', ...
    loadCounts.mbGrid(1), loadCounts.mbGrid(2), loadCounts.mbCount);
fprintf('SAD comparisons use one per candidate, as in the homework.\n');
fprintf('Clipped SAD minimum alone needs %d comparisons (C-1 per MB).\n', ...
    loadCounts.perFrame.minimumComparisons);
fprintf('Tie selection uses scalar square/multiply and comparison equivalents.\n');
fprintf('abs is separate; indexing, loops, residuals and decoding are excluded.\n');
fprintf('The same counts apply to each of P-frames %s; I-frame search cost is zero.\n', ...
    mat2str(p.pFrames));

outputDir = fullfile(projectRoot, 'results', 'frames');
writetable(perMB, fullfile(outputDir, 'full_search_load_per_mb.csv'));
writetable(perFrame, fullfile(outputDir, 'full_search_load_per_frame.csv'));
save(fullfile(outputDir, 'full_search_load.mat'), 'loadCounts', 'perMB', 'perFrame', 'p');
fprintf('[ok] saved operation counts in results/frames/\n');

function counts = addMinimumField(counts)
% Align struct fields for the display table; comparisons already includes
% both minimum reductions and the tie mask for this model.
counts.minimumComparisons = NaN;
counts = orderfields(counts, {'candidates', 'multiplications', 'additions', ...
    'comparisons', 'minimumComparisons', 'absoluteValues'});
end
