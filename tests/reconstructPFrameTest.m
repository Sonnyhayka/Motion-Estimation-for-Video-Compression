classdef reconstructPFrameTest < matlab.unittest.TestCase
methods (TestClassSetup)
    function addSourceToPath(~)
        here = fileparts(mfilename('fullpath'));
        addpath(fullfile(fileparts(here), 'src'));
    end
end
methods (Test)
    function reconstructsFromVectorsAndSignedResidual(testCase)
        reference = uint8(reshape(0:63, 8, 8));
        vectors = zeros(2, 2, 2);
        vectors(1, 1, :) = reshape([1 2], 1, 1, 2);
        residual = -10 * ones(8);
        [actual, prediction] = reconstructPFrame(reference, vectors, residual, 4);
        testCase.verifyEqual(prediction(1:4, 1:4), reference(3:6, 2:5));
        testCase.verifyEqual(actual, double(prediction) - 10);
        testCase.verifyLessThan(min(actual(:)), 0);
    end

    function rejectsInvalidVectors(testCase)
        testCase.verifyError(@() reconstructPFrame(zeros(8), zeros(1, 1, 2), zeros(8), 4), ...
            'reconstructPFrame:sizeMismatch');
        vectors = zeros(2, 2, 2);
        vectors(1) = 0.5;
        testCase.verifyError(@() reconstructPFrame(zeros(8), vectors, zeros(8), 4), ...
            'reconstructPFrame:badVectors');
        vectors(1) = -1;
        testCase.verifyError(@() reconstructPFrame(zeros(8), vectors, zeros(8), 4), ...
            'reconstructPFrame:vectorOutOfBounds');
    end

    function reconstructsAllPFrames(testCase)
        here = fileparts(mfilename('fullpath'));
        S = loadWalkSequence(fullfile(fileparts(here), 'data', 'walk_qcif.avi'), 16:20);
        reference = S.Y(:, :, S.referenceIndex);
        for frame = find(strcmp(S.frameTypes, 'P'))
            target = S.Y(:, :, frame);
            [vectors, expectedPrediction, ~, residual] = fullSearchFrame(target, reference);
            [actual, prediction] = reconstructPFrame(reference, vectors, residual);
            testCase.verifyEqual(prediction, expectedPrediction);
            testCase.verifyEqual(actual, double(target));
        end
    end
end
end
