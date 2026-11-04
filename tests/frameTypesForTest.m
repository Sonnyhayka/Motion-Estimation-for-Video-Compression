classdef frameTypesForTest < matlab.unittest.TestCase
methods (TestClassSetup)
    function addSourceToPath(~)
        here = fileparts(mfilename('fullpath'));
        addpath(fullfile(fileparts(here), 'src'));
    end
end

methods (Test)
    function specSliceIsIpppp(testCase)
        types = frameTypesFor(16:20, 16, 6);
        testCase.verifyEqual(types, {'I', 'P', 'P', 'P', 'P'});
    end

    function fullGopIsIppppp(testCase)
        types = frameTypesFor(16:21, 16, 6);
        testCase.verifyEqual(types, {'I', 'P', 'P', 'P', 'P', 'P'});
    end

    function secondGopStartsAtTwentyTwo(testCase)
        types = frameTypesFor(18:24, 16, 6);
        testCase.verifyEqual(types, {'P', 'P', 'P', 'P', 'I', 'P', 'P'});
    end

    function typesFollowClipNumbering(testCase)
        types = frameTypesFor(22, 16, 6);
        testCase.verifyEqual(types, {'I'});
    end

    function onlyIAndPAreProduced(testCase)
        types = frameTypesFor(16:37, 16, 6);
        testCase.verifyTrue(all(ismember(types, {'I', 'P'})));
        testCase.verifyEqual(sum(strcmp(types, 'I')), 4);
    end

    function rejectsNonIntegerFrames(testCase)
        testCase.verifyError(@() frameTypesFor([16 17.5], 16, 6), ...
            'frameTypesFor:badFrames');
    end

    function rejectsBadAnchor(testCase)
        testCase.verifyError(@() frameTypesFor(16:20, 16.5, 6), ...
            'frameTypesFor:badAnchor');
    end

    function rejectsBadGopSize(testCase)
        testCase.verifyError(@() frameTypesFor(16:20, 16, 0), ...
            'frameTypesFor:badGopSize');
    end

    function integerInputsPreserveFramesBeforeAnchor(testCase)
        types = frameTypesFor(uint8(10:16), uint8(16), uint8(6));
        testCase.verifyEqual(types, {'I', 'P', 'P', 'P', 'P', 'P', 'I'});
    end

    function columnFramesPreserveShape(testCase)
        types = frameTypesFor((16:18).', 16, 6);
        testCase.verifyEqual(types, {'I'; 'P'; 'P'});
    end

    function rejectsInvalidFrameArguments(testCase)
        testCase.verifyError(@() frameTypesFor([16 17; 18 19], 16, 6), ...
            'frameTypesFor:badFrames');
        testCase.verifyError(@() frameTypesFor([16 17 + 1i], 16, 6), ...
            'frameTypesFor:badFrames');
        testCase.verifyError(@() frameTypesFor(16:20, char(16), 6), ...
            'frameTypesFor:badAnchor');
        testCase.verifyError(@() frameTypesFor(16:20, 16, char(6)), ...
            'frameTypesFor:badGopSize');
    end
end

end
