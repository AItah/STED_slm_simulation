# Simulation Flow for `donut_simulator.m`

High-level flow following the script and its helpers. Diagram is in Mermaid; view with a Mermaid renderer (e.g., VS Code Markdown preview).

```mermaid
flowchart TD
    A[Load inputs<br/>LCOS_SLM_X15213.json<br/>GaussianBeam.json<br/>Calibration BMP] --> B[Build coordinates<br/>make_coordinates]
    B --> C[Input beam<br/>make_gaussian_input_beam]
    C --> D{4f spatial filter?<br/>apply_spatial_filter_4f(_hybrid)}
    D -- yes --> D1[FFT -> pinhole mask<br/>map $X_B = \lambda f_1 f_x$<br/>back via iFFT<br/>scale, invert, crop]
    D1 --> E[SLM-plane field]
    D -- no --> E
    E --> F{Steer mode<br/>angle vs shift}
    F --> G[Shift -> $\theta$ via $\operatorname{atan}(\Delta/f)$<br/>or use $\theta$ from inputs]
    G --> H[$f_{cp} = \theta p / \lambda$<br/>clamp to $|f_{cp}| \le 0.5$]
    H --> I[Phase terms<br/>$\phi_{\text{vortex}} = \ell\,\operatorname{atan2}$<br/>$\phi_{\text{shift}} = 2\pi f_{cp} \cdot (\xi,\eta)$<br/>$\phi_{\text{lens}} = -\pi (X^2+Y^2)/(\lambda f_{\text{focus}})$]
    I --> J[Optional circular mask<br/>$M_{\text{circ}}$]
    J --> K[Desired phase<br/>$\phi_{\text{des}} = M_{\text{circ}}\phi_{\text{vortex}} + \phi_{\text{shift}} + \phi_{\text{lens}}$]
    K --> L[Kinoform superposition<br/>$U = d_c + \gamma e^{i \phi_{\text{des}}}$<br/>$\phi = \arg(U)$, add noise?, wrap]
    L --> M[Map to SLM units<br/>$\text{gray} = \operatorname{round}(\phi_{\text{wrap}}/2\pi \cdot c2pi2unit)$]
    M --> N[Save mask BMP<br/>slm_vortex_*.bmp]
    M --> O[Field after SLM<br/>$E = |E_{\text{beam}}| e^{i \phi_{\text{wrap}}}$]
    O --> P[Polarization<br/>apply_waveplate (QWP)]
    P --> Q{Simulate?}
    Q -- Far-field FFT --> R[Pad by P, FFT2<br/>$I_{FF}=|E_{FF}|^2$<br/>axes $\Delta x_F = f \lambda/(N p) / P$]
    R --> S[Save sim_farfield_fft.bmp]
    Q -- Fresnel optional --> T[Angular spectrum<br/>$H = e^{i k z \sqrt{1-(\lambda f)^2}}$<br/>$E_z = \mathcal{F}^{-1}(\mathcal{F}E * H)$]
    T --> U[Save sim_fresnel_z.bmp]
```

Key relations referenced:
- Carrier from angle: $f_{cp,x} = \theta_x p_x / \lambda$, clamp $\lVert f_{cp} \rVert \le 0.5$ cycles/pixel.
- Fourier-plane shift: $\Delta x = f \lambda f_{cp,x} / p_x$ (and $y$ likewise).
- Lens phase: $\phi_{\text{lens}} = -\pi (X^2+Y^2)/(\lambda f_{\text{focus}})$.
- Kinoform: $U = d_c + \gamma e^{i \phi_{\text{des}}}$, $\phi = \arg(U)$, wrap to $[0, 2\pi)$.
