function slm = load_slm_params(jsonFile)
%LOAD_SLM_PARAMS Load and validate SLM parameters from JSON (strict schema,
% optional lambda_m).

    slm = read_json_file(jsonFile);

    % Required canonical fields (lambda_m is optional)
    required = { ...
        'Nx', ...
        'Ny', ...
        'px_side_m', ...
        'py_side_m', ...
        'Fill_factor_percent', ...
        'beam_diameter_mm', ...
        'c2pi2unit' ...
    };
    require_fields(slm, required, jsonFile);

    % --- Generic validations ---
    validate_positive_fields(slm, required, jsonFile);
    validate_positive_if_present(slm, 'lambda_m', 'lambda_m');

    % --- Range/special-case validations ---
    validate_range(slm, 'Fill_factor_percent', 0, 100, true, true, ...
        'Fill_factor_percent must be in (0, 100]');

    validate_range(slm, 'c2pi2unit', 1, 255, true, true, ...
        'c2pi2unit must be in [1, 255]');

    % --- Cast required numerics safely in a loop ---
    slm = cast_fields_to_double(slm, required);

    % Optional lambda cast only if present
    if isfield(slm, 'lambda_m') && ~isempty(slm.lambda_m)
        slm.lambda_m = double(slm.lambda_m);
    end
end


%% ===== Helpers =====

function validate_positive_fields(s, fieldList, jsonFile)
% Validate all fields in fieldList are positive (assumes they exist).

    for k = 1:numel(fieldList)
        f = fieldList{k};
        v = s.(f);

        if isempty(v) || ~isnumeric(v) || any(v(:) <= 0)
            error('Field "%s" must be numeric and > 0. File: %s', f, jsonFile);
        end
    end
end

function validate_positive_if_present(s, fieldName, label)
% Validate positive only if field exists.

    if isfield(s, fieldName) && ~isempty(s.(fieldName))
        v = s.(fieldName);
        if ~isnumeric(v) || any(v(:) <= 0)
            error('%s must be numeric and > 0', label);
        end
    end
end

function validate_range(s, fieldName, lo, hi, openLo, closedHi, msg)
% Validate numeric range for an existing field.
% openLo=true means > lo, false means >= lo
% closedHi=true means <= hi, false means < hi

    if ~isfield(s, fieldName) || isempty(s.(fieldName))
        error('Missing required field "%s"', fieldName);
    end

    v = s.(fieldName);
    if ~isnumeric(v)
        error('Field "%s" must be numeric', fieldName);
    end

    if openLo
        okLo = all(v(:) > lo);
    else
        okLo = all(v(:) >= lo);
    end

    if closedHi
        okHi = all(v(:) <= hi);
    else
        okHi = all(v(:) < hi);
    end

    if ~(okLo && okHi)
        error(msg);
    end
end

function s = cast_fields_to_double(s, fieldList)
% Cast listed fields to double.

    for k = 1:numel(fieldList)
        f = fieldList{k};
        s.(f) = double(s.(f));
    end
end
