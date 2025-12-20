function slm_plane = crop_field_to_slm(E_in, coords_in, slm)
%CROP_FIELD_TO_SLM Crop a plane to the SLM size (CROP ONLY: no resampling, no recomputation).
%
% Signature kept:
%   slm_plane = crop_field_to_slm(E_in, coords_in, slm)
%
% Now assume:
%   E_in is a struct that may contain any/all of:
%     E, I, E_amplitude, E_before, E_before_amp, I_before, E_after, ...
%     pinhole_mask, etc.
%   This function will crop *everything that exists* and matches the parent size,
%   using the same index range: [iy_start:iy_end, ix_start:ix_end]
%
% IMPORTANT:
%   - Does NOT rebuild coordinates (no make_coordinates)
%   - Does NOT recompute amplitudes/intensities (only crops what already exists)
%
% Optional reuse of crop indices:
%   If slm.crop_idx exists with fields ix_start, ix_end, iy_start, iy_end,
%   the function will reuse it (so multiple planes crop identically).

    % ---- Required checks ----
    if ~isfield(slm, 'Nx') || ~isfield(slm, 'Ny')
        error('slm must contain Nx and Ny.');
    end
    if ~isfield(coords_in, 'x_mm') || ~isfield(coords_in, 'y_mm')
        error('coords_in must contain x_mm and y_mm.');
    end
    if ~isstruct(E_in)
        error('E_in must be a struct (containing E/I/E_amplitude/etc).');
    end

    % Parent axes
    x_mm = coords_in.x_mm(:).';   % 1 x Nx
    y_mm = coords_in.y_mm(:);     % Ny x 1
    Nx = numel(x_mm);
    Ny = numel(y_mm);

    Nx_slm = slm.Nx;
    Ny_slm = slm.Ny;

    if Nx_slm > Nx || Ny_slm > Ny
        error('SLM size (%d x %d) is larger than input plane (%d x %d).', ...
              Nx_slm, Ny_slm, Nx, Ny);
    end

    % ---- Determine crop indices (reuse if provided) ----
    if isfield(slm,'crop_idx') && ~isempty(slm.crop_idx)
        idx = slm.crop_idx;
        ix_start = idx.ix_start; ix_end = idx.ix_end;
        iy_start = idx.iy_start; iy_end = idx.iy_end;
    else
        % Center around x=0,y=0
        [~, ix_center] = min(abs(x_mm));
        [~, iy_center] = min(abs(y_mm));

        half_x = floor(Nx_slm/2);
        half_y = floor(Ny_slm/2);

        ix_start = ix_center - half_x;
        ix_end   = ix_start + Nx_slm - 1;

        iy_start = iy_center - half_y;
        iy_end   = iy_start + Ny_slm - 1;

        % Clamp
        if ix_start < 1, ix_start = 1; ix_end = Nx_slm; end
        if iy_start < 1, iy_start = 1; iy_end = Ny_slm; end
        if ix_end > Nx, ix_end = Nx; ix_start = Nx - Nx_slm + 1; end
        if iy_end > Ny, iy_end = Ny; iy_start = Ny - Ny_slm + 1; end
    end

    % Ranges (your requested form)
    ix_rng = ix_start:ix_end;
    iy_rng = iy_start:iy_end;

    % ---- Crop helper ----
    crop2 = @(A) A(iy_rng, ix_rng);

    % ---- Crop ALL fields that exist ----
    slm_plane = E_in; % start as copy, overwrite cropped fields

    fns = fieldnames(E_in);
    for k = 1:numel(fns)
        name = fns{k};
        val  = E_in.(name);

        if isnumeric(val) || islogical(val)
            nd = ndims(val);

            % Crop 2D arrays that match parent size
            if ismatrix(val) && isequal(size(val), [Ny, Nx])
                slm_plane.(name) = crop2(val);

            % Crop arrays with first two dims Ny x Nx (keep trailing dims)
            elseif nd >= 3 && size(val,1)==Ny && size(val,2)==Nx
                slm_plane.(name) = val(iy_rng, ix_rng, :);

            % Crop vectors that match Nx or Ny (useful for fx/fy, x/y stored at top-level)
            elseif isvector(val)
                if numel(val) == Nx
                    if isrow(val), slm_plane.(name) = val(ix_rng);
                    else,         slm_plane.(name) = val(ix_rng).';
                    end
                elseif numel(val) == Ny
                    if iscolumn(val), slm_plane.(name) = val(iy_rng);
                    else,            slm_plane.(name) = val(iy_rng).';
                    end
                end
            end
        end
    end

    % ---- Crop coords ONLY by slicing (no rebuilding grid) ----
    coords_out = coords_in;

    % Slice 1D axes
    coords_out.x_mm = x_mm(ix_rng);
    coords_out.y_mm = y_mm(iy_rng);

    % Slice 2D grids if present
    if isfield(coords_out,'X') && ~isempty(coords_out.X) && isequal(size(coords_out.X), [Ny, Nx])
        coords_out.X = coords_out.X(iy_rng, ix_rng);
    end
    if isfield(coords_out,'Y') && ~isempty(coords_out.Y) && isequal(size(coords_out.Y), [Ny, Nx])
        coords_out.Y = coords_out.Y(iy_rng, ix_rng);
    end

    % Update sizes if present
    if isfield(coords_out,'Nx'), coords_out.Nx = numel(ix_rng); end
    if isfield(coords_out,'Ny'), coords_out.Ny = numel(iy_rng); end

    slm_plane.coords = coords_out;

    % ---- Store crop metadata ----
    slm_plane.crop_idx = struct('ix_start',ix_start,'ix_end',ix_end,'iy_start',iy_start,'iy_end',iy_end);
    slm_plane.center_in_parent_mm = [ x_mm(round((ix_start+ix_end)/2)), y_mm(round((iy_start+iy_end)/2)) ];
    slm_plane.origin_in_parent_mm = [ x_mm(ix_start),                 y_mm(iy_start)                 ];
end
