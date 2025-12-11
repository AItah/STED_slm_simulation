function shift_mask = make_shift_phase(coords, fcp_x, fcp_y)
%MAKE_SHIFT_PHASE Linear grating phase for beam steering.
%
% Inputs:
%   coords - must include xi, yi (pixel index grids)
%   fcp_x, fcp_y - cycles/pixel
%
% Output:
%   shift_mask - phase map [rad]

    if ~isfield(coords, 'xi') || ~isfield(coords, 'yi')
        error('coords must contain xi and yi for shift phase.');
    end

    shift_mask = 2*pi * (fcp_x * coords.xi + fcp_y * coords.yi);
end
