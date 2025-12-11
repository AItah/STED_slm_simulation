%% Gaussian beam on SLM with finite-pixel aperture (no added phase)
% Fraunhofer pattern via FFT. No toolboxes required.
pack
clear; clc;

%% ---------- Parameters ----------
lambda = 775e-9;           % wavelength [m]
p      = 12.5e-6;          % pixel pitch [m]
fill   = 0.968;            % linear fill factor (96.8%)
Nx     = 1272;             % SLM pixels (x)
Ny     = 1024;             % SLM pixels (y)
OS     = 4;                % integer oversampling per pixel (>=2 recommended)

w0_I   = 10e-3;            % Gaussian 1/e^2 INTENSITY radius [m]
% amplitude field uses exp(-(x^2+y^2)/w0^2) with w0 = w0_I
w0 = w0_I;

% Optional lens focal length to map to focal plane coordinates. Leave [] to skip.
f_lens = [150e-3];               % e.g., f_lens = 200e-3;

%% ---------- High-resolution simulation grid ----------
dx = p/OS;                 % sample pitch [m]
dy = dx;

Nx_hr = Nx*OS;             % high-res samples
Ny_hr = Ny*OS;

Lx = Nx_hr*dx;             % physical size of simulated window [m]
Ly = Ny_hr*dy;

% build centered coordinates
x = (-floor(Nx_hr/2):ceil(Nx_hr/2)-1)*dx;
y = (-floor(Ny_hr/2):ceil(Ny_hr/2)-1)*dy;
[X, Y] = meshgrid(x, y);

%% ---------- SLM pixel-aperture mask ----------
% Each pixel is a rect of width fill*p in both axes; dead gap completes p.
% Create a periodic mask using modulo arithmetic, centered in each pixel.
% Local coordinates inside each pixel cell:
Xloc = mod(X + p/2, p) - p/2;       % now in [-p/2, p/2)
Yloc = mod(Y + p/2, p) - p/2;

half_ap = 0.5*fill*p;
aperture = (abs(Xloc) <= half_ap) & (abs(Yloc) <= half_ap);   % logical mask

%% ---------- Incident Gaussian field (zero added phase) ----------
E_in = exp(-(X.^2 + Y.^2) / (w0^2));    % amplitude field
E_slm = E_in .* aperture;               % field after SLM aperture

% ---- Per-pixel previews (Ny x Nx) for plotting only ----
Apix     = blockavg2(aperture, OS);
Islm_pix = blockavg2(abs(E_slm).^2, OS);


%% ---------- Far-field / Fourier-plane computation ----------
% Continuous FT scaling (Riemann-sum): multiply by sample area for proper units
U_ff = fftshift(fft2(ifftshift(E_slm))) * (dx*dy);
I_ff = abs(U_ff).^2;
I_ff = I_ff / max(I_ff(:));            % normalize peak to 1 for plotting

% Spatial frequency axes (cycles per meter)
fx = (-floor(Nx_hr/2):ceil(Nx_hr/2)-1) / (Nx_hr*dx);
fy = (-floor(Ny_hr/2):ceil(Ny_hr/2)-1) / (Ny_hr*dy);

% Map to diffraction angles; small-angle approx: sin(theta) ~ theta
theta_x = asin(min(1, lambda*fx));     % radians
theta_y = asin(min(1, lambda*fy));

% Optional focal-plane coordinates if a lens is used
if ~isempty(f_lens)
    Xf = lambda * f_lens * fx;         % meters in focal plane
    Yf = lambda * f_lens * fy;
end

%% ---------- Plots ----------
close all
figure('Color','w','Position',[100 100 1200 900], ...
             'Renderer','painters','RendererMode','manual', ...
             'GraphicsSmoothing','off');     % exact pixels, no smoothing
subplot(2,2,1);        
imagesc(x*1e3, y*1e3, Apix);
axis image; colormap(gray); colorbar;
xlabel('x [mm]'); ylabel('y [mm]');
ylim([min(y*1e3/2),max(y*1e3)/2])
xlim([min(x*1e3)/2,max(x*1e3)/2])
title(sprintf('SLM Aperture Mask (p=%.1f \\mum, fill=%.1f%%, OS=%d)', ...
    p*1e6, 100*fill, OS));

subplot(2,2,2);
imagesc(x*1e3, y*1e3, Islm_pix);
axis image; colorbar;
xlabel('x [mm]'); ylabel('y [mm]');
ylim([min(y*1e3),max(y*1e3)])
xlim([min(x*1e3),max(x*1e3)])
title('Field on SLM: Gaussian \times Aperture (amplitude)');

subplot(2,2,3);
Ilog = log10(I_ff + 1e-16);
imagesc(fx*1e-3, fy*1e-3, Ilog); axis image; colorbar; colormap(gray);
caxis([min(Ilog(:)), max(Ilog(:))]);  % ~60 dB window
title('Far-field Intensity (log10)');

subplot(2,2,4);
% show 1D cuts through center
cx = round(Ny_hr/2);
cy = round(Nx_hr/2);
plot(fx*1e-3, I_ff(cx,:),'LineWidth',1.2); hold on;
plot(fy*1e-3, I_ff(:,cy),'LineWidth',1.2);
grid on; legend('Horizontal cut','Vertical cut','Location','best');
xlabel('Spatial frequency [cycles/mm]');
ylabel('Normalized intensity');
title('Central cuts');

annotation('textbox', [0 0.95 1 0.05], ...
    'String', sprintf('Gaussian w_0 = %.1f mm  |  \\lambda = %d nm  |  Array %dx%d  |  OS=%d', ...
    w0*1e3, round(lambda*1e9), Nx, Ny, OS), ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
    'FontWeight', 'bold', 'FontSize', 11);

%% ---------- Optional: plot in focal plane if f_lens provided ----------
if ~isempty(f_lens)
    I_FT_log = log10(I_ff + 1e-16);
    figure('Color','w','Position',[100 100 900 700]);
    imagesc((fx*lambda*f_lens)*1e3, (fy*lambda*f_lens)*1e3, I_FT_log);
    axis image; colorbar;
    xlabel('x_f [mm]'); ylabel('y_f [mm]');
    title(sprintf('Focal-plane Intensity (f = %.0f mm)', f_lens*1e3));
    caxis([min(I_FT_log(:)), max(I_FT_log(:))]);  % ~60 dB window
end

%% ---------- Notes ----------
% - Increase OS for sharper pixel-edge modeling (trade-off: memory/time).
% - This models only the amplitude aperture of finite pixels (zero phase).
% - To add SLM phase patterns later, multiply E_slm by exp(1i*phi(x,y)).
% - The FFT plane is the Fraunhofer pattern (angular spectrum). If you set
%   f_lens, the same pattern is re-labeled in meters at the back focal plane.

function B = blockavg2(A, OS)
    % Average non-overlapping OS×OS blocks of A (size must be (Ny*OS)×(Nx*OS))
    [Ny_hr, Nx_hr] = size(A);
    assert(mod(Ny_hr,OS)==0 && mod(Nx_hr,OS)==0, 'Size not divisible by OS');
    Ny = Ny_hr/OS; Nx = Nx_hr/OS;
    A  = reshape(double(A), Ny, OS, Nx, OS);
    B  = squeeze( mean( mean(A,2), 4) );
end