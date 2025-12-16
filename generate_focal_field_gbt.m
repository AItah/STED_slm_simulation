function [E_focal, coords_focal, q_focal] = generate_focal_field_gbt(f, beam_params, Nx, Ny, L_span_x_m, L_span_y_m)
% GENERATE_FOCAL_FIELD_GBT Generates the electric field (E) in the focal plane 
% of a lens for a given Gaussian beam using the ABCD matrix formalism.
%
% This version is numerically robust and uses explicit physical parameters 
% (w and R) for field generation to ensure a central peak (no dark spot).

    % --- 1. Extract and Calculate Input Parameters ---
    lambda  = beam_params.lambda_m;
    k       = 2 * pi / lambda;
    Amp     = beam_params.Amp;

    % --- X-direction calculations ---
    w0x     = beam_params.w_0x_m;
    z0x     = beam_params.z_0x_m;
    M2x     = beam_params.M2x; 
    
    z_lens_in_x = -z0x; % Distance from waist to lens input plane
    zRx     = pi * w0x^2 / lambda / M2x; % Rayleigh Range

    % --- Robust Input q-parameter (qx_in) Calculation ---
    if abs(z_lens_in_x) < eps % Handle z=0 singularity (collimated incidence)
        Rx_in = Inf;
        wx_in = w0x;
    else
        % General case (z != 0): R(z) = z + zR^2/z
        Rx_in   = z_lens_in_x * (1 + (zRx / z_lens_in_x)^2);
        % w(z)^2 = w0^2 * (1 + (z/zR)^2)
        wx_in   = w0x * sqrt(1 + (z_lens_in_x / zRx)^2);
    end
    
    % Input q-parameter (1/q = 1/R - i*lambda/(pi*w^2))
    qx_in   = 1 / (1/Rx_in - 1i * lambda / (pi * wx_in^2));

    % --- Y-direction calculations ---
    w0y     = beam_params.w_0y_m;
    z0y     = beam_params.z_0y_m;
    M2y     = beam_params.M2y; 
    z_lens_in_y = -z0y;
    zRy     = pi * w0y^2 / lambda / M2y;

    if abs(z_lens_in_y) < eps % Handle z=0 singularity
        Ry_in = Inf;
        wy_in = w0y;
    else
        Ry_in   = z_lens_in_y * (1 + (zRy / z_lens_in_y)^2);
        wy_in   = w0y * sqrt(1 + (z_lens_in_y / zRy)^2);
    end
    qy_in   = 1 / (1/Ry_in - 1i * lambda / (pi * wy_in^2));


    % --- 2. Propagate using the ABCD Matrix (Lens at z=0, Focal Plane at z=f) ---
    % M_total = [0, f; -1/f, 1]
    A = 0; B = f; C = -1/f; D = 1;

    qx_focal = (A * qx_in + B) / (C * qx_in + D);
    qy_focal = (A * qy_in + B) / (C * qy_in + D);

    q_focal.qx = qx_focal;
    q_focal.qy = qy_focal;

    % --- 3. Generate the Focal Plane Grid ---
    dx = L_span_x_m / Nx;
    dy = L_span_y_m / Ny;

    x_vec_m = (-Nx/2 : Nx/2 - 1) * dx;
    y_vec_m = (-Ny/2 : Ny/2 - 1) * dy;
    [X, Y] = meshgrid(x_vec_m, y_vec_m);

    % --- 4. Generate the Field E_focal (RIGOROUSLY CORRECTED STEP) ---
    % We extract w_focal and R_focal and construct E explicitly, avoiding the central dark spot.

    % --- X-direction Field Generation ---
    inv_qx = 1/qx_focal;
    
    % 1. Physical Parameters at Focal Plane
    w_focal_x = sqrt(lambda / (pi * abs(imag(inv_qx))));
    
    if abs(real(inv_qx)) < eps 
        R_focal_x = Inf; % If real(1/q) is zero, R is infinite (flat phase)
    else
        R_focal_x = 1 / real(inv_qx);
    end

    % 2. Amplitude Scaling (A_focal = A_in * w_in / w_focal)
    % This ensures power conservation (relative to the input plane).
    A_focal_x = Amp * (wx_in / w_focal_x); 
    
    % 3. Field Construction: E(x) = A_focal * exp(-x^2/w^2) * exp(-i * k * x^2 / (2*R))
    E_decay_x = exp( -X.^2 / w_focal_x^2 );
    
    if isinf(R_focal_x)
        E_phase_x = 1; 
    else
        % Note the NEGATIVE sign for the phase term, standard in optics.
        E_phase_x = exp( -1i * k * X.^2 / (2 * R_focal_x) );
    end
    E_x_component = A_focal_x * E_decay_x .* E_phase_x;

    % --- Y-direction Field Generation ---
    inv_qy = 1/qy_focal;
    w_focal_y = sqrt(lambda / (pi * abs(imag(inv_qy))));

    if abs(real(inv_qy)) < eps
        R_focal_y = Inf;
    else
        R_focal_y = 1 / real(inv_qy);
    end

    A_focal_y_factor = (wy_in / w_focal_y); % Amplitude factor for Y
    
    E_decay_y = exp( -Y.^2 / w_focal_y^2 );
    
    if isinf(R_focal_y)
        E_phase_y = 1;
    else
        E_phase_y = exp( -1i * k * Y.^2 / (2 * R_focal_y) );
    end
    E_y_component_normalized = E_decay_y .* E_phase_y;

    % --- Combine E-Field ---
    % The total field is the product of the component fields.
    % We multiply the E_x_component (which carries the full initial Amp) by the normalized E_y component factor.
    E_focal = E_x_component .* E_y_component_normalized .* A_focal_y_factor;


    % --- 5. Package Coordinates ---
    coords_focal = struct();
    coords_focal.Nx    = Nx;
    coords_focal.Ny    = Ny;
    coords_focal.px_m  = dx;
    coords_focal.py_m  = dy;
    coords_focal.X     = X;
    coords_focal.Y     = Y;
    coords_focal.x_mm  = x_vec_m * 1e3;
    coords_focal.y_mm  = y_vec_m * 1e3;

end