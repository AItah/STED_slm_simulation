function require_fields(s, required, jsonFile)
%REQUIRE_FIELDS Ensures struct s has all required fields.
% Gives a helpful error listing missing and existing fields.

    if nargin < 3, jsonFile = '<unknown file>'; end

    missing = {};
    for k = 1:numel(required)
        if ~isfield(s, required{k})
            missing{end+1} = required{k}; %#ok<AGROW>
        end
    end

    if ~isempty(missing)
        found = fieldnames(s);
        error('Missing required field(s): %s\nFound field(s): %s\nFile: %s', ...
            strjoin(missing, ', '), strjoin(found, ', '), jsonFile);
    end
end
