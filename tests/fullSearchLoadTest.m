classdef fullSearchLoadTest < matlab.unittest.TestCase
methods (TestClassSetup)
    function addSourceToPath(~)
        here = fileparts(mfilename('fullpath'));
        addpath(fullfile(fileparts(here), 'src'));
    end
end

methods (Test)
    function qcifCountsIncludeClippedBorders(testCase)
        counts = fullSearchLoad([144 176]);
        testCase.verifyEqual(counts.mbCount, 99);
        testCase.verifyEqual(nnz(counts.perMB.candidates == 225), 63);
        testCase.verifyEqual(nnz(counts.perMB.candidates == 120), 32);
        testCase.verifyEqual(nnz(counts.perMB.candidates == 64), 4);
        testCase.verifyEqual(counts.perFrame.candidates, 18271);
        testCase.verifyEqual(counts.perFrame.additions, 9336481);
        testCase.verifyEqual(counts.perFrame.multiplications, 0);
        testCase.verifyEqual(counts.perFrame.comparisons, 18271);
        testCase.verifyEqual(counts.perFrame.minimumComparisons, 18172);
        testCase.verifyEqual(counts.perFrame.absoluteValues, 4677376);
        testCase.verifyEqual(counts.fullWindow.perMB.additions, 114975);
        testCase.verifyEqual(counts.fullWindow.perFrame.additions, 11382525);
        testCase.verifyEqual(counts.fullWindow.perFrame.comparisons, 22275);
        testCase.verifyEqual(counts.implementation.perFrame.multiplications, 2690);
        testCase.verifyEqual(counts.implementation.perFrame.additions, 9354752);
        testCase.verifyEqual(counts.implementation.perFrame.comparisons, 54615);
    end

    function modelMatchesActualSearchMaps(testCase)
        % Includes one-block planes, radius zero, chroma-size blocks and a
        % radius large enough to reach beyond the immediately adjacent block.
        cases = {[16 16], 16, 7; [32 48], 16, 0; ...
            [24 32], 8, 3; [48 64], 16, 40};
        for k = 1:size(cases, 1)
            frameSize = cases{k, 1};
            mbSize = cases{k, 2};
            radius = cases{k, 3};
            plane = zeros(frameSize);
            counts = fullSearchLoad(frameSize, mbSize, radius);
            for row = 1:counts.mbGrid(1)
                for col = 1:counts.mbGrid(2)
                    [~, ~, sadMap] = fullSearchMacroblock( ...
                        plane, plane, row, col, mbSize, radius);
                    testCase.verifyEqual(counts.perMB.candidates(row, col), numel(sadMap));
                    testCase.verifyEqual(counts.implementation.perMB.multiplications(row, col), ...
                        sum(size(sadMap)));
                end
            end
        end
    end

    function rejectsRaggedFrame(testCase)
        testCase.verifyError(@() fullSearchLoad([145 176]), 'fullSearchLoad:ragged');
    end
end
end
