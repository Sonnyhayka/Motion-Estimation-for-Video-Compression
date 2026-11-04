function load = fullSearchLoad(frameSize, mbSize, radius)
%FULLSEARCHLOAD Scalar operation model for luma full search, not CPU profiling.
% frameSize is [height width]. perMB fields are macroblock-grid maps;
% perFrame fields are their sums. fullWindow assumes no border clipping.
% comparisons follows the homework convention: one per candidate. The exact
% minimum reduction needs C-1; minimumComparisons reports that alternative.
% implementation also includes the current distance-based tie selection:
% nRows+nCols squares (each counted as one multiplication), C additions,
% C inequality tests and a second C-1 minimum reduction, even without ties.
% abs is counted separately, not as a comparison or conditional negation.
% Indexing, loop/validation overhead, memory, residuals and decoding excluded.
p = hw3Params();
if nargin < 2 || isempty(mbSize)
    mbSize = p.mbSize;
end
if nargin < 3 || isempty(radius)
    radius = p.searchRadius;
end
validateattributes(frameSize, {'numeric'}, ...
    {'real', 'finite', 'integer', 'positive', 'vector', 'numel', 2});
validateattributes(mbSize, {'numeric'}, ...
    {'real', 'finite', 'integer', 'positive', 'scalar'});
validateattributes(radius, {'numeric'}, ...
    {'real', 'finite', 'integer', 'nonnegative', 'scalar'});
frameSize = double(frameSize(:).');
mbSize = double(mbSize);
radius = double(radius);
if any(mod(frameSize, mbSize) ~= 0)
    error('fullSearchLoad:ragged', ...
        'Frame dimensions must be whole multiples of mbSize.');
end

grid = frameSize / mbSize;
top = (0:grid(1)-1).' * mbSize + 1;
left = (0:grid(2)-1) * mbSize + 1;
% Legal reference-block origins intersect the +/-radius displacement range.
nRows = min(frameSize(1) - mbSize + 1, top + radius) ...
    - max(1, top - radius) + 1;
nCols = min(frameSize(2) - mbSize + 1, left + radius) ...
    - max(1, left - radius) + 1;
candidates = nRows * nCols;

load.frameSize = frameSize;
load.mbSize = mbSize;
load.radius = radius;
load.mbGrid = grid;
load.mbCount = prod(grid);
load.perMB = sadCounts(candidates, mbSize);
load.perFrame = sumCounts(load.perMB);
load.fullWindow.perMB = sadCounts((2 * radius + 1)^2, mbSize);
names = fieldnames(load.fullWindow.perMB);
for k = 1:numel(names)
    name = names{k};
    load.fullWindow.perFrame.(name) = ...
        load.fullWindow.perMB.(name) * load.mbCount;
end

load.implementation.perMB = load.perMB;
load.implementation.perMB.multiplications = nRows + nCols;
load.implementation.perMB.additions = load.perMB.additions + candidates;
load.implementation.perMB.comparisons = 3 * candidates - 2;
% Only the core SAD model uses the alternative minimumComparisons field.
load.implementation.perMB = rmfield(load.implementation.perMB, 'minimumComparisons');
load.implementation.perFrame = sumCounts(load.implementation.perMB);
end

function counts = sadCounts(candidates, mbSize)
counts.candidates = candidates;
counts.multiplications = zeros(size(candidates));
counts.additions = (2 * mbSize^2 - 1) * candidates;
counts.comparisons = candidates;
counts.minimumComparisons = candidates - 1;
counts.absoluteValues = mbSize^2 * candidates;
end

function totals = sumCounts(counts)
names = fieldnames(counts);
for k = 1:numel(names)
    name = names{k};
    totals.(name) = sum(counts.(name), 'all');
end
end
