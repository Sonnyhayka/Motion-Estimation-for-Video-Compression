function counts = fullSearchLoad(frameSize, mbSize, radius)
% frameSize is [height width]; see docs/computational_load.md.
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
nRows = min(frameSize(1) - mbSize + 1, top + radius) ...
    - max(1, top - radius) + 1;
nCols = min(frameSize(2) - mbSize + 1, left + radius) ...
    - max(1, left - radius) + 1;
candidates = nRows * nCols;

counts.frameSize = frameSize;
counts.mbSize = mbSize;
counts.radius = radius;
counts.mbGrid = grid;
counts.mbCount = prod(grid);
counts.perMB = sadCounts(candidates, mbSize);
counts.perFrame = sumCounts(counts.perMB);
counts.fullWindow.perMB = sadCounts((2 * radius + 1)^2, mbSize);
names = fieldnames(counts.fullWindow.perMB);
for k = 1:numel(names)
    name = names{k};
    counts.fullWindow.perFrame.(name) = ...
        counts.fullWindow.perMB.(name) * counts.mbCount;
end

counts.implementation.perMB = counts.perMB;
counts.implementation.perMB.multiplications = nRows + nCols;
counts.implementation.perMB.additions = counts.perMB.additions + candidates;
counts.implementation.perMB.comparisons = 3 * candidates - 2;
counts.implementation.perMB = rmfield(counts.implementation.perMB, 'minimumComparisons');
counts.implementation.perFrame = sumCounts(counts.implementation.perMB);
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
