classdef projectLayoutTest < matlab.unittest.TestCase
methods (TestClassSetup)
    function addSourceToPath(~)
        here = fileparts(mfilename('fullpath'));
        addpath(fullfile(fileparts(here), 'src'));
    end
end

methods (Test)
    function setupProjectIsRepeatable(testCase)
        root = fileparts(fileparts(mfilename('fullpath')));
        first = setupProject('Verbose', false);
        second = setupProject('Verbose', false);
        testCase.verifyEqual(first, second);
        testCase.verifyTrue(isfolder(fullfile(root, 'results')));
    end

    function codeAnalyzerIsClean(testCase)
        findings = checkProjectCode('Verbose', false);
        details = arrayfun(@(f) sprintf('%s:%d %s', f.file, f.line, f.message), ...
            findings, 'UniformOutput', false);
        testCase.verifyEmpty(findings, ...
            ['Code Analyzer reported findings:' newline strjoin(details, newline)]);
    end

    function sourceFilesArePresent(testCase)
        root = fileparts(fileparts(mfilename('fullpath')));
        required = {'hw3Params.m', 'frameTypesFor.m', 'loadWalkSequence.m', ...
            'writeYuv420.m', 'setupProject.m', 'checkProjectCode.m', ...
            'relativePath.m', 'extractMacroblock.m', 'extractSearchWindow.m', ...
            'fullSearchMacroblock.m', 'fullSearchFrame.m', ...
            'reconstructPFrame.m', 'fullSearchLoad.m'};
        for k = 1:numel(required)
            testCase.verifyTrue(isfile(fullfile(root, 'src', required{k})), ...
                sprintf('Missing src/%s', required{k}));
        end
    end
end

end
