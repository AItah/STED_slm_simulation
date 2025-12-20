# Simulation Flow for `donut_simulator.m`

High-level flow following the script and its helpers. Diagram is plain-text Mermaid to maximize compatibility across GitHub and IDE previews; equations stay below in LaTeX.

```mermaid
flowchart TD
    A[Load inputs] --> B[Build coordinates]
    B --> C[Generate input beam]
    C --> D{Apply 4f spatial filter?}
    D -- yes --> D1[FFT -> pinhole mask -> iFFT -> crop]
    D -- no --> E
    D1 --> E[SLM-plane field]
    E --> F{Steer mode?}
    F --> G[Steer by angle or shift]
    G --> H[Compute f_cp and clamp]
    H --> I[Add phase terms (vortex, shift, lens)]
    I --> J[Optional circular mask]
    J --> K[Compose desired phase]
    K --> L[Kinoform superposition and wrap]
    L --> M[Map to SLM units]
    M --> N[Save mask BMP]
    M --> O[Field after SLM]
    O --> P[Polarization (QWP)]
    P --> Q{Simulate?}
    Q -- Far-field FFT --> R[Pad -> FFT2 -> I_FF]
    R --> S[Save sim_farfield_fft.bmp]
    Q -- Fresnel optional --> T[Angular spectrum -> inverse FFT]
    T --> U[Save sim_fresnel_z.bmp]
```

Key relations referenced:
- Carrier from angle: $f_{cp,x} = \theta_x p_x / \lambda$, clamp $\lVert f_{cp} \rVert \le 0.5$ cycles/pixel.
- Fourier-plane shift: $\Delta x = f \lambda f_{cp,x} / p_x$ (and $y$ likewise).
- Lens phase: $\phi_{\text{lens}} = -\pi (X^2+Y^2)/(\lambda f_{\text{focus}})$.
- Kinoform: $U = d_c + \gamma e^{i \phi_{\text{des}}}$, $\phi = \arg(U)$, wrap to $[0, 2\pi)$.
