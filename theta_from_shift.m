function [theta_x_rad, theta_y_rad] = theta_from_shift(Delta_x_m, Delta_y_m, f_m)
%THETA_FROM_SHIFT Convert Fourier-plane shift to steering angles.
%
% Inputs:
%   Delta_x_m, Delta_y_m - desired shift at Fourier plane [m]
%   f                    - focal length [m]
%
% Outputs:
%   theta_x_rad, theta_y_rad - steering angles [rad]
%
% Uses exact geometry: theta = atan(Delta / f).

    if f_m <= 0
        error('f must be > 0');
    end

    theta_x_rad = atan(Delta_x_m / f_m);
    theta_y_rad = atan(Delta_y_m / f_m);
end
