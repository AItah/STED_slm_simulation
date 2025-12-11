function [fcp_x, fcp_y, was_clamped, scale] = clamp_fcp_nyquist(fcp_x, fcp_y)
%CLAMP_FCP_NYQUIST Enforce |fcp| <= 0.5 cycles/pixel.

    fcp_mag = sqrt(fcp_x.^2 + fcp_y.^2);

    if fcp_mag > 0.5
        scale = 0.5 / fcp_mag;
        fcp_x = fcp_x * scale;
        fcp_y = fcp_y * scale;
        was_clamped = true;
    else
        scale = 1;
        was_clamped = false;
    end
end
