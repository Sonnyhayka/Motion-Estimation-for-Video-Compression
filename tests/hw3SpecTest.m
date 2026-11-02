classdef hw3SpecTest < matlab.unittest.TestCase
methods (TestClassSetup)
    function addSourceToPath(~)
        here = fileparts(mfilename('fullpath'));
        addpath(fullfile(fileparts(here), 'src'));
    end
end

methods (Test)
    function macroblockIs16x16(testCase)
        p = hw3Params();
        testCase.verifyEqual(p.mbSize, 16);
    end

    function searchWindowIs30(testCase)
        p = hw3Params();
        testCase.verifyEqual(p.searchWindow, 30);
    end

    function searchRadiusFollowsFromCentering(testCase)
        p = hw3Params();
        testCase.verifyEqual(p.searchRadius, (p.searchWindow - p.mbSize) / 2);
        testCase.verifyEqual(p.searchRadius, 7);
    end

    function candidateCountMatchesFormula(testCase)
        p = hw3Params();
        testCase.verifyEqual(p.candidates, (2 * p.searchRadius + 1) ^ 2);
        testCase.verifyEqual(p.candidates, 225);
    end

    function framesAre16To20(testCase)
        p = hw3Params();
        testCase.verifyEqual(p.frameNumbers, 16:20);
        testCase.verifyEqual(numel(p.frameNumbers), 5);
    end

    function structureIsIpppppWithGop6(testCase)
        p = hw3Params();
        testCase.verifyEqual(p.gopSize, 6);
        testCase.verifyEqual(numel(p.frameNumbers), 5);
        testCase.verifyEqual(p.frameNumbers(p.iFrameIndex), 16);
    end

    function gopAnchorIsTheIFrame(testCase)
        p = hw3Params();
        testCase.verifyEqual(p.gopAnchor, 16);
    end

    function frameSixteenIsTheOnlyIFrame(testCase)
        p = hw3Params();
        testCase.verifyEqual(p.frameTypes, {'I', 'P', 'P', 'P', 'P'});
        testCase.verifyEqual(p.iFrame, 16);
    end

    function pFramesAreSeventeenToTwenty(testCase)
        p = hw3Params();
        testCase.verifyEqual(p.pFrames, 17:20);
    end

    function sadCostIs511Adds(testCase)
        p = hw3Params();
        testCase.verifyEqual(p.addsPerCandidate, 2 * p.mbSize ^ 2 - 1);
        testCase.verifyEqual(p.addsPerCandidate, 511);
    end

    function chromaFormatIs420(testCase)
        p = hw3Params();
        testCase.verifyEqual(p.chromaFormat, '4:2:0');
    end
end

end
