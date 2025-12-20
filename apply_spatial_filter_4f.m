function [pinhole_plane, image_plane] = apply_spatial_filter_4f(E_in, coords_in, lambda_m, f1_m, f2_m, pinhole_d_m)
%APPLY_SPATIAL_FILTER_4F 4f system: lens1 + pinhole + lens2 (using h_correct_FFT2/iFFT2).
%
% Uses physically scaled, centered FFT conventions:
%   F(fx,fy) = ? E(x,y) exp(-i2?(fx x + fy y)) dx dy
%   E(x,y)   = ? F(fx,fy) exp(+i2?(fx x + fy y)) dfx dfy
%
% The pinhole lives in the back focal plane of lens 1, where:
%   X_B = ? f1 fx,   Y_B = ? f1 fy
%
% Output is the filtered image at the back focal plane of lens 2, with:
%   magnification M = f2/f1
%   (optionally) inversion (the usual 4f parity flip)

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

    dx = coords_in.px_m;
    dy = coords_in.py_m;

    % ---------- Options (edit if you want different behavior) ----------
    invertImage = true;          % true -> typical 4f inversion; false -> no parity flip in coords
    applyAmpScale = true;        % true -> scales E by (f1/f2) to match ideal imaging amplitude scaling
    % Note: global phase factors (exp(ikf)/(i?f)) are not included; usually unnecessary for filtering.

    % ---------- Forward FT: input plane -> spatial-frequency domain ----------
    [Fk, x_vec, y_vec, fx_vec, fy_vec, dx_chk, dy_chk, dfx, dfy, Nx_chk, Ny_chk] = h_correct_FFT2(dx, dy, E_in);

    % sanity (optional)
    if Nx_chk ~= Nx || Ny_chk ~= Ny
        error('Unexpected size mismatch returned by h_correct_FFT2.');
    end
    if abs(dx_chk - dx) > 1e-15 || abs(dy_chk - dy) > 1e-15
        % Not fatal, but indicates inconsistency
    end

    [FX, FY] = meshgrid(fx_vec, fy_vec);  % [cycles/m]

    % ---------- Pinhole plane physical coordinates (lens 1 focal plane) ----------
    X_B = lambda_m * f1_m * FX;   % [m]
    Y_B = lambda_m * f1_m * FY;   % [m]
    dX_B = lambda_m * f1_m * dfx; % [m]
    dY_B = lambda_m * f1_m * dfy; % [m]

    coords_B = struct();
    coords_B.Nx   = Nx;
    coords_B.Ny   = Ny;
    coords_B.X    = X_B;
    coords_B.Y    = Y_B;
    coords_B.px_m = dX_B;
    coords_B.py_m = dY_B;
    coords_B.x_mm = X_B(1,:) * 1e3;
    coords_B.y_mm = Y_B(:,1) * 1e3;
    coords_B.fx   = fx_vec;
    coords_B.fy   = fy_vec;
    coords_B.dfx  = dfx;
    coords_B.dfy  = dfy;

    % "Field before pinhole" (spectrum). This is the correct, scaled FT.
    E_B_before = Fk;

    % ---------- Pinhole mask (in focal plane meters) ----------
    r_p = pinhole_d_m / 2;
    pinhole_mask = double( sqrt(X_B.^2 + Y_B.^2) <= r_p );

    % Apply filter in the Fourier plane
    E_B_after = E_B_before .* pinhole_mask;

    % ---------- Inverse FT: back to spatial domain (object-plane coordinate variable) ----------
    % This returns the filtered field on the same x,y sampling as the input grid.
    [E_tmp, x_tmp, y_tmp] = h_correct_iFFT2(dfx, dfy, E_B_after);

    % ---------- Map to image plane coordinates (magnification) ----------
    M = f2_m / f1_m;

    if invertImage
        x_C = -M * x_tmp;   % typical 4f inversion
        y_C = -M * y_tmp;
    else
        x_C =  M * x_tmp;
        y_C =  M * y_tmp;
    end

    [X_C, Y_C] = meshgrid(x_C, y_C);

    coords_C = struct();
    coords_C.Nx   = Nx;
    coords_C.Ny   = Ny;
    coords_C.M    = M;
    coords_C.X    = X_C;
    coords_C.Y    = Y_C;
    coords_C.px_m = abs(M) * dx;
    coords_C.py_m = abs(M) * dy;
    coords_C.x_mm = x_C * 1e3;
    coords_C.y_mm = y_C * 1e3;
    coords_C.inverted = invertImage;

    % Optional amplitude scaling for ideal imaging (energy consistent under magnification)
    if applyAmpScale
        E_C = (f1_m / f2_m) * E_tmp;
    else
        E_C = E_tmp;
    end

    % ---------- Pack outputs ----------
    pinhole_plane = struct();
    pinhole_plane.coords       = coords_B;
    pinhole_plane.E_before     = E_B_before;
    pinhole_plane.E_before_amp = abs(E_B_before);
    pinhole_plane.I_before     = abs(E_B_before).^2;
    pinhole_plane.E_after      = E_B_after;
    pinhole_plane.E_after_amp  = abs(E_B_after);
    pinhole_plane.I_after      = abs(E_B_after).^2;
    pinhole_plane.pinhole_mask = pinhole_mask;

    image_plane = struct();
    image_plane.coords = coords_C;
    image_plane.E      = E_C;
    image_plane.E_amp  = abs(E_C);
    image_plane.I      = abs(E_C).^2;

end
