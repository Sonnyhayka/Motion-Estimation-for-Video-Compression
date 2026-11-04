function [motionVectors, matchedFrame, minSads] = fullSearchFrame(target, reference, mbSize, radius)
%FULLSEARCHFRAME Match every target macroblock against the reference plane.
% motionVectors(row,col,:) contains [dx dy]. matchedFrame places each
% selected reference block at its target-grid position. minSads is indexed
% by macroblock row and column.
p = hw3Params();
if nargin < 3 || isempty(mbSize)
    mbSize = p.mbSize;
end
if nargin < 4 || isempty(radius)
    radius = p.searchRadius;
end

if ~isequal(size(target), size(reference))
    error('fullSearchFrame:sizeMismatch', ...
        'target and reference must be the same size.');
end

% Validate the plane and block size before deriving the grid dimensions.
extractMacroblock(target, 1, 1, mbSize);
mbSize = double(mbSize);
mbRows = size(target, 1) / mbSize;
mbCols = size(target, 2) / mbSize;
motionVectors = zeros(mbRows, mbCols, 2);
minSads = zeros(mbRows, mbCols);
matchedFrame = zeros(size(reference), 'like', reference);

for row = 1:mbRows
    for col = 1:mbCols
        [mv, minSads(row, col)] = fullSearchMacroblock( ...
            target, reference, row, col, mbSize, radius);
        motionVectors(row, col, :) = reshape(mv, 1, 1, 2);
        top = (row - 1) * mbSize + 1;
        left = (col - 1) * mbSize + 1;
        matchedFrame(top:top + mbSize - 1, left:left + mbSize - 1) = ...
            reference(top + mv(2):top + mv(2) + mbSize - 1, ...
                      left + mv(1):left + mv(1) + mbSize - 1);
    end
end
end
