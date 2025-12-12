function beam_noisy = add_beam_noise(beam_in, rel_amp_sigma, phase_sigma_rad)
%ADD_BEAM_NOISE Add amplitude and (optionally) phase noise to a beam struct.
%
%   beam_noisy = add_beam_noise(beam_in, rel_amp_sigma, phase_sigma_rad)
%
% Inputs:
%   beam_in        - struct from make_gaussian_input_beam (must contain E_amp or E)
%   rel_amp_sigma  - relative std dev of amplitude noise (e.g. 0.05 = 5% RMS)
%   phase_sigma_rad - std dev of phase noise [rad] (e.g. 0 = no phase noise)
%
% Outputs:
%   beam_noisy     - same struct fields as beam_in, but with:
%                       .E      (complex field, if present)
%                       .E_amp  (amplitude, if present)
%                       .I      (updated intensity = |E|^2)
%
% Notes:
%   - Amplitude noise is multiplicative: A_noisy = A .* (1 + n),
%     where n ~ N(0, rel_amp_sigma^2)
%   - Phase noise is additive: phi_noisy = phi + delta_phi,
%     where delta_phi ~ N(0, phase_sigma_rad^2)

    if nargin < 2 || isempty(rel_amp_sigma)
        rel_amp_sigma = 0.05;  % default: 5% amplitude noise
    end
    if nargin < 3 || isempty(phase_sigma_rad)
        phase_sigma_rad = 0.0; % default: no phase noise
    end

    beam_noisy = beam_in;  % start by copying

    % ---- Get the field E from the struct ----
    field_name = '';
    if isfield(beam_in, 'E')
        E = beam_in.E;
        field_name = 'E';
    elseif isfield(beam_in, 'E_amp')
        E = beam_in.E_amp;   % treat amplitude as field (real)
        field_name = 'E_amp';
    else
        error('beam_in must contain either .E or .E_amp.');
    end

    % ---- Amplitude / phase decomposition ----
    A   = abs(E);
    phi = angle(E);

    % ---- Amplitude noise (multiplicative Gaussian) ----
    if rel_amp_sigma > 0
        noise = randn(size(A));
        max_abs_val = max(abs(noise(:)));
        if max_abs_val > 0
            noiseA = rel_amp_sigma * (noise / max_abs_val);
        else
            noiseA = zeros(size(A)); % Failsafe
        end

        A_noisy = A .* (1 + noiseA);
        % Avoid negative amplitudes:
        A_noisy(A_noisy < 0) = 0;
    else
        A_noisy = A;
    end

    % ---- Phase noise (additive Gaussian) ----
    if phase_sigma_rad > 0
        noise = randn(size(A));
        max_abs_val = max(abs(noise(:)));
        if max_abs_val > 0
            noisePhi = phase_sigma_rad * (noise / max_abs_val);
        else
            noisePhi = zeros(size(A)); % Failsafe
        end
        phi_noisy = phi + noisePhi;
    else
        phi_noisy = phi;
    end

    % ---- Reconstruct noisy complex field ----
    E_noisy = A_noisy .* exp(1i * phi_noisy);

    % ---- Write back into struct ----
    switch field_name
        case 'E'
            beam_noisy.E     = E_noisy;
            % if there is a separate amplitude field, update it as well:
            if isfield(beam_noisy, 'E_amp')
                beam_noisy.E_amp = abs(E_noisy);
            end
        case 'E_amp'
            % keep convention: E_amp is amplitude, but we now have phase too
            beam_noisy.E     = E_noisy;
            beam_noisy.E_amp = A_noisy;
    end

    % Intensity is always |E|^2
    beam_noisy.I = abs(E_noisy).^2;
end
