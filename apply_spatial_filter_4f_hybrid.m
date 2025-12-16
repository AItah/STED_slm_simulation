function [pinhole_plane, image_plane_sim, slm_plane] = ...
    apply_spatial_filter_4f_hybrid(beam, slm, f1_m, f2_m, pinhole_d_m, P)

    % --- Constants and Input Grid Sizes ---
    lambda = beam.lambda_m;
    M_val = f2_m/f1_m;
    if M_val<1
        M_val = 1;
    end
    
    % SLM / Input Grid Sizes (Input Plane A)
    Nx_slm = abs(M_val)*slm.Nx; Ny_slm = abs(M_val)*slm.Ny;
    px_slm = slm.px_side_m/abs(M_val); py_slm = slm.py_side_m/abs(M_val);
    
    Lx_slm = Nx_slm * px_slm; Ly_slm = Ny_slm * py_slm;
    dx_slm = Lx_slm / Nx_slm; dy_slm = Ly_slm / Ny_slm;

    % --- 1. GBT PROPAGATION (Input to Focal Plane B) ---
    Nx_sim = abs(M_val) * P * Nx_slm; 
    Ny_sim = abs(M_val) * P * Ny_slm; 
    
    % Focal Span uses the standard physical definition (related to f1)
    L_span_x_focal = (lambda * f1_m) / dx_slm; 
    L_span_y_focal = (lambda * f1_m) / dy_slm;

    % GBT calculates the field E_B on the oversampled grid (Nx_sim).
    [E_B, coords_B, q_focal] = generate_focal_field_gbt( ... 
        f1_m, beam, Nx_sim, Ny_sim, L_span_x_focal, L_span_y_focal);
    coords_B.dx = coords_B.px_m; 
    coords_B.dy = coords_B.py_m;
    
    if ~isfield(coords_B, 'x_mm')
        coords_B.x_mm = coords_B.X(1, :) * 1e3;
        coords_B.y_mm = coords_B.Y(:, 1)' * 1e3;
    end
    
    % --- 2. SPATIAL FILTERING at Focal Plane (B) ---
    X_B = coords_B.X; Y_B = coords_B.Y; r_p = pinhole_d_m / 2;
    pinhole_mask = double( sqrt(X_B.^2 + Y_B.^2) <= r_p );
    E_B_pinhole = E_B .* pinhole_mask;

    % pack pinhole_plane
    pinhole_plane.coords = coords_B;
    pinhole_plane.E_before = E_B; pinhole_plane.E_before_amp = abs(E_B); pinhole_plane.I_before = abs(E_B).^2;
    pinhole_plane.E_after = E_B_pinhole; pinhole_plane.E_after_amp = abs(E_B_pinhole); pinhole_plane.I_after = abs(E_B_pinhole).^2;
    pinhole_plane.pinhole_mask = pinhole_mask;
    
    % --- 3. Propagate to Image Plane (C): IFFT ---
    % 1. Get Physical Span from Focal Plane B coordinates
    L_span_x_focal_actual = Nx_sim * coords_B.dx;
    L_span_y_focal_actual = Ny_sim * coords_B.dy;

    % 2. Calculate the physically required Image Plane pitch (dx_image_sim)
    dx_image_sim = (lambda * f2_m) / L_span_x_focal_actual; 
    dy_image_sim = (lambda * f2_m) / L_span_y_focal_actual;

    % 3. Calculate the required frequency resolution (dfx, dfy) to yield this pitch
    dfx_required = 1 / (Nx_sim * dx_image_sim);
    dfy_required = 1 / (Ny_sim * dy_image_sim);

    % Call the helper function
    [E_C_pad, x_vec_sim, y_vec_sim, dx_check, dy_check, ~, ~] = ...
        h_correct_iFFT2(dfx_required, dfy_required, E_B_pinhole);

    % 4. Create the final coordinate structure for the padded array
    [X_C_sim, Y_C_sim] = meshgrid(x_vec_sim, y_vec_sim);
    
    coords_C_sim = struct('X', X_C_sim, 'Y', Y_C_sim, ...
                          'dx', dx_check, 'dy', dy_check, ... % Use checked values
                          'x_mm', x_vec_sim * 1e3, ... 
                          'y_mm', y_vec_sim * 1e3);

    image_plane_sim = struct('E', E_C_pad, 'I', abs(E_C_pad).^2, 'coords', coords_C_sim); 

%     % --- Plotting: Image Plane (Simulation Grid) ---
%     sub_figure = plot_intensity_with_1e2_contour(image_plane_sim.coords, image_plane_sim.I,sprintf('image_plane_sim (Padded)'),fignum,sub_figure);
%     axis equal
% %     temp_coords = coords_C_sim;
% %     temp_coords.dx = temp_coords.dx * P;
% %     temp_coords.dy = temp_coords.dy * P;
%     show_1e2_radius(image_plane_sim.coords, image_plane_sim.I,gca)
%     
%     xlim([-slm.Nx*slm.px_side_m*1e3/2 slm.Nx*slm.px_side_m*1e3/2])
%     ylim([-slm.Ny*slm.py_side_m*1e3/2 slm.Ny*slm.py_side_m*1e3/2])
    
    
    % --- 4. Crop to SLM grid size ---
    slm_plane = crop_field_to_slm(image_plane_sim.E, image_plane_sim.coords, slm)

    if false % for debug
        fignum = 555;
        % --- Plotting: Pinhole Plane ---
        sub_figure.x = 2; sub_figure.y = 3; sub_figure.i = 1;
        sub_figure = plot_intensity_with_1e2_contour(pinhole_plane.coords, pinhole_plane.I_before,sprintf('pinhole plane without apparture'),fignum,sub_figure);
        xlim([-r_p*1e3*2, r_p*1e3*2]); ylim([-r_p*1e3*2, r_p*1e3*2]);
        show_1e2_radius(pinhole_plane.coords, pinhole_plane.I_before,gca)
        sub_figure = plot_intensity_with_1e2_contour(pinhole_plane.coords, pinhole_plane.pinhole_mask,sprintf('pinhole mask'),fignum,sub_figure);
        xlim([-r_p*1e3*1.5, r_p*1e3*1.5]); ylim([-r_p*1e3*1.5, r_p*1e3*1.5]);
        sub_figure = plot_intensity_with_1e2_contour(pinhole_plane.coords, pinhole_plane.I_after,sprintf('pinhole plane with mask'),fignum,sub_figure);
        xlim([-r_p*1e3*2, r_p*1e3*2]); ylim([-r_p*1e3*2, r_p*1e3*2]);
        
        % --- Plotting: Image Plane (Simulation Grid) ---
        sub_figure = plot_intensity_with_1e2_contour(image_plane_sim.coords, image_plane_sim.I,sprintf('image_plane_sim (Zoomed)'),fignum,sub_figure);
        axis equal
        show_1e2_radius(image_plane_sim.coords, image_plane_sim.I,gca)
        xlim([-slm.Nx*slm.px_side_m*1e3/2 slm.Nx*slm.px_side_m*1e3/2])
        ylim([-slm.Ny*slm.py_side_m*1e3/2 slm.Ny*slm.py_side_m*1e3/2])                  
        
        sub_figure = plot_intensity_with_1e2_contour(slm_plane.coords, slm_plane.I,sprintf('image_plane_sim (cropped)'),fignum,sub_figure);
        axis equal
        show_1e2_radius(slm_plane.coords, slm_plane.I,gca)
    end
end

