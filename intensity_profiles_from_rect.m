function intensity_profiles_from_rect
% INTENSITY_PROFILES_FROM_RECT
% 1. Load an image (bmp, jpg, png, tif, ...)
% 2. User draws a rectangle on the image
% 3. User selects a point inside the rectangle
% 4. Compute intensity profiles along X and Y through that point,
%    limited to the rectangle; axis origin = selected point.
% 5. Show a subplot with the selected rectangle area.

    %% --- Load image ---
    [fname, fpath] = uigetfile( ...
        {'*.bmp;*.jpg;*.jpeg;*.png;*.tif;*.tiff', 'Image files'}, ...
        'Select an image');
    if isequal(fname, 0)
        disp('No file selected. Exiting.');
        return;
    end

    I = imread(fullfile(fpath, fname));

    % Convert to grayscale if needed
    if ndims(I) == 3
        Igray = rgb2gray(I);
    else
        Igray = I;
    end

    %% --- Show image and let user draw rectangle ---
    hFig = figure('Name', 'Select rectangle and point');
    imshow(Igray, []);
    title('Draw a rectangle (double-click inside to confirm)');
    hold on;

    % Draw rectangle (interactive)
    hRect = imrect;                     % For newer MATLAB, drawrectangle also works
    rectPos = wait(hRect);              % [xmin, ymin, width, height]

    % Convert rectangle to integer pixel indices, clamped to image size
    [imgH, imgW] = size(Igray);

    xmin = max(1, floor(rectPos(1)));
    ymin = max(1, floor(rectPos(2)));
    xmax = min(imgW, ceil(rectPos(1) + rectPos(3) - 1));
    ymax = min(imgH, ceil(rectPos(2) + rectPos(4) - 1));

    % Draw the final (snapped) rectangle in red
    rectangle('Position', [xmin, ymin, xmax - xmin + 1, ymax - ymin + 1], ...
              'EdgeColor', 'r', 'LineWidth', 1.5);

    %% --- Let user select a point inside the rectangle ---
    title('Click a point inside the RED rectangle');
    [x0, y0] = ginput(1);   % x = column, y = row
    x0 = round(x0);
    y0 = round(y0);

    % Clamp the point to lie inside the rectangle
    x0 = min(max(x0, xmin), xmax);
    y0 = min(max(y0, ymin), ymax);

    % Show selected point
    plot(x0, y0, 'g+', 'MarkerSize', 10, 'LineWidth', 2);
    title('Rectangle and selected point');

    %% --- Compute intensity profiles within rectangle ---

    % X profile: row = y0, columns from xmin to xmax
    xIdx = xmin:xmax;                   % column indices within rectangle
    Ix = double(Igray(y0, xIdx));       % intensity values along X
    xRel = xIdx - x0;                   % relative X, 0 at selected point

    % Y profile: column = x0, rows from ymin to ymax
    yIdx = ymin:ymax;                   % row indices within rectangle
    Iy = double(Igray(yIdx, x0));       % intensity values along Y
    yRel = yIdx - y0;                   % relative Y, 0 at selected point

    %% --- Extract rectangle area for display ---
    rectImg = Igray(ymin:ymax, xmin:xmax);

    % Coordinates of selected point in the cropped (rect) image
    x0_rect = x0 - xmin + 1;
    y0_rect = y0 - ymin + 1;

    %% --- Plot rectangle + profiles in one figure ---
    figure('Name', 'Rectangle and intensity profiles');

    % 1) Selected rectangle area
    subplot(3,1,1);
    imshow(rectImg, []);
    hold on;
    plot(x0_rect, y0_rect, 'g+', 'MarkerSize', 1, 'LineWidth', 2);
    title('Selected rectangle area (zoomed)');

    % 2) Intensity along X
    subplot(3,1,2);
    plot(xRel, Ix, '-');
    grid on;
    xlabel('x (pixels, 0 = selected point)');
    ylabel('Intensity');
    title('Intensity along X within rectangle');

    % 3) Intensity along Y
    subplot(3,1,3);
    plot(yRel, Iy, '-');
    grid on;
    xlabel('y (pixels, 0 = selected point)');
    ylabel('Intensity');
    title('Intensity along Y within rectangle');

end
