# Donut Simulator: Simulation Flow

This document outlines the execution logic for `donut_simulator.m`. The flowchart below describes the data transformation from input parameters to the final simulated field.

## Process Flowchart

```mermaid
flowchart TD
    %% Define Nodes
    A[Load Inputs:<br/>SLM & Beam JSONs] --> B[Build Coordinates<br/>make_coordinates]
    B --> C[Generate Input Beam<br/>make_gaussian_input_beam]
    
    C --> D{4f Spatial Filter?}
    D -- Yes --> D1[FFT to Pinhole Mask]
    D1 --> D2[iFFT & Scaling]
    D2 --> E[SLM-Plane Field]
    D -- No --> E

    E --> F{Steer Mode}
    F -- Shift --> G1[Calculate theta via atan]
    F -- Angle --> G2[Use theta from inputs]
    
    G1 & G2 --> H[Calculate Carrier Frequency<br/>f_cp = theta * p / lambda]
    H --> I[Generate Phase Terms]
    
    subgraph Phase_Construction [Phase Component Summation]
        I1[Vortex Phase]
        I2[Shift Phase]
        I3[Lens Phase]
    end

    I1 & I2 & I3 --> K[Desired Phase: phi_des]
    K --> L[Kinoform Superposition<br/>U = d_c + gamma * exp]
    
    L --> M[Map to SLM Units<br/>Quantize to Gray Levels]
    M --> N[Save Mask BMP]
    M --> O[Propagate Field after SLM]
    
    O --> P[Apply Polarization<br/>Waveplate/QWP]
    
    P --> Q{Simulation Type}
    Q -- Far-field --> R[Pad & FFT2]
    R --> S[Save sim_farfield_fft.bmp]
    
    Q -- Fresnel --> T[Angular Spectrum Propagation]
    T --> U[Save sim_fresnel_z.bmp]
```

Key relations referenced:
- Carrier from angle: $f_{cp,x} = \theta_x p_x / \lambda$, clamp $\lVert f_{cp} \rVert \le 0.5$ cycles/pixel.
- Fourier-plane shift: $\Delta x = f \lambda f_{cp,x} / p_x$ (and $y$ likewise).
- Lens phase: $\phi_{\text{lens}} = -\pi (X^2+Y^2)/(\lambda f_{\text{focus}})$.
- Kinoform: $U = d_c + \gamma e^{i \phi_{\text{des}}}$, $\phi = \arg(U)$, wrap to $[0, 2\pi)$.
