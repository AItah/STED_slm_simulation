function coords = make_coordinates(Nx, Ny, px_m, py_m, force_zero)
%MAKE_COORDINATES Build pixel and physical coordinate grids.
%
%   coords = make_coordinates(Nx, Ny, px_m, py_m)
%   coords = make_coordinates(Nx, Ny, px_m, py_m, force_zero)
%
% Inputs:
%   Nx, Ny      - number of samples in x and y
%   px_m        - sampling pitch in x [m]
%   py_m        - sampling pitch in y [m]
%   force_zero  - (optional, logical) 
%                 false (default): "symmetric" convention
%                     x_pix = (0:Nx-1) - (Nx-1)/2
%                     y_pix = (0:Ny-1) - (Ny-1)/2
%                     -> origin lies between central pixels for even Nx/Ny
%                 true: "pixel-at-zero" convention
%                     even Nx: x_pix = (0:Nx-1) - Nx/2    (0 on a pixel)
%                     odd  Nx: x_pix = (0:Nx-1) - (Nx-1)/2
%
% Outputs (struct):
%   coords.Nx, coords.Ny
%   coords.px_m, coords.py_m
%   coords.x_pix, coords.y_pix     - 1D index axes [samples]
%   coords.xi, coords.yi           - index grids (Ny x Nx)
%   coords.X, coords.Y             - physical grids [m]
%   coords.x_m, coords.y_m         - 1D physical axes [m]
%   coords.x_mm, coords.y_mm       - 1D physical axes [mm]
%   coords.theta_px                - angle from index grids
%   coords.theta                   - angle from physical grids
%   coords.center_mode             - 'symmetric' or 'pixel_zero'
%
% Compatible with MATLAB R2017b.

    % ---- Handle optional argument ----
    if nargin < 5 || isempty(force_zero)
        force_zero = false;
    end

    % ---- Validation ----
    if ~isscalar(Nx) || ~isscalar(Ny) || Nx <= 0 || Ny <= 0
        error('Nx and Ny must be positive scalars.');
    end
    if ~isscalar(px_m) || ~isscalar(py_m) || px_m <= 0 || py_m <= 0
        error('px_m and py_m must be positive scalars in meters.');
    end

    Nx   = double(Nx);
    Ny   = double(Ny);
    px_m = double(px_m);
    py_m = double(py_m);

    % ---- Centered index vectors depending on convention ----
    if force_zero
        % "pixel-at-zero" convention:
        % even Nx: x_pix = -Nx/2 : Nx/2-1   (pixel at 0)
        % odd  Nx: symmetric as usual
        if mod(Nx,2) == 0
            x_pix = (0:Nx-1) - Nx/2;
        else
            x_pix = (0:Nx-1) - (Nx-1)/2;
        end

        if mod(Ny,2) == 0
            y_pix = (0:Ny-1) - Ny/2;
        else
            y_pix = (0:Ny-1) - (Ny-1)/2;
        end

        center_mode = 'pixel_zero';
    else
        % "symmetric" convention: origin between pixels for even Nx/Ny
        x_pix = (0:Nx-1) - (Nx-1)/2;
        y_pix = (0:Ny-1) - (Ny-1)/2;
        center_mode = 'symmetric';
    end

    % ---- Index grids ----
    [xi, yi] = meshgrid(x_pix, y_pix); % size Ny x Nx

    % ---- Physical axes ----
    x_m = x_pix * px_m;
    y_m = y_pix * py_m;

    % ---- Physical grids ----
    X = xi * px_m;
    Y = yi * py_m;

    % ---- Pack ----
    coords = struct();
    coords.Nx   = Nx;
    coords.Ny   = Ny;
    coords.px_m = px_m;
    coords.py_m = py_m;

    coords.x_pix = x_pix;
    coords.y_pix = y_pix;

    coords.xi = xi;
    coords.yi = yi;
    
    coords.theta_px = atan2(yi, xi);

    coords.x_m  = x_m;
    coords.y_m  = y_m;

    coords.X = X;
    coords.Y = Y;

    coords.x_mm = x_m * 1e3;
    coords.y_mm = y_m * 1e3;
    
    coords.theta       = atan2(Y, X);
    coords.center_mode = center_mode;
end
