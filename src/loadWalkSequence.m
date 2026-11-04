function S = loadWalkSequence(videoPath, frameIndices)
if nargin < 1 || isempty(videoPath)
    here = fileparts(mfilename('fullpath'));
    videoPath = resolveVideoPath(fileparts(here));
end
if nargin < 2 || isempty(frameIndices)
    p = hw3Params();
    frameIndices = p.frameNumbers;
end

frameIndices = frameIndices(:).';

if ~isnumeric(frameIndices) || isempty(frameIndices) || ...
        any(~isfinite(frameIndices)) || any(frameIndices < 1) || ...
        any(frameIndices ~= fix(frameIndices))
    error('loadWalkSequence:badIndices', ...
        'frameIndices must be a non-empty vector of positive integers.');
end
if any(diff(frameIndices) <= 0)
    error('loadWalkSequence:badIndices', ...
        'frameIndices must be strictly increasing.');
end
if ~isfile(videoPath)
    error('loadWalkSequence:missingVideo', ...
        'Video file not found:\n %s\nRun setupProject first, or pass an explicit path.', ...
        videoPath);
end

reader = VideoReader(videoPath);
width = reader.Width;
height = reader.Height;

nWant = numel(frameIndices);
frames = cell(1, nWant);
lastWanted = frameIndices(end);

k = 0;
while hasFrame(reader) && k < lastWanted
    img = readFrame(reader);
    k = k + 1;
    j = find(frameIndices == k, 1);
    if ~isempty(j)
        frames{j} = img;
    end
end

totalFrames = k;

missing = find(cellfun(@isempty, frames));
if ~isempty(missing)
    error('loadWalkSequence:shortSequence', ...
        ['Could not read frame(s) %s. The clip only has %d frame(s).\n' ...
        'HW3 needs frames 16 to 20 of walk_qcif.'], ...
        mat2str(frameIndices(missing)), totalFrames);
end

if height ~= 144 || width ~= 176
    error('loadWalkSequence:badGeometry', ...
        'Expected a 176x144 QCIF frame, got %dx%d.', width, height);
end
if ndims(frames{1}) ~= 3 || size(frames{1}, 3) ~= 3
    error('loadWalkSequence:notColour', ...
        ['Expected RGB frames with 3 colour planes, got %s.\n' ...
        'Motion estimation is done on luma and needs the colour frame.'], ...
        mat2str(size(frames{1})));
end

rgb = zeros(height, width, 3, nWant, 'uint8');
Y = zeros(height, width, nWant);
Cb420 = zeros(height / 2, width / 2, nWant);
Cr420 = zeros(height / 2, width / 2, nWant);

for j = 1:nWant
    rgb(:, :, :, j) = frames{j};

    ycbcr = rgb2ycbcr(frames{j});
    Y(:, :, j) = double(ycbcr(:, :, 1));
    Cb420(:, :, j) = subsample420(ycbcr(:, :, 2));
    Cr420(:, :, j) = subsample420(ycbcr(:, :, 3));
end

Y8 = uint8(round(Y));

p = hw3Params();
mbSize = p.mbSize;
mbRows = floor(height / mbSize);
mbCols = floor(width / mbSize);
mbGrid = struct( ...
    'size', mbSize, ...
    'rows', mbRows, ...
    'cols', mbCols, ...
    'count', mbRows * mbCols);

reportedFrames = reader.NumFrames;
if ~isscalar(reportedFrames) || ~isfinite(reportedFrames) || reportedFrames < totalFrames
    reportedFrames = totalFrames;
end

frameTypes = frameTypesFor(frameIndices, p.gopAnchor, p.gopSize);
iFrame = frameIndices(strcmp(frameTypes, 'I'));
pFrames = frameIndices(strcmp(frameTypes, 'P'));
if isempty(iFrame)
    error('loadWalkSequence:noIFrame', ...
        ['Frames %s contain no I frame.\n' ...
        'With GOP %d anchored at frame %d, I frames fall on frames %d, %d, ...'], ...
        mat2str(frameIndices), p.gopSize, p.gopAnchor, ...
        p.gopAnchor, p.gopAnchor + p.gopSize);
end
referenceIndex = find(frameIndices == iFrame(1), 1);

videoInfo = struct( ...
    'path', whichPath(videoPath), ...
    'frameRate', reader.FrameRate, ...
    'duration', reader.Duration, ...
    'numFrames', reportedFrames, ...
    'width', width, ...
    'height', height, ...
    'bitsPerPixel', reader.BitsPerPixel, ...
    'videoFormat', reader.VideoFormat);

S = struct( ...
    'frameNumbers', frameIndices, ...
    'frameCount', nWant, ...
    'frameTypes', {frameTypes}, ...
    'iFrame', iFrame, ...
    'pFrames', pFrames, ...
    'referenceIndex', referenceIndex, ...
    'rgb', rgb, ...
    'Y', Y, ...
    'Y8', Y8, ...
    'Cb420', Cb420, ...
    'Cr420', Cr420, ...
    'mbGrid', mbGrid, ...
    'videoInfo', videoInfo);
end

function out = subsample420(plane)
plane = double(plane);
out = 0.25 * (plane(1:2:end, 1:2:end) + plane(1:2:end, 2:2:end) ...
    + plane(2:2:end, 1:2:end) + plane(2:2:end, 2:2:end));
end

function p = whichPath(videoPath)
try
    p = char(java.io.File(videoPath).getCanonicalPath());
catch
    p = videoPath;
end
end

function videoPath = resolveVideoPath(root)
candidates = { ...
    fullfile(root, 'data', 'walk_qcif.avi'), ...
    fullfile(root, 'walk_qcif.avi')};

videoPath = candidates{1};
for k = 1:numel(candidates)
    if isfile(candidates{k})
        videoPath = candidates{k};
        return
    end
end
end
