function s = read_json_file(jsonFile)
%READ_JSON_FILE Generic JSON loader.
%   s = READ_JSON_FILE(jsonFile) reads a JSON file and returns a struct.
%
% Compatible with MATLAB R2017b.

    if exist(jsonFile, 'file') ~= 2
        error('JSON file not found: %s', jsonFile);
    end

    raw = fileread(jsonFile);
    s = jsondecode(raw);

    if ~isstruct(s)
        error('JSON root must decode to a struct: %s', jsonFile);
    end
end
