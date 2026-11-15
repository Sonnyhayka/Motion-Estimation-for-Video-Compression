function findings = checkProjectCode(options)
arguments
    options.ExitOnFailure (1, 1) logical = false
    options.Verbose (1, 1) logical = true
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));

targets = [ ...
    collectMFiles(fullfile(projectRoot, 'src'), true); ...
    collectMFiles(projectRoot, false); ...
    collectMFiles(fullfile(projectRoot, 'scripts'), true); ...
    collectMFiles(fullfile(projectRoot, 'tests'), true)];
targets = unique(targets);

results = cell(1, numel(targets));
for k = 1:numel(targets)
    results{k} = lintOne(targets{k});
end

findings = [results{:}];

if ~options.Verbose
    if options.ExitOnFailure && ~isempty(findings)
        error('checkProjectCode:findings', ...
            'Code Analyzer reported %d finding(s).', numel(findings));
    end
    return
end

fprintf('Code Analyzer\n');
fprintf('files checked: %d\n', numel(targets));

if isempty(findings)
    fprintf('[ok] no findings\n');
else
    for k = 1:numel(findings)
        rel = relativePath(findings(k).file, projectRoot);
        fprintf('[warn] %s:%d: %s\n', rel, findings(k).line, findings(k).message);
        fprintf('::error file=%s,line=%d::%s\n', rel, findings(k).line, findings(k).message);
    end
    fprintf('[fail] %d finding(s) across %d file(s)\n', ...
        numel(findings), numel(unique({findings.file})));
end

if options.ExitOnFailure && ~isempty(findings)
    error('checkProjectCode:findings', ...
        'Code Analyzer reported %d finding(s).', numel(findings));
end
end

function out = lintOne(file)
out = struct('file', {}, 'line', {}, 'column', {}, 'message', {});

try
    report = checkcode(file, '-struct');
catch err
    out = struct('file', file, 'line', 0, 'column', 0, 'message', err.message);
    return
end

for j = 1:numel(report)
    out(j) = struct( ...
        'file', file, ...
        'line', report(j).line, ...
        'column', report(j).column, ...
        'message', strtrim(report(j).message));
end
end

function files = collectMFiles(folder, recursive)
files = cell(0, 1);
if ~isfolder(folder)
    return
end

if recursive
    items = dir(fullfile(folder, '**', '*.m'));
else
    items = dir(fullfile(folder, '*.m'));
end

items = items(~[items.isdir]);
files = cell(numel(items), 1);
for k = 1:numel(items)
    files{k} = fullfile(items(k).folder, items(k).name);
end
end

function p = relativePath(absPath, root)
p = absPath;
prefix = [root filesep];
if strncmpi(absPath, prefix, numel(prefix))
    p = absPath(numel(prefix) + 1:end);
end
p = strrep(p, filesep, '/');
end
