function slm_plane = crop_field_to_slm(E_in, coords_in, slm)
%CROP_FIELD_TO_SLM Crop a field to the SLM size and reset coords to SLM grid.
%
%   slm_plane = crop_field_to_slm(E_in, coords_in, slm)
%
% Inputs:
%   E_in      - complex field (Ny x Nx) at some plane
%   coords_in - struct with at least x_mm, y_mm (axes of E_in)
%   slm       - struct with SLM parameters:
%                 slm.Nx, slm.Ny, slm.px_side_m, slm.py_side_m
%
% Output struct slm_plane:
%   slm_plane.E           - cropped complex field, [slm.Ny x slm.Nx]
%   slm_plane.E_amplitude - |E|
%   slm_plane.I           - |E|^2
%   slm_plane.coords      - SLM coordinate grid (like make_coordinates(...,true))
%   slm_plane.center_in_parent_mm  - [x0, y0] of crop center in parent plane
%   slm_plane.origin_in_parent_mm  - [x_min, y_min] of crop corner in parent plane

    % ---- Required fields checks ----
    if ~isfield(slm, 'Nx') || ~isfield(slm, 'Ny') || ...
       ~isfield(slm, 'px_side_m') || ~isfield(slm, 'py_side_m')
        error('slm must contain Nx, Ny, px_side_m, py_side_m.');
    end

    [Ny, Nx] = size(E_in);
    Nx_slm = slm.Nx;
    Ny_slm = slm.Ny;

    if Nx_slm > Nx || Ny_slm > Ny
        error('SLM size (%d x %d) is larger than input field size (%d x %d).', ...
              Nx_slm, Ny_slm, Nx, Ny);
    end

    if ~isfield(coords_in, 'x_mm') || ~isfield(coords_in, 'y_mm')
        error('coords_in must contain x_mm and y_mm.');
    end

    % 1D axes (ensure orientation)
    x_mm = coords_in.x_mm(:).';
    y_mm = coords_in.y_mm(:);

    if numel(x_mm) ~= Nx || numel(y_mm) ~= Ny
        error('coords_in.x_mm/y_mm inconsistent with E_in size.');
    end

    % ---- Find crop center: point closest to x=0, y=0 in parent plane ----
    [~, ix_center] = min(abs(x_mm));
    [~, iy_center] = min(abs(y_mm));

    half_x = floor(Nx_slm/2);
    half_y = floor(Ny_slm/2);

    ix_start = ix_center - half_x;
    ix_end   = ix_start + Nx_slm - 1;

    iy_start = iy_center - half_y;
    iy_end   = iy_start + Ny_slm - 1;

    % Safety clamp
    if ix_start < 1
        ix_start = 1;
        ix_end   = Nx_slm;
    end
    if iy_start < 1
        iy_start = 1;
        iy_end   = Ny_slm;
    end
    if ix_end > Nx
        ix_end   = Nx;
        ix_start = Nx - Nx_slm + 1;
    end
    if iy_end > Ny
        iy_end   = Ny;
        iy_start = Ny - Ny_slm + 1;
    end

    % ---- Crop the field ----
    E_crop = E_in(iy_start:iy_end, ix_start:ix_end);

    slm_plane = struct();
    slm_plane.E           = E_crop;
    slm_plane.E_amplitude = abs(E_crop);
    slm_plane.I           = slm_plane.E_amplitude.^2;

    % ---- SLM coordinates: canonical grid ----
    % This will be identical to:
    %   make_coordinates(slm.Nx, slm.Ny, slm.px_side_m, slm.py_side_m, true)
    slm_plane.coords = make_coordinates(slm.Nx, slm.Ny, slm.px_side_m, slm.py_side_m, true);

    % ---- (Optional) store where this patch sits in the parent plane ----
    slm_plane.center_in_parent_mm = [ x_mm(ix_center), y_mm(iy_center) ];
    slm_plane.origin_in_parent_mm = [ x_mm(ix_start),  y_mm(iy_start)  ];
end
