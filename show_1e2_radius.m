function [wx_mm, wy_mm] = show_1e2_radius(coords, I, ax)
%SHOW_1E2_RADIUS Find and overlay 1/e^2 radii on a beam intensity plot.
%
%   [wx_mm, wy_mm] = show_1e2_radius(coords, I)
%   [wx_mm, wy_mm] = show_1e2_radius(coords, I, ax)
%
% Inputs:
%   coords - struct with at least:
%              coords.x_mm : 1 x Nx   (x coordinates in mm)
%              coords.y_mm : Ny x 1   (y coordinates in mm)
%   I      - Ny x Nx intensity map (can be unnormalized)
%   ax     - (optional) axis handle to plot into (default: current axis)
%
% Outputs:
%   wx_mm  - 1/e^2 radius along x (mm), measured from beam center
%   wy_mm  - 1/e^2 radius along y (mm), measured from beam center
%
% Notes:
%   - Assumes beam is approximately centered near x=0, y=0.
%   - Uses cross-sections along the central row/column.
%   - Draws dashed white lines at ±wx_mm, ±wy_mm.

    if nargin < 3 || isempty(ax)
        ax = gca;
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

    % Normalize intensity
    I = double(I);
    I = I / max(I(:));

    % Find indices closest to x=0 and y=0
    [~, ix0] = min(abs(x_mm));
    [~, iy0] = min(abs(y_mm));

    % Central cross-sections
    Ix = I(iy0, :);   % horizontal cut (y ~ 0)
    Iy = I(:, ix0);   % vertical cut   (x ~ 0)

    target = exp(-2); % 1/e^2

    % ---- radius along x ----
    wx_mm = NaN;
    % right side
    idxR = find(Ix(ix0:end) <= target, 1, 'first');
    % left side
    idxL = find(Ix(1:ix0) <= target, 1, 'last');

    if ~isempty(idxR) && ~isempty(idxL)
        idxR = ix0 - 1 + idxR;
        idxL = idxL;

        % interpolate to target (right side)
        if idxR > 1
            x1 = x_mm(idxR-1); x2 = x_mm(idxR);
            y1 = Ix(idxR-1);   y2 = Ix(idxR);
            xR = x1 + (target - y1) * (x2 - x1) / (y2 - y1);
        else
            xR = x_mm(idxR);
        end

        % interpolate to target (left side)
        if idxL < Nx
            x1 = x_mm(idxL);   x2 = x_mm(idxL+1);
            y1 = Ix(idxL);     y2 = Ix(idxL+1);
            xL = x1 + (target - y1) * (x2 - x1) / (y2 - y1);
        else
            xL = x_mm(idxL);
        end

        wx_mm = mean(abs([xR, xL]));
    end

    % ---- radius along y ----
    wy_mm = NaN;
    % upper side (y increasing)
    idxU = find(Iy(iy0:end) <= target, 1, 'first');
    % lower side (y decreasing)
    idxD = find(Iy(1:iy0) <= target, 1, 'last');

    if ~isempty(idxU) && ~isempty(idxD)
        idxU = iy0 - 1 + idxU;
        idxD = idxD;

        % interpolate to target (upper)
        if idxU > 1
            y1 = y_mm(idxU-1); y2 = y_mm(idxU);
            i1 = Iy(idxU-1);   i2 = Iy(idxU);
            yU = y1 + (target - i1) * (y2 - y1) / (i2 - i1);
        else
            yU = y_mm(idxU);
        end

        % interpolate to target (lower)
        if idxD < Ny
            y1 = y_mm(idxD);   y2 = y_mm(idxD+1);
            i1 = Iy(idxD);     i2 = Iy(idxD+1);
            yD = y1 + (target - i1) * (y2 - y1) / (i2 - i1);
        else
            yD = y_mm(idxD);
        end

        wy_mm = mean(abs([yU, yD]));
    end

    % ---- overlay on current figure ----
    hold(ax, 'on');

    if ~isnan(wx_mm)
        yMin = min(y_mm); yMax = max(y_mm);
        plot(ax, [ wx_mm  wx_mm], [yMin yMax], 'w--', 'LineWidth', 1.0);
        plot(ax, [-wx_mm -wx_mm], [yMin yMax], 'w--', 'LineWidth', 1.0);
    end

    if ~isnan(wy_mm)
        xMin = min(x_mm); xMax = max(x_mm);
        plot(ax, [xMin xMax], [ wy_mm  wy_mm], 'w--', 'LineWidth', 1.0);
        plot(ax, [xMin xMax], [-wy_mm -wy_mm], 'w--', 'LineWidth', 1.0);
    end

    % optional text
    txt = sprintf('w_x = %.3f mm, w_y = %.3f mm (1/e^2)', wx_mm, wy_mm);
    disp(txt);
end
