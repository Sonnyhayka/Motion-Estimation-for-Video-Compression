function [mv, minSad, sadMap] = fullSearchMacroblock(target, reference, row, col, mbSize, radius)
p = hw3Params();
if nargin < 5 || isempty(mbSize)
    mbSize = p.mbSize;
end
if nargin < 6 || isempty(radius)
    radius = p.searchRadius;
end

if ~isequal(size(target), size(reference))
    error('fullSearchMacroblock:sizeMismatch', ...
        'target is %s but reference is %s, they must be the same size.', ...
        mat2str(size(target)), mat2str(size(reference)));
end

[block, mbOrigin] = extractMacroblock(target, row, col, mbSize);
[window, winOrigin] = extractSearchWindow(reference, row, col, mbSize, radius);

block = double(block);
window = double(window);
mbSize = double(mbSize);

nRows = size(window, 1) - mbSize + 1;
nCols = size(window, 2) - mbSize + 1;

sadMap = zeros(nRows, nCols);
for r = 1:nRows
    for c = 1:nCols
        candidate = window(r:r + mbSize - 1, c:c + mbSize - 1);
        sadMap(r, c) = sum(abs(block(:) - candidate(:)));
    end
end

dy = winOrigin(1) - mbOrigin(1) + (0:nRows - 1).';
dx = winOrigin(2) - mbOrigin(2) + (0:nCols - 1);

minSad = min(sadMap(:));
distance = dy .^ 2 + dx .^ 2;
distance(sadMap ~= minSad) = Inf;
[~, best] = min(distance(:));
[r, c] = ind2sub(size(sadMap), best);

mv = [dx(c), dy(r)];
end
