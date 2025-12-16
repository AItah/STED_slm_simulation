function beam = load_gaussian_beam_params(jsonFile)
%LOAD_GAUSSIAN_BEAM_PARAMS Load Gaussian beam parameters from JSON (strict + GBT aliases).
%
% This loader supports the "legacy" fields used by make_gaussian_input_beam
% AND also populates convenience aliases needed by generate_focal_field_gbt:
%
%   Legacy / JSON fields:
%       beam_type      : 'gaussian'
%       lambda_m       : wavelength [m]
%       w0x_1e2_m      : 1/e^2 intensity radius in x at waist [m]
%       w0y_1e2_m      : 1/e^2 intensity radius in y at waist [m]
%       center_x_m     : beam center [m]
%       center_y_m     : beam center [m]
%       M2             : (optional) beam quality factor (same for x,y)
%       waist_z_m      : (optional) z-position of waist [m]
%       power_norm     : (optional) amplitude scaling (legacy)
%       Amp            : (optional) *explicit* field amplitude scale
%
%   GBT-friendly aliases added here:
%       w_0x_m, w_0y_m : waist radii [m] (same as w0x_1e2_m, w0y_1e2_m)
%       M2x, M2y       : M^2 in x and y (copied from M2)
%       z_0x_m, z_0y_m : waist positions [m] (copied from waist_z_m)
%       Amp            : final amplitude scale used by GBT
%
% Usage:
%   beam = load_gaussian_beam_params('GaussianBeam.json');

    beam = read_json_file(jsonFile);

    % -------- Required fields (legacy format) --------
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

    % -------- Optional legacy fields & defaults --------
    if ~isfield(beam, 'M2')
        beam.M2 = 1.0;
    end
    if ~isfield(beam, 'waist_z_m')
        beam.waist_z_m = 0.0;
    end
    if ~isfield(beam, 'power_norm')
        beam.power_norm = 1.0;
    end
    % If Amp not given explicitly, derive it from power_norm
    % (we treat power_norm as an amplitude scaling, for backward
    % compatibility with make_gaussian_input_beam).
    if ~isfield(beam, 'Amp')
        beam.Amp = beam.power_norm;
    end

    % -------- Cast numerics to double --------
    beam.lambda_m   = double(beam.lambda_m);
    beam.w0x_1e2_m  = double(beam.w0x_1e2_m);
    beam.w0y_1e2_m  = double(beam.w0y_1e2_m);
    beam.center_x_m = double(beam.center_x_m);
    beam.center_y_m = double(beam.center_y_m);
    beam.M2         = double(beam.M2);
    beam.waist_z_m  = double(beam.waist_z_m);
    beam.power_norm = double(beam.power_norm);
    beam.Amp        = double(beam.Amp);

    % -------- GBT-friendly aliases --------
    % Waist radii (1/e^2 intensity) – your GBT code expects these as w_0x_m, w_0y_m
    beam.w_0x_m = beam.w0x_1e2_m;
    beam.w_0y_m = beam.w0y_1e2_m;

    % M^2 in x and y (for now assume same in both axes; can generalize later)
    beam.M2x = beam.M2;
    beam.M2y = beam.M2;

    % Waist positions in x and y (again same scalar, but kept separately for generality)
    beam.z_0x_m = beam.waist_z_m;
    beam.z_0y_m = beam.waist_z_m;
end
