% Parameters (mm)
d = 1550e-6;           % separation between the two deltas [mm]
FWHM = 775e-6;        % Gaussian FWHM [mm]
sigma = FWHM / (2*sqrt(2*log(2)));   % convert FWHM -> sigma

% Grid (mm)
dx = 0.000001;                           % step size [mm]
x = (-0.002:dx:0.002).';                      % coordinate vector [mm]

% ----- Signal: two Dirac deltas at +/- d/2 -----
% Use discrete impulses with area 1: amplitude = 1/dx
s = zeros(size(x));
[~, i1] = min(abs(x - (-d/2)));
[~, i2] = min(abs(x - ( d/2)));
s([i1 i2]) = 1/dx;

% ----- Gaussian PSF (normalized to unit area) -----
g = (1/(sigma*sqrt(2*pi))) * exp(-(x.^2)/(2*sigma^2));

% ----- Numeric convolution (continuous approx) -----
% Multiply by dx to approximate integral (continuous) convolution
y_num = conv(s, g, 'same') * dx;

% ----- Analytic result: sum of two shifted Gaussians -----
y_ana = (1/(sigma*sqrt(2*pi))) * ( ...
          exp(-((x - d/2).^2)/(2*sigma^2)) + ...
          exp(-((x + d/2).^2)/(2*sigma^2)) );

% ----- Plot -----
figure; hold on; box on;
plot(x, y_num, 'LineWidth', 1.5);
plot(x, y_ana, '--', 'LineWidth', 1.2);
legend('Numeric conv', 'Analytic sum');
xlabel('x [mm]'); ylabel('Amplitude');
title('Convolution: two \delta''s (±0.15 mm) * Gaussian (FWHM 0.2 mm)');
grid on;
