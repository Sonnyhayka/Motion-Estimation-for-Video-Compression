function tests = testProjectFiles
%TESTPROJECTFILES Basic CI smoke tests for the motion estimation repository.
% Add algorithm-specific unit tests here as MATLAB source is implemented.
tests = functiontests(localfunctions);
end

function videoFile = locateVideo()
projectRoot = fileparts(fileparts(mfilename('fullpath')));
candidates = { ...
    fullfile(projectRoot, 'data', 'walk_qcif.avi'), ...
    fullfile(projectRoot, 'walk_qcif.avi')};

videoFile = candidates{1};
for k = 1:numel(candidates)
    if isfile(candidates{k})
        videoFile = candidates{k};
        break
    end
end
end

function testInputVideoExists(testCase)
videoFile = locateVideo();
testCase.verifyTrue(isfile(videoFile), ...
    sprintf('Required input video walk_qcif.avi is missing. Looked for %s.', ...
    videoFile));
end

function testInputVideoNotEmpty(testCase)
fileInfo = dir(locateVideo());
testCase.verifyNotEmpty(fileInfo);
if ~isempty(fileInfo)
    testCase.verifyGreaterThan(fileInfo.bytes, 0);
end
end
