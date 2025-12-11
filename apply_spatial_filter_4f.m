function [pinhole_plane, image_plane] = apply_spatial_filter_4f(E_in, coords_in, lambda_m, f1_m, f2_m, pinhole_d_m)
%APPLY_SPATIAL_FILTER_4F 4f system: lens1 + pinhole + lens2.
%
% Inputs:
%   E_in        - complex field at input plane (Plane A)
%   coords_in   - struct from make_coordinates (must contain Nx, Ny, px_m, py_m, X, Y, x_mm, y_mm)
%   lambda_m    - wavelength [m]
%   f1_m        - focal length lens 1 [m] (e.g. 100e-3)
%   f2_m        - focal length lens 2 [m] (e.g. 250e-3)
%   pinhole_d_m - pinhole diameter at common focal plane [m] (e.g. 25e-6)
%
% Outputs:
%   pinhole_plane - struct describing the Fourier / pinhole plane (lens-1 focal plane)
%       .coords        - coordinate struct at this plane
%       .E_before      - complex field before pinhole
%       .E_before_amp  - |E_before|
%       .I_before      - |E_before|^2
%       .E_after       - complex field after pinhole
%       .E_after_amp   - |E_after|
%       .I_after       - |E_after|^2
%       .pinhole_mask  - 0/1 mask used
%
%   image_plane   - struct describing the image plane (output of lens 2)
%       .coords   - coordinate struct at this plane (includes .M magnification)
%       .E        - complex field
%       .E_amp    - |E|
%       .I        - |E|^2
%
% Notes:
%   - Assumes input plane is at front focal plane of lens 1,
%     output plane is back focal plane of lens 2.
%   - Magnification M = f2_m / f1_m appears in image_plane.coords.M.
%
% Compatible with MATLAB R2017b.

    % ---------- Basic checks ----------
    if lambda_m <= 0 || f1_m <= 0 || f2_m <= 0 || pinhole_d_m <= 0
        error('lambda_m, f1_m, f2_m, and pinhole_d_m must be > 0.');
    end

    required = {'Nx','Ny','px_m','py_m','X','Y','x_mm','y_mm'};
    for k = 1:numel(required)
        if ~isfield(coords_in, required{k})
            error('coords_in missing required field "%s".', required{k});
        end
    end

    [Ny, Nx] = size(coords_in.X);
    if ~isequal(size(E_in), [Ny, Nx])
        error('E_in size must match coords_in.X size.');
    end

    px = coords_in.px_m;
    py = coords_in.py_m;

    % ---------- Plane: Fourier / pinhole plane (lens 1 focal plane) ----------
    fx = (-Nx/2:Nx/2-1) / (Nx * px);   % [cycles/m]
    fy = (-Ny/2:Ny/2-1) / (Ny * py);
    [FX, FY] = meshgrid(fx, fy);

    % Physical coords in focal plane of lens 1
    X_B = lambda_m * f1_m * FX;   % [m]
    Y_B = lambda_m * f1_m * FY;   % [m]

    coords_B = struct();
    coords_B.X    = X_B;
    coords_B.Y    = Y_B;
    coords_B.x_mm = X_B(1,:) * 1e3;
    coords_B.y_mm = Y_B(:,1) * 1e3;
    coords_B.Nx   = Nx;
    coords_B.Ny   = Ny;

    % Field at pinhole plane (before mask), up to global phase/scale
    E_B = fftshift(fft2(E_in));

    % Pinhole mask at this plane
    r_p = pinhole_d_m / 2;
    pinhole_mask = double( sqrt(X_B.^2 + Y_B.^2) <= r_p );

    % After pinhole
    E_B_pinhole = E_B .* pinhole_mask;

    % ---------- Plane: image plane (output of lens 2) ----------
    % In normalized FFT model, lens 2 gives an inverse FT.
    E_C = ifft2(ifftshift(E_B_pinhole));

    % Geometric magnification
    M = f2_m / f1_m;

    % New physical sampling at image plane:
    px_out = M * px;
    py_out = M * py;

    coords_C = struct();
    coords_C.Nx   = Nx;
    coords_C.Ny   = Ny;
    coords_C.px_m = px_out;
    coords_C.py_m = py_out;
    coords_C.X    = coords_in.X * M;
    coords_C.Y    = coords_in.Y * M;
    coords_C.x_mm = coords_in.x_mm * M;
    coords_C.y_mm = coords_in.y_mm * M;
    coords_C.M    = M;

    % ---------- Pack pinhole_plane struct ----------
    pinhole_plane = struct();
    pinhole_plane.coords       = coords_B;
    pinhole_plane.E_before     = E_B;
    pinhole_plane.E_before_amp = abs(E_B);
    pinhole_plane.I_before     = abs(E_B).^2;
    pinhole_plane.E_after      = E_B_pinhole;
    pinhole_plane.E_after_amp  = abs(E_B_pinhole);
    pinhole_plane.I_after      = abs(E_B_pinhole).^2;
    pinhole_plane.pinhole_mask = pinhole_mask;

    % ---------- Pack image_plane struct ----------
    image_plane = struct();
    image_plane.coords = coords_C;
    image_plane.E      = E_C;
    image_plane.E_amp  = abs(E_C);
    image_plane.I      = abs(E_C).^2;
end
