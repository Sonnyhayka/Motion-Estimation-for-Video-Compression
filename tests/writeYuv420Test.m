classdef writeYuv420Test < matlab.unittest.TestCase
properties
    ProjectRoot
    VideoPath
    TempDir
end

methods (TestClassSetup)
    function locateProject(testCase)
        here = fileparts(mfilename('fullpath'));
        testCase.ProjectRoot = fileparts(here);
        testCase.VideoPath = fullfile(testCase.ProjectRoot, 'data', 'walk_qcif.avi');
        addpath(fullfile(testCase.ProjectRoot, 'src'));
    end
end

methods (TestMethodSetup)
    function makeTempDir(testCase)
        testCase.TempDir = tempname();
        mkdir(testCase.TempDir);
    end
end

methods (TestMethodTeardown)
    function removeTempDir(testCase)
        if isfolder(testCase.TempDir)
            rmdir(testCase.TempDir, 's');
        end
    end
end

methods (Test)
    function writesOneFrameOf38016Bytes(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:16);
        yuvPath = fullfile(testCase.TempDir, 'one.yuv');
        bytes = writeYuv420(S, yuvPath, 'Verbose', false);
        testCase.verifyEqual(bytes, 38016);
        info = dir(yuvPath);
        testCase.verifyEqual(info.bytes, 38016);
    end

    function writesFiveFramesOf190080Bytes(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:20);
        yuvPath = fullfile(testCase.TempDir, 'five.yuv');
        bytes = writeYuv420(S, yuvPath, 'Verbose', false);
        testCase.verifyEqual(bytes, 190080);
        testCase.verifyEqual(bytes, 176 * 144 * 1.5 * 5);
    end

    function byteCountScalesWithFrames(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:20);
        bytes = writeYuv420(S, fullfile(testCase.TempDir, 'a.yuv'), 'Verbose', false);
        testCase.verifyEqual(bytes, 38016 * S.frameCount);
    end

    function readBackMatchesPlanes(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:18);
        yuvPath = fullfile(testCase.TempDir, 'planes.yuv');
        writeYuv420(S, yuvPath, 'Verbose', false);

        fid = fopen(yuvPath, 'r');
        cleaner = onCleanup(@() fclose(fid));
        data = fread(fid, Inf, 'uint8=>uint8');

        yBytes = numel(S.Y8(:, :, 1));
        cbBytes = numel(S.Cb420(:, :, 1));
        crBytes = numel(S.Cr420(:, :, 1));
        stride = yBytes + cbBytes + crBytes;

        for j = 1:S.frameCount
            base = (j - 1) * stride;
            Y = reshape(data(base + (1:yBytes)), fliplr(size(S.Y8(:, :, j)))).';
            Cb = reshape(data(base + yBytes + (1:cbBytes)), fliplr(size(S.Cb420(:, :, j)))).';
            Cr = reshape(data(base + yBytes + cbBytes + (1:crBytes)), fliplr(size(S.Cr420(:, :, j)))).';
            testCase.verifyEqual(Y, S.Y8(:, :, j));
            testCase.verifyEqual(Cb, uint8(round(S.Cb420(:, :, j))));
            testCase.verifyEqual(Cr, uint8(round(S.Cr420(:, :, j))));
        end
    end

    function chromaIsQuarterOfLuma(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:16);
        testCase.verifyEqual(size(S.Cb420, 1) * size(S.Cb420, 2) * 4, ...
            size(S.Y, 1) * size(S.Y, 2));
    end

    function createsMissingOutputFolder(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:16);
        yuvPath = fullfile(testCase.TempDir, 'nested', 'deep', 'out.yuv');
        writeYuv420(S, yuvPath, 'Verbose', false);
        testCase.verifyTrue(isfile(yuvPath));
    end

    function rejectsUnwritablePath(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:16);
        blocker = fullfile(testCase.TempDir, 'blocker');
        fid = fopen(blocker, 'w');
        fclose(fid);
        testCase.verifyError( ...
            @() writeYuv420(S, fullfile(blocker, 'out.yuv'), 'Verbose', false), ...
            'writeYuv420:badPath');
    end

    function rejectsInvalidGeometryBeforeOpeningFile(testCase)
        S = struct('Y8', zeros(4, 4, 2, 'uint8'), ...
            'Cb420', zeros(2, 2, 2), 'Cr420', zeros(2, 2, 2));
        invalid = {S, S, S, S};
        invalid{1}.Cb420 = zeros(4, 4, 2);
        invalid{2}.Cr420 = zeros(2, 2);
        invalid{3}.Y8 = zeros(3, 4, 2, 'uint8');
        invalid{4}.Y8 = zeros(4, 4, 2, 2, 'uint8');
        yuvPath = fullfile(testCase.TempDir, 'invalid.yuv');
        for k = 1:numel(invalid)
            testCase.verifyError(@() writeYuv420(invalid{k}, yuvPath, 'Verbose', false), ...
                'writeYuv420:badGeometry');
            testCase.verifyFalse(isfile(yuvPath));
        end
    end
end

end
