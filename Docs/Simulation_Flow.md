# Simulation Flow for `donut_simulator.m`

High-level flow following the script and its helpers. Diagram is in Mermaid; view with a Mermaid renderer (e.g., VS Code Markdown preview).

```mermaid
flowchart TD
    A[Load inputs
LCOS_SLM_X15213.json
GaussianBeam.json
Calibration BMP] --> B[Build coordinates
make_coordinates]
    B --> C[Input beam
make_gaussian_input_beam]
    C --> D{4f spatial filter?
apply_spatial_filter_4f(_hybrid)}
    D -- yes --> D1[FFT -> pinhole mask
map X_B=lambda f1 f_x
back via iFFT
scale, invert, crop]
    D1 --> E[SLM-plane field]
    D -- no --> E
    E --> F{Steer mode
angle vs shift}
    F --> G[Shift->theta via atan(Delta/f)
or use theta from inputs]
    G --> H[f_cp = theta*p/lambda
clamp to |f_cp|<=0.5]
    H --> I[Phase terms
phi_vortex=ell atan2
phi_shift=2pi f_cp*xi,eta
phi_lens=-pi(X^2+Y^2)/(lambda f_focus)]
    I --> J[Optional circular mask
M_circ]
    J --> K[Desired phase
phi_des = M_circ*phi_vortex + phi_shift + phi_lens]
    K --> L[Kinoform superposition
U = d_c + gamma e^{i phi_des}
phi=angle(U), add noise?, wrap]
    L --> M[Map to SLM units
gray = round(phi_wrap/2pi * c2pi2unit)]
    M --> N[Save mask BMP
slm_vortex_*.bmp]
    M --> O[Field after SLM
E = |E_beam| e^{i phi_wrap}]
    O --> P[Polarization
apply_waveplate (QWP)]
    P --> Q{Simulate?}
    Q -- Far-field FFT --> R[Pad by P, FFT2
I_FF=|E_FF|^2
axes Delta_x_F = f lambda/(N p) / P]
    R --> S[Save sim_farfield_fft.bmp]
    Q -- Fresnel optional --> T[Angular spectrum
H = exp(i k z sqrt(1-(lambda f)^2))
E_z = F^-1(F*H)]
    T --> U[Save sim_fresnel_z.bmp]
```

Key relations referenced:
- Carrier from angle: `f_cp,x = theta_x p_x / lambda`, clamp `||f_cp|| <= 0.5` cycles/pixel.
- Fourier-plane shift: `Delta_x = f * lambda * f_cp,x / p_x` (and y likewise).
- Lens phase: `phi_lens = -pi (X^2+Y^2)/(lambda f_focus)`.
- Kinoform: `U = d_c + gamma exp(i phi_des)`, `phi = arg(U)`, wrap to `[0,2pi)`.
