function h = plot_slm_outline(slm, ax, varargin)
%PLOT_SLM_OUTLINE Draw SLM active area rectangle in mm.
%
%   h = plot_slm_outline(slm)
%   h = plot_slm_outline(slm, ax)
%   h = plot_slm_outline(slm, ax, 'LineColor', 'w', 'LineWidth', 1.5, ...)
%
% Inputs:
%   slm - struct with at least:
%           slm.Nx, slm.Ny, slm.px_side_m, slm.py_side_m
%   ax  - (optional) axes handle, default gca
%   varargin - passed to rectangle() (e.g. 'EdgeColor', 'LineWidth')
%
% Output:
%   h   - handle to the rectangle object
%
% The rectangle is centered at (0,0) with width/height equal to the
% full SLM active area: Nx*px_side_m by Ny*py_side_m (in mm).

    if nargin < 2 || isempty(ax)
        ax = gca;
    end

    required = {'Nx','Ny','px_side_m','py_side_m'};
    for k = 1:numel(required)
        if ~isfield(slm, required{k})
            error('slm is missing required field "%s".', required{k});
        end
    end

    % SLM size in mm
    width_mm  = slm.Nx * slm.px_side_m * 1e3;
    height_mm = slm.Ny * slm.py_side_m * 1e3;

    x0 = -width_mm/2;
    y0 = -height_mm/2;

    % Default style if user did not override
    if isempty(varargin)
        varargin = {'EdgeColor', 'w', 'LineWidth', 1.0};
    end

    h = rectangle(ax, ...
        'Position', [x0, y0, width_mm, height_mm], ...
        'Curvature', [0 0], ...
        varargin{:});
end
