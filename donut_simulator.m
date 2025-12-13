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
sub_figure = struct();
sub_figure.x = 2;
sub_figure.y = 3;
sub_figure.i = 0;
use_log_view = true;       % toggle log or linear view

%% ================= Steering user inputs =================
theta_x_deg_user = -0.0;   % [deg]
theta_y_deg_user =  0.0;  % [deg]

Delta_x_mm_user  =  -0.4;   % [mm]
Delta_y_mm_user  =  0.0;  % [mm]

% Vortex control
ell = 1;                   % topological charge (>=1)

% Lens focal length
f = 100e-3;                % [m]

%% ================= Mask options =================
use_forked       = true;     % true: forked (steered +1 order). false: centered spiral
use_digital_lens = false;    % true: add Fresnel lens term (no physical lens needed)
f_focus          = f;        % [m] focus distance if digital lens is used

%% ================= Simulation options =================
do_fft_farfield  = true;
do_fresnel       = false;
z_prop           = 0.10;     % [m]

%% --- Phase-only encoding (superposition kinoform) ---
dc_bias = 0.5;     % amplitude of reference wave (controls zero-order strength)
gamma   = 1.0;     % weight of desired field (controls diffracted order strength)

%% === Load components ===
slm = load_slm_params('LCOS_SLM_X15213.json');
beam = load_gaussian_beam_params('GaussianBeam.json');

% % optional
beam_L = beam;
beam_L.center_x_m=-slm.Nx*slm.px_side_m/4;
beam_R = beam;
beam_R.center_x_m= slm.Nx*slm.px_side_m/4;
% coords_ = make_coordinates(slm.Nx, slm.Ny, slm.px_side_m, slm.py_side_m, true);
% beam_in_ = make_gaussian_input_beam(coords_, beam);
% % optional: flat input
% edge_width_px = 20;
% beam_in_ = make_flat_soft_input_beam(coords_, slm.beam_diameter_mm, edge_width_px);
% plot_intensity_with_1e2_contour(coords_, beam_in_.I, sprintf('beam_in_'));

%% === input beam + Spatial filter + expander parameters ===
% 4f optics
f1        = 250e-3;
f2        = 500e-3;
M_4f      = f2 / f1;
pinhole_d = 25e-6;

% Effective magnification for the *grid* (ensure we never shrink the grid)
M_grid = max(1, M_4f);     % >= 1 always

% input beam + its coordinates
px_in = slm.px_side_m / M_grid;
py_in = slm.py_side_m / M_grid;
coords_4f_in = make_coordinates(round(slm.Nx*M_grid), round(slm.Ny*M_grid), px_in, py_in,true);
% edge_width_px = 5;
% beam_in = make_flat_soft_input_beam(coords_4f_in, slm.beam_diameter_mm, edge_width_px);
beam_in = make_gaussian_input_beam(coords_4f_in, beam);

% optional:
beam_in_L = make_gaussian_input_beam(coords_4f_in, beam_L);
beam_in_R = make_gaussian_input_beam(coords_4f_in, beam_R);
beam_in.I = beam_in_L.I + beam_in_R.I;

if (b_plot)
    sub_figure = plot_intensity_with_1e2_contour(coords_4f_in, beam_in.I, 'input two gaussians',1,sub_figure);
end
 
% Add, for example, 5% amplitude noise and small phase noise (0.1 rad RMS)
beam_in = add_beam_noise(beam_in, 0.05, 0.05);

% optional: plot
if (b_plot)
    sub_figure = plot_intensity_with_1e2_contour(coords_4f_in, beam_in.I, 'input Beam',1,sub_figure);
    show_1e2_radius(coords_4f_in,beam_in.I, gca)
end

[pinhole_plane, image_plane] = apply_spatial_filter_4f(beam_in.E_amp, coords_4f_in, beam.lambda_m, f1, f2, pinhole_d);

% ---- image_plane ----
% optional: plot
if b_plot
    sub_figure = plot_intensity_with_1e2_contour(image_plane.coords, image_plane.I, sprintf('image plane � filtered beam, M = %.2f', M_grid),1,sub_figure);
    [wx_mm, wy_mm] = show_1e2_radius(image_plane.coords, image_plane.I, gca);
    plot_slm_outline(slm, gca, 'EdgeColor','c','LineWidth',1.5);
end

[slm_plane] = crop_field_to_slm(image_plane.E, image_plane.coords, slm);

if b_plot
    sub_figure = plot_intensity_with_1e2_contour(slm_plane.coords, slm_plane.I, sprintf('SLM plane � filtered beam, M = %.2f', M_grid),1,sub_figure);
    [wx_mm, wy_mm] = show_1e2_radius(slm_plane.coords, slm_plane.I, gca);
    plot_slm_outline(slm, gca, 'EdgeColor','c','LineWidth',1.5);
end

%% imput beam
beam_input_shape = slm_plane.E;
coords = slm_plane.coords;

% beam_input_shape = beam_in_.I;
% coords = coords_;



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
mask = make_circular_mask(coords, beam, sqrt(beam.w0x_1e2_m.^2+beam.w0y_1e2_m.^2)*2);
if b_plot
    sub_figure = plot_intensity_with_1e2_contour(coords, mask, sprintf('phase mask'),1,sub_figure);
end
% --- Total desired phase ---
desired = (vortex_mask + shift_mask + lens_mask).* mask;

%% --- Phase-only encoding (superposition kinoform) ---
% We encode a reference (DC / zero-order) + the desired complex field into a phase-only pattern for the SLM.

% Complex superposition field (not directly displayed)
U = dc_bias + gamma * exp(1i * desired);

% Phase-only hologram to display on SLM
phi = angle(U);

% Wrap phase to [0, 2*pi)
phi_wrapped = mod(phi, 2*pi);

% figure('Name','SLM Phase (8-bit)'); 
figure(3); 
set(gcf, 'Name', 'SLM Phase (8-bit)');
subplot(2,3,1)
imagesc(vortex_mask)
colormap(gca, gray);
axis(gca, 'equal');
subplot(2,3,2)
imagesc(shift_mask)
colormap(gca, gray);
axis(gca, 'equal');
subplot(2,3,3)
imagesc(lens_mask)
colormap(gca, gray);
axis(gca, 'equal');
subplot(2,3,4)
imagesc(desired)
colormap(gca, gray);
axis(gca, 'equal');
subplot(2,3,5)
imagesc(phi)
colormap(gca, gray);
axis(gca, 'equal');
subplot(2,3,6)
imagesc(phi_wrapped)
colormap(gca, gray);
axis(gca, 'equal');

% Alternative (simplest): display the desired phase directly
% phi_wrapped = mod(desired, 2*pi);

% Field immediately after SLM (input amplitude � SLM phase)
E = beam_input_shape .* exp(1i * phi_wrapped);

% Map wrapped phase to 8-bit grayscale using SLM calibration
phase_gray = slm.c2pi2unit * (phi_wrapped / (2*pi));
primary_mask_uint8 = uint8( min(slm.c2pi2unit, round(phase_gray)));
combined_phase = uint16(primary_mask_uint8)+uint16(calib_mask);
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
%     % Complex field after SLM (assuming flat amplitude A=1)
%     E = exp(1i * phi_wrapped);

    % Far-field (Fourier plane) pattern ~ FFT of field
    E_FT = fftshift(fft2(E));
    I_FT = abs(E_FT).^2;
    I_FT = I_FT / max(I_FT(:));
    
    % ==== Added physical scaling of Fourier plane axes ====
    dxF = f * beam.lambda_m / (slm.Nx * slm.px_side_m);    % [m/px]
    dyF = f * beam.lambda_m / (slm.Ny * slm.py_side_m);
    
    % Build axis vectors in meters, then convert to mm for plotting
    xF = (-slm.Nx/2:slm.Nx/2-1) * dxF;
    yF = (-slm.Ny/2:slm.Ny/2-1) * dyF;
    
    % Sanity print
    LFx = slm.Nx*dxF; LFy = slm.Ny*dyF;      % total span [m]
    fprintf('Fourier-plane span: LFx = %.2f mm, LFy = %.2f mm (f=%d mm)\n', ...
            1e3*LFx, 1e3*LFy, round(1e3*f));
    
    % ----- Plot with correct axes -----
%     figure('Name','Sim: Fourier-plane (after lens)');
    figure(2)
    subplot(2,3,[2:3 5:6]);
    if use_log_view
        % safe log10: avoid -Inf by adding eps
        Ilog = log10(I_FT + eps*0);
        imagesc(xF*1e3, yF*1e3, Ilog);  % log display
        % toolbox-free contrast: clip lower 2%
        v = sort(Ilog(:));
        lo = v(max(1, round(0.02*numel(v))));
        hi = max(Ilog(:));
        caxis([lo hi]);
    else
        imagesc(xF*1e3, yF*1e3, I_FT);  % linear display
        % optional gentle contrast for linear view:
        % lo = min(I_FT(:)) + 0.02*(max(I_FT(:))-min(I_FT(:)));
        % caxis([lo max(I_FT(:))]);
    end

    set(gca,'YDir','normal'); axis image; colormap hot; colorbar;
    xlabel('x_F [mm]'); ylabel('y_F [mm]');
    title(sprintf('Sim: Fourier-plane (after lens), Simulated far-field (log scale = %s, Fourier plane, donut in +1 order if forked)', ternary(use_log_view, 'true', 'false')), ...
      'Interpreter','latex');

    if save_sim_fft_png, imwrite(uint8(255*mat2gray(I_FT)), fft_filename); end

    % Mark predicted +1 order at physical coordinates
    hold on;
    plot(1e3*Delta_x, 1e3*Delta_y, 'w+', 'MarkerSize', 14, 'LineWidth', 1.5);
    text(1e3*Delta_x+0.2, 1e3*Delta_y, '+1 order (predicted)', 'Color','w');
    hold off;
    
%     xlim([-1.1,-0.6]);
%     ylim([-0.2,0.2]);
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

end

%% Utility
function out = ternary(cond,a,b)
    if cond, out=a; else, out=b; end
end

