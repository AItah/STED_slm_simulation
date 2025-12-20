function [] = donut_simulator()
%% cleanup
close all 
clear all
clc

%% load calibration mask for 770nm
correction_path = [pwd '\Correction_patterns\CAL_LSH0805598_770nm.bmp'];
calib_mask = load_grayscale_bmp(correction_path);
% % optional
% imagesc(calib_mask);
% colormap(gca,gray)
% colorbar

%% plot flags and settings
b_plot = false;
use_log_view = false;       % toggle log or linear view

%% ================= Steering user inputs =================
theta_x_deg_user = -0.0;   % [deg]
theta_y_deg_user =  0.00;   % [deg]

Delta_x_mm_user  =  -0.00;  % [mm]
Delta_y_mm_user  =  0.0;    % [mm]

% Vortex control
ell = 1;                   % topological charge (>=1)

% Lens focal length
f = 100e-3;                % [m]

%% ================= Mask options =================
use_forked       = true;     % true: forked (steered +1 order). false: centered spiral
use_digital_lens = false;    % true: add Fresnel lens term (no physical lens needed)
f_focus          = f;        % [m] focus distance if digital lens is used

% ================= 4f optics ================= 
P         = 1; % padding factor
f1        = 250e-3;
f2        = 250e-3;
M_4f      = f2 / f1;
pinhole_d = 100000e-6;

%% ================= Simulation options =================
do_fft_farfield  = true;
do_fresnel       = false;
z_prop           = 0.10;     % [m]

%% --- Phase-only encoding (superposition kinoform) ---
dc_bias = 0.0;     % amplitude of reference wave (controls zero-order strength)
gamma   = 1.0;     % weight of desired field (controls diffracted order strength)

%% === Load components ===

slm = load_slm_params('LCOS_SLM_X15213.json');
% % optional foe test - instead of changing the json
% slm_factor = 1;
% slm.Nx = slm.Nx * slm_factor;
% slm.Ny = slm.Ny * slm_factor;
% slm.px_side_m = slm.px_side_m * slm_factor; 
% slm.py_side_m = slm.py_side_m * slm_factor;

beam = load_gaussian_beam_params('GaussianBeam.json');

%% === input beam + Spatial filter + expander parameters ===


% Effective magnification for the *grid* (ensure we never shrink the grid)
M_grid = max(1, M_4f);     % >= 1 always

% input beam + its coordinates
factor = 3;
px_in = slm.px_side_m / M_grid;
py_in = slm.py_side_m / M_grid;

if min(px_in,py_in) > pinhole_d/30
    
    factor = max(round(px_in * 30 / pinhole_d), round(py_in * 30 / pinhole_d));
    
    px_in = px_in/factor;
    py_in = py_in/factor;
end

coords_4f_in = make_coordinates(round(slm.Nx*M_grid*factor), round(slm.Ny*M_grid*factor), px_in, py_in,true);
% edge_width_px = 5;
% beam_in = make_flat_soft_input_beam(coords_4f_in, slm.beam_diameter_mm, edge_width_px);
beam_in = make_gaussian_input_beam(coords_4f_in, beam);
beam_in.coords = coords_4f_in;
% 
% Add, for example, 5% amplitude noise and small phase noise (0.1 rad RMS)
if (false)
    beam_in = add_beam_noise(beam_in, 0.05, 0.05);
end

% optional FFT simulation limitted with memory:
[pinhole_plane, slm_plane] = apply_spatial_filter_4f(beam_in.E_amp, coords_4f_in, beam.lambda_m, f1, f2, pinhole_d);
% [~, ~, slm_plane] = apply_spatial_filter_4f_hybrid(beam, slm, f1, f2, pinhole_d, P);
slm_plane = crop_field_to_slm(slm_plane.E, slm_plane.coords, slm);

if (b_plot)
    beam_in_ = crop_field_to_slm_4plot(beam_in, beam_in.coords, slm);
    pinhole_plane_ = crop_field_to_slm_4plot(pinhole_plane, pinhole_plane.coords, slm);
    slm_plane_ = crop_field_to_slm_4plot(slm_plane, slm_plane.coords, slm);
    
    sub_figure = struct();
    sub_figure.x = 2;
    sub_figure.y = 3;
    sub_figure.i = 0;
    
%     sub_figure = plot_intensity_with_1e2_contour(coords_4f_in, beam_in.I, 'input  gaussian Beam',1,sub_figure);
%     show_1e2_radius(coords_4f_in,beam_in.I, gca)
    
    sub_figure = plot_intensity_with_1e2_contour(beam_in_.coords, beam_in_.I, 'input  gaussian Beam',1,sub_figure);
    show_1e2_radius(beam_in_.coords, beam_in_.I, gca)
    
    sub_figure = plot_intensity_with_1e2_contour(pinhole_plane_.coords, pinhole_plane_.I_before,['pinhole plane before mask'],1,sub_figure);
    show_1e2_radius(pinhole_plane_.coords, pinhole_plane_.I_before,gca)
    
    sub_figure = plot_intensity_with_1e2_contour(pinhole_plane_.coords, pinhole_plane_.pinhole_mask,['pinhole mask'],1,sub_figure);
    show_1e2_radius(pinhole_plane_.coords, pinhole_plane_.pinhole_mask,gca)
    
    sub_figure = plot_intensity_with_1e2_contour(pinhole_plane.coords, pinhole_plane.I_after,['pinhole plane including mask'],1,sub_figure);
    show_1e2_radius(pinhole_plane_.coords, pinhole_plane_.I_after,gca)

    sub_figure = plot_intensity_with_1e2_contour(slm_plane_.coords, slm_plane_.I,['image plane of beam expander (input beam for SLM)'],1,sub_figure);
    show_1e2_radius(slm_plane_.coords, slm_plane_.I,gca)
end
beam_in = slm_plane;


%% imput beam
beam_input_shape = beam_in.E;
coords = beam_in.coords;



%% ================= Choose steering mode =================
[steer_mode, use_forked_] = choose_steer_mode(theta_x_deg_user, theta_y_deg_user, Delta_x_mm_user, Delta_y_mm_user);
if ~(use_forked_ == 'none')
    use_forked = false;
end
        
%% ================= Resolve to fcp =================
switch steer_mode
    case "angle"
        theta_x_rad = theta_x_deg_user * pi/180;
        theta_y_rad = theta_y_deg_user * pi/180;

    case "shift"
        Delta_x_m = Delta_x_mm_user * 1e-3;
        Delta_y_m = Delta_y_mm_user * 1e-3;

        [theta_x_rad, theta_y_rad] = theta_from_shift(Delta_x_m, Delta_y_m, f);
end

% Single authoritative conversion: theta -> fcp
[fcp_x, fcp_y] = fcp_from_theta(theta_x_rad, theta_y_rad, slm, beam.lambda_m);

% Nyquist safety clamp
[fcp_x, fcp_y, clamped] = clamp_fcp_nyquist(fcp_x, fcp_y);

% Report actual predicted shifts
Delta_x_act_mm = 1e3 * f * beam.lambda_m * fcp_x / slm.px_side_m;
Delta_y_act_mm = 1e3 * f * beam.lambda_m * fcp_y / slm.py_side_m;
if clamped
    fprintf('Steer mode: %s | actual: dx=%.2f mm, dy=%.2f mm (Nyquist-limited)\n', ...
        steer_mode, Delta_x_act_mm, Delta_y_act_mm);
else
    fprintf('Steer mode: %s | actual: dx=%.2f mm, dy=%.2f mm\n', ...
        steer_mode, Delta_x_act_mm, Delta_y_act_mm);
end



%% ================= Save outputs =================
save_mask_png = true;

% Use a meaningful tag for filename:
% - if "shift" mode, use requested shift
% - if "angle" mode, use actual predicted shift
if steer_mode == "shift"
    shift_tag_mm = Delta_x_mm_user;
else
    shift_tag_mm = Delta_x_act_mm;
end

mask_filename = sprintf('slm_vortex_%s_ell%d_%dx%d_%0.3fmm.bmp', ...
    ternary(use_forked,'forked','spiral'), ell, slm.Nx, slm.Ny, shift_tag_mm);

save_sim_fft_png     = true;  fft_filename     = 'sim_farfield_fft.bmp';
save_sim_fresnel_png = true;  fresnel_filename = 'sim_fresnel_z.bmp';


%% ===== Build phase mask =====
vortex_mask = make_vortex_phase(coords, ell);   % ell * theta

shift_mask  = zeros(size(vortex_mask));
lens_mask   = zeros(size(vortex_mask));

if use_forked
    shift_mask = make_shift_phase(coords, fcp_x, fcp_y);
end

if use_digital_lens
    lens_mask = make_lens_phase(coords, beam.lambda_m, f_focus);
end

% make circular mask
maskR = 100*(slm.Ny*slm.py_side_m)/2; % sqrt(beam.w0x_1e2_m.^2+beam.w0y_1e2_m.^2)*3
mask = make_circular_mask(coords, beam, maskR);
if b_plot
    sub_figure = plot_intensity_with_1e2_contour(coords, mask, sprintf('phase mask'),1,sub_figure);
end
% --- Total desired phase ---
desired = (vortex_mask.* mask + shift_mask + lens_mask);

%% --- Phase-only encoding (superposition kinoform) ---
% We encode a reference (DC / zero-order) + the desired complex field into a phase-only pattern for the SLM.

% Complex superposition field (not directly displayed)
U = dc_bias + gamma * exp(1i * desired);

% Phase-only hologram to display on SLM
phi = angle(U);

% --- ADD MASK NOISE HERE ---
phase_sigma_mask_rad = 0.0; % [rad] e.g., 0.5 rad (about 30 degrees)
if phase_sigma_mask_rad > 0
    % Generate phase noise map
    % randn() generates standard normal random numbers
    noise_map = phase_sigma_mask_rad * randn(size(phi));
    % Apply the noise
    phi = phi + noise_map;
    
    fprintf('Phase noise added to mask: sigma = %.2f rad\n', phase_sigma_mask_rad);
end
% --- END MASK NOISE ---

% Wrap phase to [0, 2*pi)
phi_wrapped = mod(phi, 2*pi);

% figure('Name','SLM Phase (8-bit)'); 
i = 0; 
figure(3); 
set(gcf, 'Name', 'SLM mask creation');
i=i+1; subplot(2,3,i); 
what_is_done = 'Vortex mask, $\phi_{vortex}(x,y)$.';
equation_part = '$\phi_{vortex}(x,y) = \ell\, \theta(x,y) = atan2(y,x)$'; 
full_title_cell_array = {what_is_done, equation_part};
plot_vortex(coords, full_title_cell_array, vortex_mask)

i=i+1; subplot(2,3,i); 
what_is_done = 'shift mask, $\phi_{shift}(x,y)$.';
equation_part = '$\phi_{shift}(x,y) = 2\pi(f_{cp,x}n_x + f_{cp,y}n_y)$'; 
full_title_cell_array = {what_is_done, equation_part};
plot_vortex(coords, full_title_cell_array, shift_mask)

i=i+1; subplot(2,3,i); 
what_is_done = 'digital lens, $\phi_{lens}(x,y)$. (not in use)';
equation_part = '$\phi_{lens}(x,y) = -\frac{\pi}{\lambda f_{focus}}(x^2 + y^2)$'
full_title_cell_array = {what_is_done, equation_part};
plot_vortex(coords, full_title_cell_array, lens_mask)

i=i+1; subplot(2,3,i); 
what_is_done = 'combined mask, $\phi_{combined}(x,y)$.';
equation_part = '$\phi_{combined}(x,y) = \phi_{vortex}(x,y)+ \phi_{shift}(x,y) + \phi_{lens}(x,y)$'
full_title_cell_array = {what_is_done, equation_part};
plot_vortex(coords, full_title_cell_array, desired)

i=i+1; subplot(2,3,i);
dc_bias_str = sprintf('%.2f', dc_bias);
what_is_done = 'Phase angle of each complex number in $U(x,y)$';
equation_part_1 = 'where: $U(x,y) = d_c+e^{i\phi_{combined}(x,y)}$, $d_c = ';
equation_part_2 = '$';
full_title_cell_array = {what_is_done, [equation_part_1,dc_bias_str,equation_part_2]};
plot_vortex(coords, full_title_cell_array, phi)

i=i+1; subplot(2,3,i); 
what_is_done = 'Wrapped pahse, $\phi_{wrapped}(x,y)$';
equation_part = '$\phi_{wrapped}(x,y) = U(x,y) mod 2\pi$'; 
full_title_cell_array = {what_is_done, equation_part};
title(full_title_cell_array, 'Interpreter', 'latex', 'FontSize', 16);
plot_vortex(coords, full_title_cell_array, phi_wrapped)

% Field immediately after SLM (input amplitude ï¿½ SLM phase)
E = beam_input_shape .* exp(1i * phi_wrapped);


% --- Polarization state (assume linear x-polarized entering the SLM) ---
Ex = E;
Ey = zeros(size(E));

% --- Quarter-wave plate after SLM ---
alpha = 45*pi/180;      % fast-axis angle (45° converts linear -> circular)
delta = pi/2;           % retardance for ideal QWP at the design wavelength

[Ex, Ey] = apply_waveplate(Ex, Ey, delta, alpha);

% ---- end applying waveplate ----

% Map wrapped phase to 8-bit grayscale using SLM calibration
phase_gray = slm.c2pi2unit * (phi_wrapped / (2*pi));
primary_mask_uint8 = uint8( min(slm.c2pi2unit, round(phase_gray)));
combined_phase = uint16(primary_mask_uint8);%+uint16(calib_mask);
slm_img = uint8(mod(combined_phase, slm.c2pi2unit));


% Show & save mask
% figure('Name','SLM Phase (8-bit)'); 
figure(2)
h_ax1 = subplot(2,3,1);
imagesc(coords.x_mm, coords.y_mm, primary_mask_uint8);
set(gca,'YDir','normal');    % so y increases upward
axis image; 
colormap(h_ax1, gray); 
colorbar;
xlabel('x [mm]'); ylabel('y [mm]');
title(sprintf('SLM Phase without clibration correction (8-bit, wrapped, $0\\!\\ldots\\!2\\pi \\;\\rightarrow\\; 0\\!\\ldots\\!%d$ @ $\\lambda = %d\\,\\mathrm{nm}$)', ...
    slm.c2pi2unit, round(beam.lambda_m*1e9)), 'Interpreter','latex');
caxis([0 slm.c2pi2unit]);

h_ax2 = subplot(2,3,4);
imagesc(coords.x_mm, coords.y_mm, slm_img);
set(gca,'YDir','normal');    % so y increases upward
axis image; 
colormap(h_ax2, gray);
colorbar;
xlabel('x [mm]'); ylabel('y [mm]');
title(sprintf('SLM Phase with calibration correction (8-bit, wrapped, $0\\!\\ldots\\!2\\pi \\;\\rightarrow\\; 0\\!\\ldots\\!%d$ @ $\\lambda = %d\\,\\mathrm{nm}$)', ...
    slm.c2pi2unit, round(beam.lambda_m*1e9)), 'Interpreter','latex');
caxis([0 slm.c2pi2unit]);

% --- LINK AXES ---
% This links the X and Y limits of the two axes (h_ax1 and h_ax2).
% 'xy' means link both the X and Y axes.
linkaxes([h_ax1, h_ax2], 'xy');

% OPTIONAL: Set a common set of limits if they haven't been automatically
% synchronized yet. For image data on the same grid, this is usually unnecessary,
% but it's a good fail-safe.
% xlim(h_ax1, [min_x, max_x]); 
% ylim(h_ax1, [min_y, max_y]);


% return
if save_mask_png, imwrite(slm_img, mask_filename); end



%% Quick predictions for your steering
theta_x = fcp_x * beam.lambda_m / slm.px_side_m;      % radians (small-angle)
theta_y = fcp_y * beam.lambda_m / slm.py_side_m;
Delta_x = f * beam.lambda_m * fcp_x / slm.px_side_m;  % shift at Fourier plane [m]
Delta_y = f * beam.lambda_m * fcp_y / slm.py_side_m;

fprintf('\n--- Steering prediction ---\n');
fprintf('fcp_x = %.5f cyc/px ? theta_x ? %.4f deg, ?x ? %.3f mm @ f=%.0f mm\n', ...
    fcp_x, theta_x*180/pi, 1e3*Delta_x, 1e3*f);
fprintf('fcp_y = %.5f cyc/px ? theta_y ? %.4f deg, ?y ? %.3f mm @ f=%.0f mm\n\n', ...
    fcp_y, theta_y*180/pi, 1e3*Delta_y, 1e3*f);

%% Sim 1: far-field after lens (Fourier plane) via FFT
if do_fft_farfield

    % Field on SLM (keep this grid as-is)
    [Ny, Nx] = size(E);

    % ----- Choose oversampling factor in Fourier (donut) plane -----
    P_pad  = 6;                  % e.g. 4x finer sampling
    Ny_pad = P_pad * Ny;
    Nx_pad = P_pad * Nx;

    % ----- Zero-pad E to center of a larger array -----
    E_pad = zeros(Ny_pad, Nx_pad);
    
    cy = floor(Ny_pad/2) + 1;
    cx = floor(Nx_pad/2) + 1;

    ys = cy - floor(Ny/2);
    xs = cx - floor(Nx/2);

    E_pad(ys:ys+Ny-1, xs:xs+Nx-1) = E;
    
    % ----- Far-field (Fourier plane) pattern ~ FFT of padded field -----
    E_FT = fftshift(fft2(E_pad));
    I_FT = abs(E_FT).^2;
    I_FT = I_FT / max(I_FT(:));
    
    
    % --- waveplate ----
    Ex_pad = zeros(Ny_pad, Nx_pad);
    Ey_pad = zeros(Ny_pad, Nx_pad);

    Ex_pad(ys:ys+Ny-1, xs:xs+Nx-1) = Ex;
    Ey_pad(ys:ys+Ny-1, xs:xs+Nx-1) = Ey;

    Ex_FT = fftshift(fft2(Ex_pad));
    Ey_FT = fftshift(fft2(Ey_pad));

    I_FT = abs(Ex_FT).^2 + abs(Ey_FT).^2;
    I_FT = I_FT / max(I_FT(:));
    % --- end waveplate ---
    

    % ==== Physical scaling of Fourier-plane axes ====
    dxF_native = f * beam.lambda_m / (Nx * slm.px_side_m);   % [m/px] for original Nx


    dxF = dxF_native / P_pad;                                % [m/px] in padded array
    dyF = dxF;   % assuming square pixels / same scaling in x,y

    xF = (-Nx_pad/2 : Nx_pad/2-1) * dxF;                     % [m]
    yF = (-Ny_pad/2 : Ny_pad/2-1) * dyF;                     % [m]

    % Sanity: total span is unchanged: L_F = Nx_pad*dxF = Nx*dxF_native
    LFx = Nx_pad * dxF;
    LFy = Ny_pad * dyF;
    fprintf('Fourier-plane span (padded): LFx = %.2f mm, LFy = %.2f mm (f=%d mm)\n', ...
            1e3*LFx, 1e3*LFy, round(1e3*f));

    % ----- Plot with correct axes -----
    figure(2)
    subplot(2,3,[2:3 5:6]);

    if use_log_view
        Ilog = log10(I_FT + eps);
        imagesc(xF*1e3, yF*1e3, Ilog);
        v  = sort(Ilog(:));
        lo = v(max(1, round(0.02*numel(v))));
        hi = max(Ilog(:));
        caxis([lo hi]);
    else
        imagesc(xF*1e3, yF*1e3, I_FT);
    end

    set(gca,'YDir','normal'); axis image; colormap hot; colorbar;
    xlabel('x_F [mm]'); ylabel('y_F [mm]');
    title(sprintf(['Sim: Fourier-plane (after lens), oversampled by P=%d, ', ...
                   'log scale = %s, donut in +1 order if forked'], ...
                  P_pad, ternary(use_log_view,'true','false')), ...
          'Interpreter','latex');

    if save_sim_fft_png
        imwrite(uint8(255*mat2gray(I_FT)), fft_filename);
    end

    % Optional zoom around predicted shift
    Dx = Delta_x*1e3;
    Dy = Delta_y*1e3;
    xlim([Dx-2*beam.w_0x_m*1e3 Dx+2*beam.w_0x_m*1e3]);
    ylim([Dy-2*beam.w_0y_m*1e3 Dy+2*beam.w_0y_m*1e3]);
end

%% Sim 2: lensless propagation (Fresnel) with angular spectrum
if do_fresnel
    E0 = E;
    k = 2*pi/beam.lambda_m;
    fx = (-slm.Nx/2:slm.Nx/2-1)/(slm.Nx*slm.px_side_m);
    fy = (-slm.Ny/2:slm.Ny/2-1)/(slm.Ny*slm.py_side_m);
    [FX, FY] = meshgrid(fx, fy);
    H = exp(1i*k*z_prop*sqrt( max(0, 1 - (beam.lambda_m*FX).^2 - (beam.lambda_m*FY).^2) ));
    E_z = ifft2( fft2(E0) .* fftshift(H) );
    I_z = abs(E_z).^2; I_z = I_z / max(I_z(:));

    % ==== Added physical axes for propagation intensity ====
    figure('Name','Sim: Fresnel propagation');
    imagesc(coords.x_mm, coords.y_mm, I_z);
    set(gca,'YDir','normal');
    axis image; colormap hot; colorbar;
    xlabel('x [mm]'); ylabel('y [mm]');
    title(sprintf('Lensless propagation, z = %.0f cm', 100*z_prop))
    
    if save_sim_fresnel_png, imwrite(uint8(255*mat2gray(I_z)), fresnel_filename); end
end


R_sted_th = (beam.lambda_m * f/(pi*sqrt(2)*beam.w_0x_m))*2;

disp(sprintf("roughly STED diameter for our params is: %.3f um",R_sted_th*1e6));
end

%% Utility
function out = ternary(cond,a,b)
    if cond, out=a; else, out=b; end
end

function [] = plot_vortex(coords, title_, mask)
x_mm = coords.x_mm(:).';
y_mm = coords.y_mm(:);


imagesc(x_mm, y_mm, mask);
axis image;
set(gca, 'YDir', 'normal');
colorbar;
xlabel('x [mm]');
ylabel('y [mm]');
title(title_, 'Interpreter', 'latex', 'FontSize', 16);
colormap(gca, gray);
axis(gca, 'equal');
end
