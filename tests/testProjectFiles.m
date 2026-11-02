function tests = testProjectFiles
%TESTPROJECTFILES Basic CI smoke tests for the motion estimation repository.
% Add algorithm-specific unit tests here as MATLAB source is implemented.
tests = functiontests(localfunctions);
end

function testInputVideoExists(testCase)
projectRoot = fileparts(fileparts(mfilename('fullpath')));
videoFile = fullfile(projectRoot, 'walk_qcif.avi');
testCase.verifyTrue(isfile(videoFile), ...
    'Required input video walk_qcif.avi is missing.');
end

function testInputVideoNotEmpty(testCase)
projectRoot = fileparts(fileparts(mfilename('fullpath')));
videoFile = fullfile(projectRoot, 'walk_qcif.avi');
fileInfo = dir(videoFile);
testCase.verifyNotEmpty(fileInfo);
if ~isempty(fileInfo)
    testCase.verifyGreaterThan(fileInfo.bytes, 0);
end
end
