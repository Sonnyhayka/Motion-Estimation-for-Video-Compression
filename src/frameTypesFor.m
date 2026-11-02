function types = frameTypesFor(frameNumbers, anchor, gopSize)
if ~isnumeric(frameNumbers) || isempty(frameNumbers) || ...
        any(~isfinite(frameNumbers)) || any(frameNumbers ~= fix(frameNumbers))
    error('frameTypesFor:badFrames', ...
        'frameNumbers must be a non-empty vector of integers.');
end
if ~isscalar(anchor) || ~isfinite(anchor) || anchor ~= fix(anchor)
    error('frameTypesFor:badAnchor', ...
        'anchor must be a single integer frame number.');
end
if ~isscalar(gopSize) || ~isfinite(gopSize) || gopSize < 1 || gopSize ~= fix(gopSize)
    error('frameTypesFor:badGopSize', ...
        'gopSize must be a positive integer.');
end

types = repmat({'P'}, size(frameNumbers));
types(mod(frameNumbers - anchor, gopSize) == 0) = {'I'};
end
