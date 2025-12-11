function g = make_flat_soft_input_beam(coords, beam_diameter_mm, edge_width_px)
%MAKE_FLAT_SOFT_INPUT Flat-top beam with soft edges in physical coordinates.
%
%   ap_mask = make_flat_soft_input(coords, beam_diameter_mm, edge_width_px)
%
% Inputs:
%   coords           - struct from make_coordinates (must contain X, Y, px_m, py_m)
%   beam_diameter_mm - beam diameter [mm] at 1 (flat region) before soft edge
%   edge_width_px    - approximate soft edge width, in "pixels" (samples)
%
% Output:
%   ap_mask          - Ny x Nx amplitude mask (0..1), flat in center with soft edge
%
% The aperture is circular in *physical* space:
%   radius = beam_diameter_mm/2 (converted to meters)
% The soft edge is defined in meters using an average sampling pitch.
%
% Compatible with MATLAB R2017b.

    % --- Basic checks ---
    if ~isfield(coords, 'X') || ~isfield(coords, 'Y')
        error('coords must contain fields X and Y (physical grids in meters).');
    end
    if ~isfield(coords, 'px_m') || ~isfield(coords, 'py_m')
        error('coords must contain px_m and py_m.');
    end

    if nargin < 3 || isempty(edge_width_px)
        edge_width_px = 5; % default soft edge ~5 samples
    end

    if beam_diameter_mm <= 0
        error('beam_diameter_mm must be > 0');
    end

    % --- Physical beam radius in meters ---
    ap_rad_m = beam_diameter_mm * 1e-3 / 2;   % [m]

    % --- Convert edge width (in "pixels") to meters ---
    pitch_avg = mean([coords.px_m, coords.py_m]);   % [m/sample]
    edge_m    = edge_width_px * pitch_avg;          % [m]

    % --- Radial coordinate in physical space ---
    R_phys = sqrt(coords.X.^2 + coords.Y.^2);

    % --- Electric field amplitude (real, positive) ---
    E_amp = 0.5 * (1 - tanh((R_phys - ap_rad_m) / edge_m));

    % --- Intensity ---
    I = abs(E_amp).^2;

    % --- Pack output struct ---
    g       = struct();
    g.E_amp = E_amp;
    g.I     = I;
end
