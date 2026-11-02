function [window, origin] = extractSearchWindow(plane, row, col, mbSize, radius)
p = hw3Params();
if nargin < 4 || isempty(mbSize)
    mbSize = p.mbSize;
end
if nargin < 5 || isempty(radius)
    radius = p.searchRadius;
end

[~, mbOrigin] = extractMacroblock(plane, row, col, mbSize);
validateRadius(radius);

mbSize = double(mbSize);
radius = double(radius);

topRow = max(1, mbOrigin(1) - radius);
leftCol = max(1, mbOrigin(2) - radius);
bottomRow = min(size(plane, 1), mbOrigin(1) + mbSize - 1 + radius);
rightCol = min(size(plane, 2), mbOrigin(2) + mbSize - 1 + radius);

origin = [topRow, leftCol];
window = plane(topRow:bottomRow, leftCol:rightCol);
end

function validateRadius(radius)
if ~isnumeric(radius) || ~isscalar(radius) || ~isfinite(radius) || ...
        radius ~= fix(radius) || radius < 0
    error('extractSearchWindow:badRadius', ...
        'radius must be a single integer of at least 0, got %s.', describeValue(radius));
end
end

function s = describeValue(value)
if isnumeric(value) && ~isempty(value)
    s = mat2str(value);
else
    s = class(value);
end
end
