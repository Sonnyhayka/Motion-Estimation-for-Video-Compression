classdef fullSearchFrameTest < matlab.unittest.TestCase
methods (TestClassSetup)
    function addSourceToPath(~)
        here = fileparts(mfilename('fullpath'));
        addpath(fullfile(fileparts(here), 'src'));
    end
end

methods (Test)
    function matchesEveryBlockAndStoresVectors(testCase)
        stream = RandStream('mt19937ar', 'Seed', 19);
        reference = uint8(randi(stream, 256, 144, 176) - 1);
        target = reference;
        shifts = [4 3; -3 2; 2 -4; -5 -6];
        positions = [1 1; 1 11; 9 1; 9 11];
        for k = 1:size(positions, 1)
            top = (positions(k, 1) - 1) * 16 + 1;
            left = (positions(k, 2) - 1) * 16 + 1;
            dx = shifts(k, 1);
            dy = shifts(k, 2);
            target(top:top + 15, left:left + 15) = ...
                reference(top + dy:top + dy + 15, left + dx:left + dx + 15);
        end

        [vectors, matched, sads] = fullSearchFrame(target, reference);
        testCase.verifySize(vectors, [9 11 2]);
        testCase.verifySize(sads, [9 11]);
        testCase.verifyClass(matched, 'uint8');
        testCase.verifyEqual(matched, target);
        testCase.verifyEqual(sads, zeros(9, 11));
        for k = 1:size(positions, 1)
            row = positions(k, 1);
            col = positions(k, 2);
            testCase.verifyEqual(reshape(vectors(row, col, :), 1, 2), shifts(k, :));
        end
        testCase.verifyEqual(reshape(vectors(5, 6, :), 1, 2), [0 0]);
    end

    function outputBlocksAndSadsAgreeWithVectors(testCase)
        stream = RandStream('mt19937ar', 'Seed', 42);
        reference = randi(stream, 256, 32, 48) - 1;
        target = randi(stream, 256, 32, 48) - 1;
        [vectors, matched, sads] = fullSearchFrame(target, reference, 8, 3);
        testCase.verifySize(vectors, [4 6 2]);
        for row = 1:4
            for col = 1:6
                [block, origin] = extractMacroblock(target, row, col, 8);
                mv = reshape(vectors(row, col, :), 1, 2);
                top = origin(1) + mv(2);
                left = origin(2) + mv(1);
                expected = reference(top:top + 7, left:left + 7);
                testCase.verifyEqual(extractMacroblock(matched, row, col, 8), expected);
                testCase.verifyEqual(sads(row, col), sum(abs(block(:) - expected(:))));
            end
        end
    end

    function rejectsInvalidInputs(testCase)
        testCase.verifyError(@() fullSearchFrame(ones(32), ones(16)), ...
            'fullSearchFrame:sizeMismatch');
        testCase.verifyError(@() fullSearchFrame(ones(20), ones(20)), ...
            'extractMacroblock:ragged');
        testCase.verifyError(@() fullSearchFrame(ones(32), ones(32), 16, -1), ...
            'extractSearchWindow:badRadius');
    end

    function searchesAllPFramesAgainstTheIFrame(testCase)
        here = fileparts(mfilename('fullpath'));
        S = loadWalkSequence(fullfile(fileparts(here), 'data', 'walk_qcif.avi'), 16:20);
        reference = S.Y(:, :, S.referenceIndex);
        for frame = 2:numel(S.frameNumbers)
            target = S.Y(:, :, frame);
            [vectors, matched, sads] = fullSearchFrame(target, reference);
            testCase.verifySize(vectors, [9 11 2]);
            for row = 1:9
                for col = 1:11
                    block = extractMacroblock(target, row, col);
                    prediction = extractMacroblock(matched, row, col);
                    collocated = extractMacroblock(reference, row, col);
                    testCase.verifyEqual(sads(row, col), sum(abs(block(:) - prediction(:))));
                    testCase.verifyLessThanOrEqual(sads(row, col), ...
                        sum(abs(block(:) - collocated(:))));
                end
            end
        end
    end
end
end
