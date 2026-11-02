classdef fullSearchMacroblockTest < matlab.unittest.TestCase
properties
    ProjectRoot
    VideoPath
    Reference
    Target
end

methods (TestClassSetup)
    function locateProject(testCase)
        here = fileparts(mfilename('fullpath'));
        testCase.ProjectRoot = fileparts(here);
        testCase.VideoPath = fullfile(testCase.ProjectRoot, 'data', 'walk_qcif.avi');
        addpath(fullfile(testCase.ProjectRoot, 'src'));
        stream = RandStream('mt19937ar', 'Seed', 7);
        testCase.Reference = randi(stream, 256, 144, 176) - 1;
        testCase.Target = randi(stream, 256, 144, 176) - 1;
    end
end

methods (Test)
    function recoversKnownDisplacements(testCase)
        shifts = [3 -2; -7 7; 7 -7; 0 5; -4 0; 7 7; -7 -7];
        for k = 1:size(shifts, 1)
            target = plantBlock(testCase.Reference, 5, 6, shifts(k, 1), shifts(k, 2));
            [mv, minSad] = fullSearchMacroblock(target, testCase.Reference, 5, 6);
            testCase.verifyEqual(mv, shifts(k, :));
            testCase.verifyEqual(minSad, 0);
        end
    end

    function vectorIsColumnOffsetThenRowOffset(testCase)
        target = plantBlock(testCase.Reference, 5, 6, 5, -3);
        mv = fullSearchMacroblock(target, testCase.Reference, 5, 6);
        testCase.verifyEqual(mv, [5 -3]);
        testCase.verifyNotEqual(mv, [-3 5]);
    end

    function matchedBlockSitsAtOriginPlusVector(testCase)
        target = plantBlock(testCase.Reference, 5, 6, 3, -2);
        mv = fullSearchMacroblock(target, testCase.Reference, 5, 6);
        [block, origin] = extractMacroblock(target, 5, 6);
        top = origin(1) + mv(2);
        left = origin(2) + mv(1);
        matched = testCase.Reference(top:top + 15, left:left + 15);
        testCase.verifyEqual(matched, block);
    end

    function identicalPlanesGiveZeroMotion(testCase)
        for position = [5 6; 1 1; 9 11]'
            [mv, minSad] = fullSearchMacroblock( ...
                testCase.Reference, testCase.Reference, position(1), position(2));
            testCase.verifyEqual(mv, [0 0]);
            testCase.verifyEqual(minSad, 0);
        end
    end

    function interiorSearchScoresEveryCandidateVector(testCase)
        p = hw3Params();
        [~, ~, sadMap] = fullSearchMacroblock(testCase.Target, testCase.Reference, 5, 6);
        testCase.verifySize(sadMap, [15 15]);
        testCase.verifyEqual(numel(sadMap), p.candidates);
    end

    function borderSearchScoresOnlyCandidatesInsideTheFrame(testCase)
        [~, ~, corner] = fullSearchMacroblock(testCase.Target, testCase.Reference, 1, 1);
        [~, ~, topRow] = fullSearchMacroblock(testCase.Target, testCase.Reference, 1, 5);
        [~, ~, leftColumn] = fullSearchMacroblock(testCase.Target, testCase.Reference, 5, 1);
        testCase.verifySize(corner, [8 8]);
        testCase.verifySize(topRow, [8 15]);
        testCase.verifySize(leftColumn, [15 8]);
    end

    function sadMapMatchesDirectComputation(testCase)
        [~, ~, sadMap] = fullSearchMacroblock(testCase.Target, testCase.Reference, 5, 6);
        expected = zeros(15, 15);
        block = testCase.Target(65:80, 81:96);
        for dy = -7:7
            for dx = -7:7
                matched = testCase.Reference(65 + dy:80 + dy, 81 + dx:96 + dx);
                expected(dy + 8, dx + 8) = sum(sum(abs(block - matched)));
            end
        end
        testCase.verifyEqual(sadMap, expected);
    end

    function minimumComesFromTheMapAndMatchesTheVector(testCase)
        [mv, minSad, sadMap] = fullSearchMacroblock( ...
            testCase.Target, testCase.Reference, 5, 6);
        testCase.verifyEqual(minSad, min(sadMap(:)));
        testCase.verifyEqual(sadMap(mv(2) + 8, mv(1) + 8), minSad);
    end

    function positiveAndNegativeErrorsDoNotCancel(testCase)
        checker = 5 * (-1) .^ ((1:16).' + (1:16));
        target = testCase.Reference;
        target(65:80, 81:96) = testCase.Reference(65:80, 81:96) + checker;
        [~, ~, sadMap] = fullSearchMacroblock(target, testCase.Reference, 5, 6);
        testCase.verifyEqual(sadMap(8, 8), 16 * 16 * 5);
    end

    function uint8InputDoesNotSaturate(testCase)
        target = zeros(144, 176, 'uint8');
        reference = 255 * ones(144, 176, 'uint8');
        [mv, minSad, sadMap] = fullSearchMacroblock(target, reference, 5, 6);
        testCase.verifyEqual(minSad, 255 * 256);
        testCase.verifyClass(minSad, 'double');
        testCase.verifyClass(sadMap, 'double');
        testCase.verifyTrue(all(sadMap(:) == 255 * 256));
        testCase.verifyEqual(mv, [0 0]);
    end

    function flatPlanesTieEverywhereAndPickZeroMotion(testCase)
        flat = 100 * ones(144, 176);
        [mv, minSad, sadMap] = fullSearchMacroblock(flat, flat, 5, 6);
        testCase.verifyEqual(mv, [0 0]);
        testCase.verifyEqual(minSad, 0);
        testCase.verifyEqual(sadMap, zeros(15, 15));
    end

    function nearestTieBeatsScanOrder(testCase)
        target = 100 * ones(144, 176);
        reference = target;
        reference(65, 81) = 0;
        reference(65, 97) = 0;
        [mv, minSad, sadMap] = fullSearchMacroblock(target, reference, 5, 6);
        testCase.verifyEqual(sadMap(9, 1), 0);
        testCase.verifyGreaterThan(sadMap(8, 8), 0);
        testCase.verifyEqual(minSad, 0);
        testCase.verifyEqual(mv, [0 1]);
    end

    function cornerBlockFindsDisplacementInsideTheFrame(testCase)
        target = plantBlock(testCase.Reference, 1, 1, 4, 3);
        [mv, minSad] = fullSearchMacroblock(target, testCase.Reference, 1, 1);
        testCase.verifyEqual(mv, [4 3]);
        testCase.verifyEqual(minSad, 0);

        target = plantBlock(testCase.Reference, 9, 11, -5, -6);
        [mv, minSad] = fullSearchMacroblock(target, testCase.Reference, 9, 11);
        testCase.verifyEqual(mv, [-5 -6]);
        testCase.verifyEqual(minSad, 0);
    end

    function everyVectorKeepsTheMatchedBlockInsideTheFrame(testCase)
        for row = 1:9
            for col = 1:11
                mv = fullSearchMacroblock(testCase.Target, testCase.Reference, row, col);
                [~, origin] = extractMacroblock(testCase.Target, row, col);
                topLeft = origin + [mv(2) mv(1)];
                testCase.verifyLessThanOrEqual(abs(mv), 7);
                testCase.verifyGreaterThanOrEqual(topLeft, [1 1]);
                testCase.verifyLessThanOrEqual(topLeft, [144 176] - 15);
            end
        end
    end

    function explicitSizesMatchDefaults(testCase)
        [mvA, sadA, mapA] = fullSearchMacroblock(testCase.Target, testCase.Reference, 5, 6);
        [mvB, sadB, mapB] = fullSearchMacroblock( ...
            testCase.Target, testCase.Reference, 5, 6, 16, 7);
        testCase.verifyEqual(mvB, mvA);
        testCase.verifyEqual(sadB, sadA);
        testCase.verifyEqual(mapB, mapA);
    end

    function smallerRadiusShrinksTheSearch(testCase)
        target = plantBlock(testCase.Reference, 5, 6, 2, -1);
        [mv, minSad, sadMap] = fullSearchMacroblock(target, testCase.Reference, 5, 6, 16, 2);
        testCase.verifySize(sadMap, [5 5]);
        testCase.verifyEqual(mv, [2 -1]);
        testCase.verifyEqual(minSad, 0);
    end

    function zeroRadiusComparesOnlyTheCollocatedBlock(testCase)
        [mv, minSad, sadMap] = fullSearchMacroblock( ...
            testCase.Target, testCase.Reference, 5, 6, 16, 0);
        direct = sum(sum(abs(testCase.Target(65:80, 81:96) - ...
            testCase.Reference(65:80, 81:96))));
        testCase.verifyEqual(mv, [0 0]);
        testCase.verifyEqual(sadMap, direct);
        testCase.verifyEqual(minSad, direct);
    end

    function integerArgumentsDoNotSaturate(testCase)
        target = plantBlock(testCase.Reference, 9, 11, -5, -6);
        [mvD, sadD, mapD] = fullSearchMacroblock(target, testCase.Reference, 9, 11);
        [mv, minSad, sadMap] = fullSearchMacroblock( ...
            uint8(target), uint8(testCase.Reference), ...
            int8(9), int8(11), int8(16), int8(7));
        testCase.verifyEqual(mv, mvD);
        testCase.verifyEqual(minSad, sadD);
        testCase.verifyEqual(sadMap, mapD);
        testCase.verifyClass(mv, 'double');
    end

    function searchingTheIFrameAgainstItselfFindsZeroMotion(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:20);
        reference = S.Y(:, :, S.referenceIndex);
        [mv, minSad] = fullSearchMacroblock(reference, reference, 5, 6);
        testCase.verifyEqual(mv, [0 0]);
        testCase.verifyEqual(minSad, 0);
    end

    function pFrameSearchBeatsZeroMotionOnEveryBlock(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:20);
        reference = S.Y(:, :, S.referenceIndex);
        target = S.Y(:, :, 2);
        for row = 1:S.mbGrid.rows
            for col = 1:S.mbGrid.cols
                [mv, minSad] = fullSearchMacroblock(target, reference, row, col);
                [block, origin] = extractMacroblock(target, row, col);
                collocated = extractMacroblock(reference, row, col);
                top = origin(1) + mv(2);
                left = origin(2) + mv(1);
                matched = reference(top:top + 15, left:left + 15);
                testCase.verifyEqual(minSad, sum(abs(block(:) - matched(:))));
                testCase.verifyLessThanOrEqual(minSad, sum(abs(block(:) - collocated(:))));
                testCase.verifyLessThanOrEqual(abs(mv), 7);
            end
        end
    end

    function chromaSearchUsesHalfSizeBlocksAndRadius(testCase)
        S = loadWalkSequence(testCase.VideoPath, 16:20);
        plane = S.Cb420(:, :, S.referenceIndex);
        [mv, minSad, sadMap] = fullSearchMacroblock(plane, plane, 5, 6, 8, 3);
        testCase.verifySize(sadMap, [7 7]);
        testCase.verifyEqual(mv, [0 0]);
        testCase.verifyEqual(minSad, 0);
    end

    function rejectsPlanesOfDifferentSizes(testCase)
        testCase.verifyError(@() fullSearchMacroblock( ...
            ones(144, 176), ones(144, 160), 1, 1), ...
            'fullSearchMacroblock:sizeMismatch');
    end

    function rejectsBadRadius(testCase)
        testCase.verifyError(@() fullSearchMacroblock( ...
            testCase.Target, testCase.Reference, 5, 6, 16, -1), ...
            'extractSearchWindow:badRadius');
    end

    function rejectsRowPastTheGrid(testCase)
        testCase.verifyError(@() fullSearchMacroblock( ...
            testCase.Target, testCase.Reference, 10, 1), ...
            'extractMacroblock:outOfRange');
    end

    function rejectsPlaneThatIsNotWholeBlocks(testCase)
        testCase.verifyError(@() fullSearchMacroblock( ...
            ones(20, 40), ones(20, 40), 1, 1), ...
            'extractMacroblock:ragged');
    end
end

end

function target = plantBlock(reference, row, col, dx, dy)
mbSize = 16;
top = (row - 1) * mbSize + 1;
left = (col - 1) * mbSize + 1;
target = reference;
target(top:top + mbSize - 1, left:left + mbSize - 1) = ...
    reference(top + dy:top + dy + mbSize - 1, left + dx:left + dx + mbSize - 1);
end
