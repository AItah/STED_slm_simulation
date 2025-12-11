function plot_intensity_with_1e2_contour(coords, I, fig_title)
%PLOT_INTENSITY_WITH_1E2_CONTOUR Show intensity and 1/e^2 perimeter.
%
%   plot_intensity_with_1e2_contour(coords, I, fig_title)
%
% Inputs:
%   coords    - struct with:
%                 coords.x_mm : 1 x Nx  (x coordinates in mm)
%                 coords.y_mm : Ny x 1  (y coordinates in mm)
%   I         - Ny x Nx intensity map (can be unnormalized)
%   fig_title - (optional) figure title (string)
%
% Behavior:
%   - Normalizes I so max(I) = 1.
%   - Displays I with imagesc (x,y in mm).
%   - Overlays a white contour line where I = 1/e^2.
%
% Compatible with MATLAB R2017b.

    if nargin < 3
        fig_title = '';
    end

    if ~isfield(coords, 'x_mm') || ~isfield(coords, 'y_mm')
        error('coords must contain x_mm and y_mm.');
    end

    x_mm = coords.x_mm(:).';   % row
    y_mm = coords.y_mm(:);     % column

    [Ny, Nx] = size(I);
    if length(x_mm) ~= Nx || length(y_mm) ~= Ny
        error('Size mismatch: I is %dx%d, but x_mm,y_mm are [%d,%d].', ...
              Ny, Nx, length(y_mm), length(x_mm));
    end

    I = double(I);
    Imax = max(I(:));
    if Imax <= 0
        warning('Intensity is non-positive everywhere; nothing to plot.');
        return;
    end

    Inorm  = I / Imax;
    target = exp(-2);   % 1/e^2 level

    % Grid for contour
    [Xmm, Ymm] = meshgrid(x_mm, y_mm);

    % --- Plot ---
    figure;
    imagesc(x_mm, y_mm, Inorm);
    axis image;
    set(gca, 'YDir', 'normal');
    colorbar;
    xlabel('x [mm]');
    ylabel('y [mm]');
    if ~isempty(fig_title)
        title(fig_title);
    end
    caxis([0 1]);

    hold on;
    
    % Contour at I = 1/e^2
    contour(Xmm, Ymm, Inorm, [target target], 'w', 'LineWidth', 1.5);
    hold off;
end
