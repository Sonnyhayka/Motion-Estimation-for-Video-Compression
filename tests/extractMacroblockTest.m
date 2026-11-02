classdef extractMacroblockTest < matlab.unittest.TestCase
properties
    ProjectRoot
    VideoPath
    Plane
end

methods (TestClassSetup)
    function locateProject(testCase)
        here = fileparts(mfilename('fullpath'));
        testCase.ProjectRoot = fileparts(here);
        testCase.VideoPath = fullfile(testCase.ProjectRoot, 'data', 'walk_qcif.avi');
        addpath(fullfile(testCase.ProjectRoot, 'src'));
        testCase.Plane = makeRamp(144, 176);
    end
end

methods (Test)
    function topLeftBlockIsFirstSixteenPixels(testCase)
        block = extractMacroblock(testCase.Plane, 1, 1);
        testCase.verifyEqual(block, testCase.Plane(1:16, 1:16));
    end

    function bottomRightBlockIsLastSixteenPixels(testCase)
        block = extractMacroblock(testCase.Plane, 9, 11);
        testCase.verifyEqual(block, testCase.Plane(129:144, 161:176));
    end

    function interiorBlockUsesRowThenColumn(testCase)
        block = extractMacroblock(testCase.Plane, 2, 3);
        testCase.verifyEqual(block, testCase.Plane(17:32, 33:48));
    end

    function swappedIndicesGiveDifferentBlock(testCase)
        a = extractMacroblock(testCase.Plane, 2, 3);
        b = extractMacroblock(testCase.Plane, 3, 2);
        testCase.verifyNotEqual(a, b);
    end

    function originIsTopLeftPixel(testCase)
        [~, origin] = extractMacroblock(testCase.Plane, 1, 1);
        testCase.verifyEqual(origin, [1 1]);
        [~, origin] = extractMacroblock(testCase.Plane, 9, 11);
        testCase.verifyEqual(origin, [129 161]);
        [~, origin] = extractMacroblock(testCase.Plane, 4, 7);
        testCase.verifyEqual(origin, [49 97]);
    end

    function blockSizeIsSixteenByDefault(testCase)
        block = extractMacroblock(testCase.Plane, 3, 4);
        testCase.verifySize(block, [16 16]);
    end

    function explicitSizeMatchesDefault(testCase)
        expected = extractMacroblock(testCase.Plane, 3, 4);
        actual = extractMacroblock(testCase.Plane, 3, 4, 16);
        testCase.verifyEqual(actual, expected);
    end

    function smallerSizeSelectsSmallerBlock(testCase)
        block = extractMacroblock(testCase.Plane, 2, 2, 8);
        testCase.verifySize(block, [8 8]);
        testCase.verifyEqual(block, testCase.Plane(9:16, 9:16));
    end

    function uint8InputStaysUint8(testCase)
        plane = uint8(testCase.Plane);
        block = extractMacroblock(plane, 2, 2);
        testCase.verifyClass(block, 'uint8');
        testCase.verifyEqual(block, plane(17:32, 17:32));
    end

    function doubleInputStaysDouble(testCase)
        block = extractMacroblock(testCase.Plane, 2, 2);
        testCase.verifyClass(block, 'double');
    end

    function blocksTileTheFrameExactlyOnce(testCase)
        coverage = zeros(size(testCase.Plane));
        mbSize = hw3Params().mbSize;
        mbRows = size(testCase.Plane, 1) / mbSize;
        mbCols = size(testCase.Plane, 2) / mbSize;
        for row = 1:mbRows
            for col = 1:mbCols
                [block, origin] = extractMacroblock(testCase.Plane, row, col);
                coverage(origin(1):origin(1) + mbSize - 1, ...
                    origin(2):origin(2) + mbSize - 1) = ...
                    coverage(origin(1):origin(1) + mbSize - 1, ...
                    origin(2):origin(2) + mbSize - 1) + 1;
                testCase.verifyEqual(block, testCase.Plane( ...
                    origin(1):origin(1) + mbSize - 1, ...
                    origin(2):origin(2) + mbSize - 1));
            end
        end
        testCase.verifyEqual(coverage, ones(size(testCase.Plane)));
        testCase.verifyEqual(mbRows * mbCols, 99);
    end

    function extractsFromEveryPFrameOfTheSequence(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:20);
        targets = find(strcmp(S.frameTypes, 'P'));
        testCase.verifyEqual(numel(targets), 4);
        for k = targets
            block = extractMacroblock(S.Y(:, :, k), 5, 6);
            testCase.verifySize(block, [S.mbGrid.size S.mbGrid.size]);
            testCase.verifyEqual(block, S.Y(65:80, 81:96, k));
        end
    end

    function chromaUsesHalfSizeBlocksOnTheLumaGrid(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:20);
        half = S.mbGrid.size / 2;
        [~, lumaOrigin] = extractMacroblock(S.Y(:, :, 2), 5, 6);
        for chroma = {S.Cb420(:, :, 2), S.Cr420(:, :, 2)}
            plane = chroma{1};
            [block, origin] = extractMacroblock(plane, 5, 6, half);
            testCase.verifySize(block, [half half]);
            testCase.verifyEqual(block, plane(33:40, 41:48));
            testCase.verifyEqual(origin, (lumaOrigin - 1) / 2 + 1);
            lastBlock = extractMacroblock(plane, S.mbGrid.rows, S.mbGrid.cols, half);
            testCase.verifyEqual(lastBlock, plane(65:72, 81:88));
        end
    end

    function chromaPlaneAtFullMacroblockSizeIsRejected(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:20);
        testCase.verifyError(@() extractMacroblock(S.Cb420(:, :, 2), 1, 1), ...
            'extractMacroblock:ragged');
    end

    function rejectsPlaneThatIsNotWholeBlocks(testCase)
        testCase.verifyError(@() extractMacroblock(makeRamp(20, 40), 1, 1), ...
            'extractMacroblock:ragged');
        testCase.verifyError(@() extractMacroblock(makeRamp(32, 40), 1, 1), ...
            'extractMacroblock:ragged');
    end

    function integerIndicesDoNotSaturate(testCase)
        [block, origin] = extractMacroblock(testCase.Plane, int8(9), int8(11));
        testCase.verifyEqual(block, testCase.Plane(129:144, 161:176));
        testCase.verifyEqual(origin, [129 161]);
        testCase.verifyClass(origin, 'double');
    end

    function integerBlockSizeDoesNotSaturate(testCase)
        [block, origin] = extractMacroblock(testCase.Plane, 9, 11, int8(16));
        testCase.verifyEqual(block, testCase.Plane(129:144, 161:176));
        testCase.verifyEqual(origin, [129 161]);
        testCase.verifyClass(origin, 'double');
    end

    function rejectsNonNumericPlane(testCase)
        testCase.verifyError(@() extractMacroblock('not a plane', 1, 1), ...
            'extractMacroblock:badPlane');
    end

    function rejectsEmptyPlane(testCase)
        testCase.verifyError(@() extractMacroblock([], 1, 1), ...
            'extractMacroblock:badPlane');
    end

    function rejectsThreeDimensionalPlane(testCase)
        testCase.verifyError(@() extractMacroblock(ones(16, 16, 3), 1, 1), ...
            'extractMacroblock:badPlane');
    end

    function rejectsRowPastTheGrid(testCase)
        testCase.verifyError(@() extractMacroblock(testCase.Plane, 10, 1), ...
            'extractMacroblock:outOfRange');
    end

    function rejectsColumnPastTheGrid(testCase)
        testCase.verifyError(@() extractMacroblock(testCase.Plane, 1, 12), ...
            'extractMacroblock:outOfRange');
    end

    function rejectsZeroIndex(testCase)
        testCase.verifyError(@() extractMacroblock(testCase.Plane, 0, 1), ...
            'extractMacroblock:badIndex');
    end

    function rejectsFractionalIndex(testCase)
        testCase.verifyError(@() extractMacroblock(testCase.Plane, 1.5, 1), ...
            'extractMacroblock:badIndex');
    end

    function rejectsVectorIndex(testCase)
        testCase.verifyError(@() extractMacroblock(testCase.Plane, [1 2], 1), ...
            'extractMacroblock:badIndex');
    end

    function rejectsBadMacroblockSize(testCase)
        testCase.verifyError(@() extractMacroblock(testCase.Plane, 1, 1, 0), ...
            'extractMacroblock:badSize');
    end
end

end

function plane = makeRamp(height, width)
plane = reshape(1:height * width, width, height).';
end
