# Physics Sequence for `donut_simulator.m`

Step-by-step equations that mirror the script and its helpers. Symbols: `x,y` in meters unless noted; pixel pitch `p_x, p_y`; wavelength `λ`; focal lengths `f, f1, f2`; topological charge `ℓ`; steering carrier `f_cp` in cycles/pixel.

## 1) Coordinates and Input Beam
- Grid: `x_i = (i - (N_x-1)/2) * p_x`, `y_j = (j - (N_y-1)/2) * p_y`; meshes `X, Y` from `make_coordinates`.
- Gaussian amplitude (1/e^2 radii `w0x, w0y`):
  `E_in(X,Y) = exp(-(X^2/w0x^2 + Y^2/w0y^2))` (power-normalized upstream).

## 2) 4f Spatial Filter (`apply_spatial_filter_4f`)
- Forward FT: `F(f_x,f_y) = ∫∫ E_in e^{-i2π(f_x x + f_y y)} dx dy`.
- Lens-1 focal plane mapping: `X_B = λ f1 f_x`, `Y_B = λ f1 f_y`.
- Pinhole mask: `M_p(X_B,Y_B) = 1{√(X_B^2+Y_B^2) ≤ d/2}` with diameter `d = pinhole_d`.
- Filtered spectrum: `F_after = F · M_p`.
- Inverse FT to object coordinates, then magnification `M = f2/f1`; coordinates scale to `x_C = -M x`, `y_C = -M y` (parity flip). Optional amplitude scale `(f1/f2)` applied.

## 3) Steering Choice and Safety
- Shift → angle: `θ_x = atan(Δ_x / f)`, `θ_y = atan(Δ_y / f)`.
- Angle → carrier: `f_cp_x = θ_x p_x / λ`, `f_cp_y = θ_y p_y / λ`.
- Nyquist clamp: if `√(f_cp_x^2+f_cp_y^2) > 0.5`, scale both by `0.5 / ‖f_cp‖`.
- Predicted Fourier-plane shift: `Δ_x = f λ f_cp_x / p_x`, `Δ_y = f λ f_cp_y / p_y`.

## 4) Phase Building Blocks
- Vortex: `φ_vortex = ℓ · atan2(Y, X)`.
- Steering grating: `φ_shift = 2π ( f_cp_x · ξ + f_cp_y · η )` where `(ξ, η)` are pixel-index grids.
- Digital lens (optional): `φ_lens = -π (X^2 + Y^2) / (λ f_focus)`.
- Aperture mask (optional circular): `M_circ` applied multiplicatively to `φ_vortex` region.

## 5) Phase-Only Hologram Encoding
- Combined desired phase: `φ_des = M_circ·φ_vortex + φ_shift + φ_lens`.
- Superposition kinoform: `U = d_c + γ · exp(i φ_des)` with DC bias `d_c` and weight `γ`.
- Phase to display: `φ = angle(U)`; optional additive noise `φ += N(0, σ^2)`.
- Wrap: `φ_wrapped = mod(φ, 2π)`.
- SLM mapping: `gray = round( (φ_wrapped / 2π) · c2pi2unit )`, clipped to `[0, c2pi2unit]`.
- Field after SLM (before polarization): `E = |E_beam| · exp(i φ_wrapped)`.

## 6) Polarization Waveplate (`apply_waveplate`)
- Jones matrix with retardance `δ` and fast-axis `α`:
  `R(α) = [[cosα, -sinα],[sinα, cosα]]`, `J0 = diag(1, e^{iδ})`, `J = Rᵀ J0 R`.
- Output: `[E_x; E_y] = J · [E_x_in; E_y_in]` (quarter-wave when `δ = π/2`, `α = 45°`).

## 7) Far-Field FFT (Fourier Plane)
- Pad by factor `P` around SLM field: place `E` into center of zero array.
- Compute `E_FF = FFT2_shifted(E_pad)`; intensity `I_FF = |E_FF|^2`, normalized to max=1.
- Physical sampling: native `Δx_F = f λ / (N_x p_x)`, padded `Δx_F_pad = Δx_F / P`; axes `x_F = (-N_xP/2…)*Δx_F_pad` (same for `y`).
- Small-angle steering relation reused: `θ ≈ λ f_cp / p`, so first-order donut sits near `(Δ_x, Δ_y)` above.

## 8) Fresnel Propagation (Angular Spectrum, optional)
- Spatial frequencies: `f_x = k_x/(2π)`, `f_y = k_y/(2π)` from array size and pitch.
- Transfer: `H = exp(i k z · √( max(0, 1 - (λ f_x)^2 - (λ f_y)^2) ))`, `k = 2π/λ`.
- Propagated field: `E_z = FFT⁻¹( FFT(E) · H_shifted )`; intensity `I_z = |E_z|^2` (normalized).

## 9) STED-Style Radius Estimate (script diagnostic)
- Rough diameter printed: `R_STED ≈ 2 · λ f / (π √2 · w0x)` (using beam waist and focal length from current params).

## 10) File I/O Landmarks
- Inputs: `LCOS_SLM_X15213.json` (`N_x, N_y, p_x, p_y, c2pi2unit, fill`), `GaussianBeam.json` (`λ, w0x, w0y, M², centers`), optional calibration BMP in `Correction_patterns/`.
- Outputs: mask BMP `slm_vortex_*.bmp`, simulated `sim_farfield_fft.bmp`, optional `sim_fresnel_z.bmp`.
