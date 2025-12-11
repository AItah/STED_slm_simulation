function lens_mask = make_lens_phase(coords, lambda_m, f_focus_m)
%MAKE_LENS_PHASE Fresnel (quadratic) lens phase term.
%
% Inputs:
%   coords     - must include X, Y (physical grids in meters)
%   lambda_m   - wavelength [m]
%   f_focus_m  - focal distance [m]
%
% Output:
%   lens_mask  - phase map [rad]
%
% Convention matches your existing sign:
%   desired = desired - pi/(lambda*f) * (X^2 + Y^2)

    if ~isfield(coords, 'X') || ~isfield(coords, 'Y')
        error('coords must contain X and Y for lens phase.');
    end
    if lambda_m <= 0 || f_focus_m <= 0
        error('lambda_m and f_focus_m must be > 0.');
    end

    lens_mask = - pi/(lambda_m * f_focus_m) * (coords.X.^2 + coords.Y.^2);
end
