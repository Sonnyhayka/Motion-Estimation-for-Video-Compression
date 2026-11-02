function projectRoot = setupProject(options)
arguments
    options.Verbose (1, 1) logical = true
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));

srcDir = fullfile(projectRoot, 'src');
dataDir = fullfile(projectRoot, 'data');
resultsDir = fullfile(projectRoot, 'results');
frameDir = fullfile(resultsDir, 'frames');
figureDir = fullfile(resultsDir, 'figures');

pathCells = strsplit(path, pathsep);
if ~any(strcmpi(pathCells, srcDir))
    addpath(srcDir);
end

folders = {dataDir, resultsDir, frameDir, figureDir};
for k = 1:numel(folders)
    if ~isfolder(folders{k})
        mkdir(folders{k});
    end
end

if options.Verbose
    fprintf('Project root : %s\n', projectRoot);
    fprintf('Source folder: %s\n', srcDir);
    fprintf('Results      : %s\n', resultsDir);
end
end
