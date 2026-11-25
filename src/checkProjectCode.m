function findings = checkProjectCode(options)
arguments
    options.ExitOnFailure (1, 1) logical = false
    options.Verbose (1, 1) logical = true
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));

targets = [ ...
    collectMFiles(fullfile(projectRoot, 'src')); ...
    collectMFiles(fullfile(projectRoot, 'scripts')); ...
    collectMFiles(fullfile(projectRoot, 'tests'))];

results = cell(1, numel(targets));
for k = 1:numel(targets)
    results{k} = lintOne(targets{k});
end
findings = [results{:}];

if options.Verbose
    fprintf('Code Analyzer\n');
    fprintf('files checked: %d\n', numel(targets));
    if isempty(findings)
        fprintf('[ok] no findings\n');
    else
        for k = 1:numel(findings)
            fprintf('[warn] %s:%d: %s\n', relativePath(findings(k).file, projectRoot), ...
                findings(k).line, findings(k).message);
        end
        fprintf('[fail] %d finding(s) across %d file(s)\n', ...
            numel(findings), numel(unique({findings.file})));
    end
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

function files = collectMFiles(folder)
files = cell(0, 1);
if ~isfolder(folder)
    return
end

items = dir(fullfile(folder, '**', '*.m'));
items = items(~[items.isdir]);
if isempty(items)
    return
end
files = fullfile({items.folder}, {items.name}).';
end
