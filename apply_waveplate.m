function [Ex_out, Ey_out] = apply_waveplate(Ex_in, Ey_in, delta, alpha)
% APPLY_WAVEPLATE Jones waveplate with retardance delta and fast-axis angle alpha.
% delta = pi/2 is a quarter-wave plate. alpha in radians.

    ca = cos(alpha); sa = sin(alpha);

    % Rotation matrix
    R = [ ca, -sa;
          sa,  ca ];

    % Waveplate in its own axes (fast axis = x')
    J0 = [1, 0;
          0, exp(1i*delta)];

    % Rotate into lab axes: J = R' * J0 * R
    J = R' * J0 * R;

    Ex_out = J(1,1).*Ex_in + J(1,2).*Ey_in;
    Ey_out = J(2,1).*Ex_in + J(2,2).*Ey_in;
end
