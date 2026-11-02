function S = loadWalkSequence(videoPath, frameIndices)
%LOADWALKSEQUENCE Read walk_qcif and extract the frames used in HW3.
%
% S = loadWalkSequence() extracts frames 16 to 20 of data/walk_qcif.avi.
% S = loadWalkSequence(VIDEOPATH, FRAMEINDICES) extracts a custom subset.
%
% Returns a struct with fields:
% frameNumbers source frame indices, default [16 17 18 19 20]
% frameCount number of frames returned
% rgb HxWx3xN uint8 colour frames
% Y HxWxN double luma
% Y8 HxWxN uint8 luma
% Cb420, Cr420 H/2xW/2xN double 4:2:0 chroma
% mbGrid rows, cols, count for 16x16 macroblocks
% videoInfo source file metadata
%
% See also setupProject.

% Defaults
if nargin < 1 || isempty(videoPath)
    here = fileparts(mfilename('fullpath'));
    videoPath = fullfile(here, '..', 'data', 'walk_qcif.avi');
end
if nargin < 2 || isempty(frameIndices)
    p = hw3Params();
    frameIndices = p.frameNumbers;
end

frameIndices = frameIndices(:).';

% Argument checks
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

% Read frames sequentially up to the last requested index
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

% QCIF geometry check
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

% Split into luma and 4:2:0 chroma
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

% 16x16 macroblock grid
p = hw3Params();
mbSize = p.mbSize;
mbRows = floor(height / mbSize);
mbCols = floor(width / mbSize);
mbGrid = struct( ...
    'size', mbSize, ...
    'rows', mbRows, ...
    'cols', mbCols, ...
    'count', mbRows * mbCols);

% Metadata. NumFrames is not populated for every container, so fall back to
% the number of frames actually read.
reportedFrames = reader.NumFrames;
if ~isscalar(reportedFrames) || ~isfinite(reportedFrames) || reportedFrames < totalFrames
    reportedFrames = totalFrames;
end

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
    'rgb', rgb, ...
    'Y', Y, ...
    'Y8', Y8, ...
    'Cb420', Cb420, ...
    'Cr420', Cr420, ...
    'mbGrid', mbGrid, ...
    'videoInfo', videoInfo);
end

function out = subsample420(plane)
% Mean of each 2x2 block, giving the 4:2:0 chroma resolution.
plane = double(plane);
out = 0.25 * ( plane(1:2:end, 1:2:end) + plane(1:2:end, 2:2:end) ...
             + plane(2:2:end, 1:2:end) + plane(2:2:end, 2:2:end) );
end

function p = whichPath(videoPath)
% Absolute path when possible, otherwise the input unchanged.
try
    p = char(java.io.File(videoPath).getCanonicalPath());
catch
    p = videoPath;
end
end
