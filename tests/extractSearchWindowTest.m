classdef extractSearchWindowTest < matlab.unittest.TestCase
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
    function interiorWindowIsThirtyByThirty(testCase)
        [window, origin] = extractSearchWindow(testCase.Plane, 5, 6);
        testCase.verifySize(window, [30 30]);
        testCase.verifyEqual(origin, [58 74]);
        testCase.verifyEqual(window, testCase.Plane(58:87, 74:103));
    end

    function topLeftCornerIsTwentyThreeSquare(testCase)
        [window, origin] = extractSearchWindow(testCase.Plane, 1, 1);
        testCase.verifySize(window, [23 23]);
        testCase.verifyEqual(origin, [1 1]);
        testCase.verifyEqual(window, testCase.Plane(1:23, 1:23));
    end

    function topRightCornerIsTwentyThreeSquare(testCase)
        [window, origin] = extractSearchWindow(testCase.Plane, 1, 11);
        testCase.verifySize(window, [23 23]);
        testCase.verifyEqual(origin, [1 154]);
        testCase.verifyEqual(window, testCase.Plane(1:23, 154:176));
    end

    function bottomLeftCornerIsTwentyThreeSquare(testCase)
        [window, origin] = extractSearchWindow(testCase.Plane, 9, 1);
        testCase.verifySize(window, [23 23]);
        testCase.verifyEqual(origin, [122 1]);
        testCase.verifyEqual(window, testCase.Plane(122:144, 1:23));
    end

    function bottomRightCornerIsTwentyThreeSquare(testCase)
        [window, origin] = extractSearchWindow(testCase.Plane, 9, 11);
        testCase.verifySize(window, [23 23]);
        testCase.verifyEqual(origin, [122 154]);
        testCase.verifyEqual(window, testCase.Plane(122:144, 154:176));
    end

    function topRowIsShortAndWide(testCase)
        [window, origin] = extractSearchWindow(testCase.Plane, 1, 5);
        testCase.verifySize(window, [23 30]);
        testCase.verifyEqual(origin, [1 58]);
        testCase.verifyEqual(window, testCase.Plane(1:23, 58:87));
    end

    function bottomRowIsShortAndWide(testCase)
        [window, origin] = extractSearchWindow(testCase.Plane, 9, 5);
        testCase.verifySize(window, [23 30]);
        testCase.verifyEqual(origin, [122 58]);
        testCase.verifyEqual(window, testCase.Plane(122:144, 58:87));
    end

    function leftColumnIsTallAndNarrow(testCase)
        [window, origin] = extractSearchWindow(testCase.Plane, 5, 1);
        testCase.verifySize(window, [30 23]);
        testCase.verifyEqual(origin, [58 1]);
        testCase.verifyEqual(window, testCase.Plane(58:87, 1:23));
    end

    function rightColumnIsTallAndNarrow(testCase)
        [window, origin] = extractSearchWindow(testCase.Plane, 5, 11);
        testCase.verifySize(window, [30 23]);
        testCase.verifyEqual(origin, [58 154]);
        testCase.verifyEqual(window, testCase.Plane(58:87, 154:176));
    end

    function windowSizesAcrossTheGridFollowTheEdges(testCase)
        mbRows = 9;
        mbCols = 11;
        sizes = zeros(mbRows * mbCols, 2);
        k = 0;
        for row = 1:mbRows
            for col = 1:mbCols
                k = k + 1;
                window = extractSearchWindow(testCase.Plane, row, col);
                sizes(k, :) = size(window);
            end
        end
        testCase.verifyEqual(sum(all(sizes == [30 30], 2)), 63);
        testCase.verifyEqual(sum(all(sizes == [23 23], 2)), 4);
        testCase.verifyEqual(sum(all(sizes == [23 30], 2)), 18);
        testCase.verifyEqual(sum(all(sizes == [30 23], 2)), 14);
    end

    function everyWindowHoldsItsMacroblockAtTheRightOffset(testCase)
        mbSize = hw3Params().mbSize;
        for row = 1:9
            for col = 1:11
                [block, mbOrigin] = extractMacroblock(testCase.Plane, row, col);
                [window, origin] = extractSearchWindow(testCase.Plane, row, col);
                offset = mbOrigin - origin;
                inside = window(offset(1) + 1:offset(1) + mbSize, ...
                    offset(2) + 1:offset(2) + mbSize);
                testCase.verifyEqual(inside, block);
                testCase.verifyEqual(window, testCase.Plane( ...
                    origin(1):origin(1) + size(window, 1) - 1, ...
                    origin(2):origin(2) + size(window, 2) - 1));
            end
        end
    end

    function interiorMacroblockIsCenteredInTheWindow(testCase)
        [~, mbOrigin] = extractMacroblock(testCase.Plane, 5, 6);
        [~, origin] = extractSearchWindow(testCase.Plane, 5, 6);
        testCase.verifyEqual(mbOrigin - origin, [7 7]);
    end

    function cornerMacroblockSitsAtTheWindowEdge(testCase)
        [~, mbOrigin] = extractMacroblock(testCase.Plane, 1, 1);
        [~, origin] = extractSearchWindow(testCase.Plane, 1, 1);
        testCase.verifyEqual(mbOrigin - origin, [0 0]);
    end

    function interiorWindowHoldsEveryCandidateVector(testCase)
        p = hw3Params();
        window = extractSearchWindow(testCase.Plane, 5, 6);
        positions = size(window) - p.mbSize + 1;
        testCase.verifyEqual(positions, [15 15]);
        testCase.verifyEqual(prod(positions), p.candidates);
    end

    function cornerWindowHoldsOnlyCandidatesInsideTheFrame(testCase)
        p = hw3Params();
        window = extractSearchWindow(testCase.Plane, 1, 1);
        positions = size(window) - p.mbSize + 1;
        testCase.verifyEqual(positions, [8 8]);
    end

    function explicitSizesMatchDefaults(testCase)
        expected = extractSearchWindow(testCase.Plane, 5, 6);
        actual = extractSearchWindow(testCase.Plane, 5, 6, 16, 7);
        testCase.verifyEqual(actual, expected);
    end

    function smallerRadiusShrinksWindow(testCase)
        [window, origin] = extractSearchWindow(testCase.Plane, 5, 6, 16, 4);
        testCase.verifySize(window, [24 24]);
        testCase.verifyEqual(origin, [61 77]);
        testCase.verifyEqual(window, testCase.Plane(61:84, 77:100));
    end

    function zeroRadiusIsTheMacroblock(testCase)
        [block, mbOrigin] = extractMacroblock(testCase.Plane, 5, 6);
        [window, origin] = extractSearchWindow(testCase.Plane, 5, 6, 16, 0);
        testCase.verifyEqual(window, block);
        testCase.verifyEqual(origin, mbOrigin);
    end

    function uint8InputStaysUint8(testCase)
        plane = uint8(testCase.Plane);
        window = extractSearchWindow(plane, 5, 6);
        testCase.verifyClass(window, 'uint8');
        testCase.verifyEqual(window, plane(58:87, 74:103));
    end

    function doubleInputStaysDouble(testCase)
        window = extractSearchWindow(testCase.Plane, 5, 6);
        testCase.verifyClass(window, 'double');
    end

    function integerArgumentsDoNotSaturate(testCase)
        plane = uint8(testCase.Plane);
        [window, origin] = extractSearchWindow( ...
            plane, int8(9), int8(11), int8(16), int8(7));
        testCase.verifyEqual(window, plane(122:144, 154:176));
        testCase.verifyEqual(origin, [122 154]);
        testCase.verifyClass(origin, 'double');
    end

    function extractsFromTheIFrameOfTheSequence(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:20);
        reference = S.Y(:, :, S.referenceIndex);
        window = extractSearchWindow(reference, 5, 6);
        testCase.verifySize(window, [30 30]);
        testCase.verifyEqual(window, S.Y(58:87, 74:103, S.referenceIndex));
    end

    function chromaUsesHalfSizeBlocksAndRadius(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:20);
        plane = S.Cb420(:, :, S.referenceIndex);
        [window, origin] = extractSearchWindow(plane, 5, 6, 8, 3);
        testCase.verifySize(window, [14 14]);
        testCase.verifyEqual(origin, [30 38]);
        testCase.verifyEqual(window, plane(30:43, 38:51));
        lastWindow = extractSearchWindow(plane, S.mbGrid.rows, S.mbGrid.cols, 8, 3);
        testCase.verifySize(lastWindow, [11 11]);
        testCase.verifyEqual(lastWindow, plane(62:72, 78:88));
    end

    function rejectsNegativeRadius(testCase)
        testCase.verifyError(@() extractSearchWindow(testCase.Plane, 5, 6, 16, -1), ...
            'extractSearchWindow:badRadius');
    end

    function rejectsFractionalRadius(testCase)
        testCase.verifyError(@() extractSearchWindow(testCase.Plane, 5, 6, 16, 2.5), ...
            'extractSearchWindow:badRadius');
    end

    function rejectsVectorRadius(testCase)
        testCase.verifyError(@() extractSearchWindow(testCase.Plane, 5, 6, 16, [1 2]), ...
            'extractSearchWindow:badRadius');
    end

    function rejectsNonNumericRadius(testCase)
        testCase.verifyError(@() extractSearchWindow(testCase.Plane, 5, 6, 16, 'a'), ...
            'extractSearchWindow:badRadius');
    end

    function rejectsRowPastTheGrid(testCase)
        testCase.verifyError(@() extractSearchWindow(testCase.Plane, 10, 1), ...
            'extractMacroblock:outOfRange');
    end

    function rejectsPlaneThatIsNotWholeBlocks(testCase)
        testCase.verifyError(@() extractSearchWindow(makeRamp(20, 40), 1, 1), ...
            'extractMacroblock:ragged');
    end

    function rejectsNonNumericPlane(testCase)
        testCase.verifyError(@() extractSearchWindow('not a plane', 1, 1), ...
            'extractMacroblock:badPlane');
    end
end

end

function plane = makeRamp(height, width)
plane = reshape(1:height * width, width, height).';
end
