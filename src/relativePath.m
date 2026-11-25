function p = relativePath(absPath, root)
p = absPath;
prefix = [root filesep];
if strncmpi(absPath, prefix, numel(prefix))
    p = absPath(numel(prefix) + 1:end);
end
p = strrep(p, filesep, '/');
end
