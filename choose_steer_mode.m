function [steer_mode, use_forked] = choose_steer_mode(theta_x_deg, theta_y_deg, Delta_x_mm, Delta_y_mm)
%CHOOSE_STEER_MODE Decide how steering is specified by the user.
% Angle wins if both are given.
    use_forked = 'none';
    if (theta_x_deg ~= 0) || (theta_y_deg ~= 0)
        steer_mode = "angle";
    elseif (Delta_x_mm ~= 0) || (Delta_y_mm ~= 0)
        steer_mode = "shift";
    else
        steer_mode = "angle";
        theta_x_deg = 1e-9;
        use_forked = false;
%         error('No steering specified: set theta_x/y or Delta_x/y.');
    end
end
