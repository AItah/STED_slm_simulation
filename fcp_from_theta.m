function [fcp_x, fcp_y] = fcp_from_theta(theta_x_rad, theta_y_rad, slm, lambda_m)
%FCP_FROM_THETA Convert steering angles to carrier frequencies (cycles/pixel).
%
% Inputs:
%   theta_x_rad, theta_y_rad - steering angles [rad]
%   slm                      - struct with px_side_m, py_side_m
%   lambda_m                 - wavelength [m]
%
% Outputs:
%   fcp_x, fcp_y             - carrier frequencies [cycles/pixel]
%
% Small-angle model consistent with SLM phase ramp sampling.

    if lambda_m <= 0
        error('lambda_m must be > 0');
    end
    if ~isfield(slm, 'px_side_m') || ~isfield(slm, 'py_side_m')
        error('slm must contain px_side_m and py_side_m');
    end

    theta_x_rad = double(theta_x_rad);
    theta_y_rad = double(theta_y_rad);

    fcp_x = theta_x_rad * slm.px_side_m / lambda_m;
    fcp_y = theta_y_rad * slm.py_side_m / lambda_m;
end
