classdef projectLayoutTest < matlab.unittest.TestCase
%PROJECTLAYOUTTEST Verify the repository is wired for reproducible runs.

methods (Test)
    function setupProjectIsRepeatable(testCase)
        root = fileparts(fileparts(mfilename('fullpath')));
        addpath(fullfile(root, 'src'));
        first = setupProject('Verbose', false);
        second = setupProject('Verbose', false);
        testCase.verifyEqual(first, second);
        testCase.verifyTrue(isfolder(fullfile(root, 'results')));
    end

    function codeAnalyzerIsClean(testCase)
        root = fileparts(fileparts(mfilename('fullpath')));
        addpath(fullfile(root, 'src'));
        findings = checkProjectCode('Verbose', false);
        if ~isempty(findings)
            for k = 1:numel(findings)
                testCase.diagnostic = sprintf('%s:%d %s', ...
                    findings(k).file, findings(k).line, findings(k).message);
            end
        end
        testCase.verifyEmpty(findings, 'Code Analyzer reported findings.');
    end

    function sourceFilesArePresent(testCase)
        root = fileparts(fileparts(mfilename('fullpath')));
        required = {'hw3Params.m', 'loadWalkSequence.m', 'setupProject.m', ...
            'checkProjectCode.m'};
        for k = 1:numel(required)
            testCase.verifyTrue(isfile(fullfile(root, 'src', required{k})), ...
                sprintf('Missing src/%s', required{k}));
        end
    end
end

end
