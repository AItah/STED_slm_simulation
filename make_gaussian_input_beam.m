function g = make_gaussian_input_beam(coords, beam, z_plane_m)
%MAKE_GAUSSIAN_INPUT_BEAM_M2 Gaussian amplitude at a plane using M^2 model.
% not the Intensity
% fo that we need I = abs(E).^2
%
% Inputs:
%   coords     - from make_coordinates (must contain X, Y)
%   beam       - struct from beam JSON
%   z_plane_m  - plane position [m] (default 0)
%
% Required beam fields:
%   beam.beam_type     = 'gaussian'
%   beam.lambda_m
%   beam.w0x_1e2_m, beam.w0y_1e2_m   (waist 1/e^2 intensity radii)
%   beam.center_x_m, beam.center_y_m
%
% Optional:
%   beam.M2        (default 1)
%   beam.waist_z_m (default 0)
%   beam.power_norm (default 1)
%
% Notes:
%   Uses:
%     zR = pi*w0^2/(M^2*lambda)
%     w(z) = w0*sqrt(1 + (z/zR)^2)
%   Amplitude form for 1/e^2 intensity radius:
%     A ~ exp( -(x^2/w^2) )

    if nargin < 3 || isempty(z_plane_m)
        z_plane_m = 0;
    end

    if ~isfield(coords, 'X') || ~isfield(coords, 'Y')
        error('coords must contain X and Y.');
    end

    % --- Required fields ---
    required = {'beam_type','lambda_m','w0x_1e2_m','w0y_1e2_m','center_x_m','center_y_m'};
    for k = 1:numel(required)
        if ~isfield(beam, required{k})
            error('Missing field "%s" in beam struct.', required{k});
        end
    end

    if ~strcmp(beam.beam_type, 'gaussian')
        error('Unsupported beam_type "%s".', beam.beam_type);
    end

    % --- Defaults ---
    if ~isfield(beam, 'M2'),        beam.M2 = 1.0; end
    if ~isfield(beam, 'waist_z_m'), beam.waist_z_m = 0.0; end
    if ~isfield(beam, 'power_norm'), beam.power_norm = 1.0; end

    % --- Cast ---
    lambda = double(beam.lambda_m);
    M2     = double(beam.M2);

    w0x    = double(beam.w0x_1e2_m);
    w0y    = double(beam.w0y_1e2_m);

    cx     = double(beam.center_x_m);
    cy     = double(beam.center_y_m);

    z0     = double(beam.waist_z_m);
    z      = double(z_plane_m) - z0;

    p      = double(beam.power_norm);

    if lambda <= 0 || M2 <= 0
        error('lambda_m and M2 must be > 0.');
    end
    if w0x <= 0 || w0y <= 0
        error('w0x_1e2_m and w0y_1e2_m must be > 0.');
    end

    % --- Rayleigh ranges with M^2 ---
    zRx = pi * w0x^2 / (M2 * lambda);
    zRy = pi * w0y^2 / (M2 * lambda);

    % --- Beam radii at plane ---
    wx = w0x * sqrt(1 + (z/zRx)^2);
    wy = w0y * sqrt(1 + (z/zRy)^2);

    % --- Centered coordinates ---
    Xc = coords.X - cx;
    Yc = coords.Y - cy;

    % --- Electric field amplitude (real, positive) ---
    E_amp = p * exp( -(Xc.^2)/(wx^2) - (Yc.^2)/(wy^2) );

    % --- Intensity ---
    I = abs(E_amp).^2;

    % --- Pack output struct ---
    g       = struct();
    g.E_amp = E_amp;
    g.I     = I;
    g.wx_m  = wx;
    g.wy_m  = wy;
    g.zRx_m = zRx;
    g.zRy_m = zRy;
    
end
