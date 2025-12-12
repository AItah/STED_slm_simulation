function mask = make_circular_aperture(coords, beam, radius_m)
%MAKE_CIRCULAR_APERTURE Generates a logical mask with ones inside a circle.
%
% Inputs:
%   coords       - Struct containing 2D grid coordinates (coords.X, coords.Y).
%   beam         - Struct containing center_x_m and center_y_m fields.
%   radius_m     - The radius of the circle [m].
%
% Required beam fields:
%   beam.center_x_m 
%   beam.center_y_m
%
% Output:
%   mask         - A logical array (true/1 inside, false/0 outside).

    % --- Input Validation ---
    if ~isfield(coords, 'X') || ~isfield(coords, 'Y')
        error('coords must contain X and Y fields.');
    end
    
    required = {'center_x_m','center_y_m'};
    for k = 1:numel(required)
        if ~isfield(beam, required{k})
            error('Missing field "%s" in beam struct.', required{k});
        end
    end

    if radius_m <= 0
        error('Radius must be a positive value.');
    end

    % --- Extract Center Coordinates ---
    cx = double(beam.center_x_m);
    cy = double(beam.center_y_m);

    % --- Centered Coordinates ---
    % Xc and Yc are the coordinates relative to the beam center.
    Xc = coords.X - cx; 
    Yc = coords.Y - cy; 

    % --- Calculate Radial Distance ---
    % R_dist is the distance from the center (cx, cy) at every point.
    R_dist = sqrt(Xc.^2 + Yc.^2); 

    % --- Create the Logical Mask ---
    % The mask is TRUE (1) wherever the radial distance is less than or equal to the radius.
    mask = (R_dist <= radius_m);
    
end