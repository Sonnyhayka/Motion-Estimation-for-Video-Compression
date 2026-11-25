function [reconstructed, prediction] = reconstructPFrame(reference, motionVectors, residual, mbSize)
% motionVectors(row, col, :) contains [dx dy].
if nargin < 4 || isempty(mbSize)
    p = hw3Params();
    mbSize = p.mbSize;
end
extractMacroblock(reference, 1, 1, mbSize);
mbSize = double(mbSize);
rows = size(reference, 1) / mbSize;
cols = size(reference, 2) / mbSize;
if ~isequal(size(residual), size(reference)) || ...
        ~isequal(size(motionVectors), [rows cols 2])
    error('reconstructPFrame:sizeMismatch', ...
        'Residual or vector dimensions do not match the reference.');
end
if ~isnumeric(motionVectors) || ~isreal(motionVectors) || ...
        any(~isfinite(motionVectors(:))) || any(motionVectors(:) ~= fix(motionVectors(:)))
    error('reconstructPFrame:badVectors', ...
        'Motion vectors must be finite integer offsets.');
end
prediction = zeros(size(reference), 'like', reference);
for row = 1:rows
    for col = 1:cols
        top = (row - 1) * mbSize + 1;
        left = (col - 1) * mbSize + 1;
        sourceTop = top + double(motionVectors(row, col, 2));
        sourceLeft = left + double(motionVectors(row, col, 1));
        if sourceTop < 1 || sourceLeft < 1 || ...
                sourceTop + mbSize - 1 > size(reference, 1) || ...
                sourceLeft + mbSize - 1 > size(reference, 2)
            error('reconstructPFrame:vectorOutOfBounds', ...
                'Motion vector points outside the reference.');
        end
        prediction(top:top + mbSize - 1, left:left + mbSize - 1) = ...
            reference(sourceTop:sourceTop + mbSize - 1, ...
            sourceLeft:sourceLeft + mbSize - 1);
    end
end
reconstructed = double(prediction) + double(residual);
end
