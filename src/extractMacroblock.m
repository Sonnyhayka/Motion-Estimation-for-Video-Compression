function [block, origin] = extractMacroblock(plane, row, col, mbSize)
if nargin < 4 || isempty(mbSize)
    p = hw3Params();
    mbSize = p.mbSize;
end

validatePlane(plane);
validateSize(mbSize);
validateIndex(row, 'row');
validateIndex(col, 'col');

row = double(row);
col = double(col);
mbSize = double(mbSize);

height = size(plane, 1);
width = size(plane, 2);
if mod(height, mbSize) ~= 0 || mod(width, mbSize) ~= 0
    error('extractMacroblock:ragged', ...
        ['A %dx%d plane is not a whole number of %dx%d macroblocks.\n' ...
         '4:2:0 chroma planes are half size, so they take half the macroblock size.'], ...
        height, width, mbSize, mbSize);
end

mbRows = height / mbSize;
mbCols = width / mbSize;

if row > mbRows || col > mbCols
    error('extractMacroblock:outOfRange', ...
        'Macroblock (%s,%s) is outside the %dx%d grid of a %dx%d plane with %dx%d blocks.', ...
        describeValue(row), describeValue(col), mbRows, mbCols, height, width, mbSize, mbSize);
end

topRow = (row - 1) * mbSize + 1;
leftCol = (col - 1) * mbSize + 1;
origin = [topRow, leftCol];
block = plane(topRow:topRow + mbSize - 1, leftCol:leftCol + mbSize - 1);
end

function validatePlane(plane)
if ~isnumeric(plane)
    error('extractMacroblock:badPlane', ...
        'plane must be numeric, got %s.', class(plane));
end
if isempty(plane)
    error('extractMacroblock:badPlane', 'plane must not be empty.');
end
if ~ismatrix(plane)
    error('extractMacroblock:badPlane', ...
        'plane must be 2-D, got %d dimensions.', ndims(plane));
end
end

function validateSize(mbSize)
if ~isnumeric(mbSize) || ~isscalar(mbSize) || ~isfinite(mbSize) || ...
        mbSize ~= fix(mbSize) || mbSize < 1
    error('extractMacroblock:badSize', ...
        'mbSize must be a single positive integer, got %s.', describeValue(mbSize));
end
end

function validateIndex(value, name)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || ...
        value ~= fix(value) || value < 1
    error('extractMacroblock:badIndex', ...
        '%s must be a single positive integer, got %s.', name, describeValue(value));
end
end

function s = describeValue(value)
if isnumeric(value) && ~isempty(value)
    s = mat2str(value);
else
    s = class(value);
end
end
