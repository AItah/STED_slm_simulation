function beam = load_gaussian_beam_params(jsonFile)
%LOAD_GAUSSIAN_BEAM_PARAMS Load Gaussian beam parameters from JSON (strict).

    beam = read_json_file(jsonFile);

    required = { ...
        'beam_type', ...
        'lambda_m', ...
        'w0x_1e2_m', ...
        'w0y_1e2_m', ...
        'center_x_m', ...
        'center_y_m' ...
    };

    require_fields(beam, required, jsonFile);

    if ~strcmp(beam.beam_type, 'gaussian')
        error('Unsupported beam_type "%s" in %s', beam.beam_type, jsonFile);
    end

    if beam.lambda_m <= 0
        error('beam.lambda_m must be > 0');
    end
    if beam.w0x_1e2_m <= 0 || beam.w0y_1e2_m <= 0
        error('w0x_1e2_m and w0y_1e2_m must be > 0');
    end

    % optional
    if ~isfield(beam, 'power_norm')
        beam.power_norm = 1.0;
    end

    % Cast numerics
    beam.lambda_m   = double(beam.lambda_m);
    beam.w0x_1e2_m  = double(beam.w0x_1e2_m);
    beam.w0y_1e2_m  = double(beam.w0y_1e2_m);
    beam.center_x_m = double(beam.center_x_m);
    beam.center_y_m = double(beam.center_y_m);
    beam.power_norm = double(beam.power_norm);
end
