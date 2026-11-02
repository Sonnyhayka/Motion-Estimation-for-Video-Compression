classdef loadWalkSequenceTest < matlab.unittest.TestCase
properties
    ProjectRoot
    VideoPath
end

methods (TestClassSetup)
    function locateProject(testCase)
        here = fileparts(mfilename('fullpath'));
        testCase.ProjectRoot = fileparts(here);
        testCase.VideoPath = fullfile(testCase.ProjectRoot, 'data', 'walk_qcif.avi');
        addpath(fullfile(testCase.ProjectRoot, 'src'));
    end
end

methods (Test)
    function videoFileIsPresent(testCase)
        testCase.verifyTrue(isfile(testCase.VideoPath), ...
            'data/walk_qcif.avi is missing from the repository.');
    end

    function loadsFiveFrames(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:20);
        testCase.verifyEqual(S.frameCount, 5);
        testCase.verifyEqual(S.frameNumbers, 16:20);
    end

    function frameGeometryIsQcif(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:20);
        testCase.verifySize(S.Y, [144 176 5]);
        testCase.verifySize(S.rgb, [144 176 3 5]);
        testCase.verifySize(S.Cb420, [72 88 5]);
        testCase.verifySize(S.Cr420, [72 88 5]);
    end

    function macroblockGridIs99(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:20);
        testCase.verifyEqual(S.mbGrid.size, 16);
        testCase.verifyEqual(S.mbGrid.cols, 11);
        testCase.verifyEqual(S.mbGrid.rows, 9);
        testCase.verifyEqual(S.mbGrid.count, 99);
    end

    function lumaIsInVideoRange(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:20);
        testCase.verifyGreaterThanOrEqual(min(S.Y, [], 'all'), 16);
        testCase.verifyLessThanOrEqual(max(S.Y, [], 'all'), 235);
    end

    function lumaIsNotTheRedChannel(testCase)
        S = loadWalkSequence(testCase.VideoPath, 17:17);
        red = double(S.rgb(:, :, 1, 1));
        testCase.verifyNotEqual(S.Y(:, :, 1), red, ...
            'Luma should come from rgb2ycbcr, not the red channel.');
    end

    function y8IsRoundedLuma(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:20);
        testCase.verifyEqual(S.Y8, uint8(round(S.Y)));
    end

    function chromaIsTwoByTwoMean(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:16);
        ycbcr = rgb2ycbcr(S.rgb(:, :, :, 1));
        cb = double(ycbcr(:, :, 2));
        expected = 0.25 * (cb(1:2:end, 1:2:end) + cb(1:2:end, 2:2:end) ...
            + cb(2:2:end, 1:2:end) + cb(2:2:end, 2:2:end));
        testCase.verifyEqual(S.Cb420(:, :, 1), expected);
    end

    function defaultCallUsesSpecFrames(testCase)
        S = loadWalkSequence();
        p = hw3Params();
        testCase.verifyEqual(S.frameNumbers, p.frameNumbers);
    end

    function rejectsMissingFile(testCase)
        testCase.verifyError(@() loadWalkSequence('no\such\file.avi', 16:20), ...
            'loadWalkSequence:missingVideo');
    end

    function rejectsFramesPastEnd(testCase)
        testCase.verifyError(@() loadWalkSequence(testCase.VideoPath, 16:999), ...
            'loadWalkSequence:shortSequence');
    end

    function rejectsNonIntegerIndices(testCase)
        testCase.verifyError(@() loadWalkSequence(testCase.VideoPath, [16 17.5]), ...
            'loadWalkSequence:badIndices');
    end

    function rejectsUnsortedIndices(testCase)
        testCase.verifyError(@() loadWalkSequence(testCase.VideoPath, [18 17]), ...
            'loadWalkSequence:badIndices');
    end

    function rejectsZeroIndices(testCase)
        testCase.verifyError(@() loadWalkSequence(testCase.VideoPath, 0:3), ...
            'loadWalkSequence:badIndices');
    end
end

end
