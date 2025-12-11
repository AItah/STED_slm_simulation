function desired = make_vortex_phase(coords, ell)
%MAKE_VORTEX_PHASE Generate the vortex (spiral) desired phase: ell * theta.
%
%   desired = make_vortex_phase(coords, ell)
%
% Inputs:
%   coords - struct from make_coordinates (or compatible)
%            Expected fields (preferably):
%               coords.X, coords.Y   [m]
%            Fallback:
%               coords.xi, coords.yi [pixels]
%   ell    - topological charge (positive integer)
%
% Output:
%   desired - 2D phase map (same size as coords grids), in radians
%
% Notes:
%   Uses atan2 for correct quadrant handling.
%   Prefers physical coordinates when available.
%
% Compatible with MATLAB R2017b.

    % ---- Validate ell ----
    if ~isscalar(ell) || ~isfinite(ell) || ell < 1 || abs(ell - round(ell)) > 0
        error('ell must be a positive integer topological charge.');
    end
    ell = round(double(ell));

    % ---- Determine which coordinate system to use for theta ----
    if isfield(coords, 'X') && isfield(coords, 'Y')
        theta = atan2(coords.Y, coords.X);  % physical angle
    elseif isfield(coords, 'xi') && isfield(coords, 'yi')
        theta = atan2(coords.yi, coords.xi); % pixel angle fallback
    else
        error('coords must contain either (X,Y) or (xi,yi).');
    end

    desired = ell * theta;
end
