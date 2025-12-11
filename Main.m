%% Parameters from your device
Nx = 1272; Ny = 1024;                % pixels
Wx_mm = 15.9; Wy_mm = 12.8;          % effective area (mm)
dx_mm = Wx_mm / Nx;                  % pixel pitch in mm  -> 0.0125 mm = 12.5 µm
dy_mm = Wy_mm / Ny;                  % pixel pitch in mm

levels = 255;                        % 8-bit max amplitude for the "on" region

%% Choose rectangle size (in mm). 
% Set these equal to Wx_mm, Wy_mm for a full-frame rectangle, or smaller if you want a sub-rectangle.
rect_w_mm = Wx_mm;                   % e.g., full width; change if needed
rect_h_mm = Wy_mm;                   % e.g., full height; change if needed

% Convert to pixels (rounded to nearest integer, enforce odd to center cleanly)
rect_w_px = max(1, round(rect_w_mm / dx_mm));
rect_h_px = max(1, round(rect_h_mm / dy_mm));
if mod(rect_w_px,2)==0, rect_w_px = rect_w_px-1; end
if mod(rect_h_px,2)==0, rect_h_px = rect_h_px-1; end

%% Build mask (centered rectangle)
mask = zeros(Ny, Nx, 'double');
cy = floor(Ny/2)+1; cx = floor(Nx/2)+1;
yr = (cy - (rect_h_px-1)/2) : (cy + (rect_h_px-1)/2);
xr = (cx - (rect_w_px-1)/2) : (cx + (rect_w_px-1)/2);
mask(yr, xr) = levels;               % rectangle at 0..255

%% Spatial axes (mm)
x_mm = ((1:Nx) - cx) * dx_mm;
y_mm = ((1:Ny) - cy) * dy_mm;

%% 2-D FFT (shifted) and frequency axes (cycles/mm)
F = fftshift(fft2(mask));
Fmag = abs(F);
Fmag_log = log10(1 + Fmag);          % for display

fx = ((-floor(Nx/2)):(ceil(Nx/2)-1)) / (Nx*dx_mm);  % cycles/mm
fy = ((-floor(Ny/2)):(ceil(Ny/2)-1)) / (Ny*dy_mm);  % cycles/mm

%% Plots
figure; imagesc(x_mm, y_mm, mask); axis image; colormap(gray); colorbar;
xlabel('x (mm)'); ylabel('y (mm)'); title('Rectangular mask (mm)');

figure; imagesc(fx, fy, Fmag_log); axis image; colormap(parula); colorbar;
xlabel('f_x (cycles/mm)'); ylabel('f_y (cycles/mm)'); 
title('FFT magnitude (log scale)');

%% Optional: remove DC to better see sidelobes (uncomment)
% F_noDC = F; F_noDC(fy==0, fx==0) = 0;
% figure; imagesc(fx, fy, log10(1+abs(F_noDC))); axis image; colormap(parula); colorbar;
% xlabel('f_x (cycles/mm)'); ylabel('f_y (cycles/mm)'); title('FFT (log) without DC');
