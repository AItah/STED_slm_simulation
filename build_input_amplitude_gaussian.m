function A = build_input_amplitude_gaussian(beam, X, Y)
%BUILD_INPUT_AMPLITUDE_GAUSSIAN Collimated Gaussian amplitude at SLM plane.
%
% beam.w0x_1e2_m and w0y_1e2_m are 1/e^2 INTENSITY radii.
% So amplitude is exp(-(x^2/w^2)).

    Xc = X - beam.center_x_m;
    Yc = Y - beam.center_y_m;

    wx = beam.w0x_1e2_m;
    wy = beam.w0y_1e2_m;

    A = beam.power_norm * exp( -(Xc.^2)/(wx^2) - (Yc.^2)/(wy^2) );
end
