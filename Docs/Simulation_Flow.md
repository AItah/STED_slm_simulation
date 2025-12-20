# Donut Simulator: Simulation Flow

This document outlines the execution logic for `donut_simulator.m` and serves as a guideline for Mermaid flowcharts in this repo.

## Flowchart Guidelines (Mermaid)

- Use fenced blocks: ```` ```mermaid ```` … ```` ``` ```` (GitHub renders these automatically).
- Keep node text simple (avoid parentheses-heavy “code-like” labels); put detailed math in the “Key relations” section below in LaTeX.
- Prefer a small number of nodes with clear verbs; use `subgraph` blocks to group major phases.
- When you reference code, use the exact function name (no arguments) and add a traceability list with `donut_simulator.m:<line>` links.

## Process Flowchart (Matches `donut_simulator.m`)

```mermaid
flowchart TD
    %% Inputs / setup
    subgraph Inputs[Inputs]
        A0[Load calibration mask BMP<br/>load_grayscale_bmp] --> A1[Load SLM params JSON<br/>load_slm_params]
        A1 --> A2[Load beam params JSON<br/>load_gaussian_beam_params]
    end

    %% Input beam preparation (grid + 4f filter + crop)
    subgraph BeamPrep[Input Beam Prep (4f + crop)]
        B1[Build expanded coordinates<br/>make_coordinates] --> B2[Generate input beam amplitude<br/>make_gaussian_input_beam]
        B2 --> B3[Apply 4f spatial filter (default)<br/>apply_spatial_filter_4f]
        B3 --> B4[Crop field to SLM grid<br/>crop_field_to_slm]
    end

    A2 --> B1
    B4 --> C0[Use cropped field as SLM input amplitude]

    %% Steering (user inputs -> theta -> fcp -> clamp)
    subgraph Steering[Steering (user inputs)]
        C0 --> C1[Choose steering mode<br/>choose_steer_mode]
        C1 -->|shift| C2[Convert shift to angles<br/>theta_from_shift]
        C1 -->|angle| C3[Use user angles]
        C2 --> C4[Convert angles to carrier (cycles/pixel)<br/>fcp_from_theta]
        C3 --> C4
        C4 --> C5[Clamp to Nyquist<br/>clamp_fcp_nyquist]
    end

    %% Mask construction (vortex + optional forked shift + optional digital lens + circular mask)
    subgraph Mask[Mask Construction]
        C5 --> D1[Vortex phase<br/>make_vortex_phase]
        C5 --> D2{Forked mode enabled?}
        D2 -->|yes| D3[Shift phase<br/>make_shift_phase]
        D2 -->|no| D4[No shift term]
        C5 --> D5{Digital lens enabled?}
        D5 -->|yes| D6[Lens phase<br/>make_lens_phase]
        D5 -->|no| D7[No lens term]
        C5 --> D8[Circular aperture mask<br/>make_circular_mask]
        D1 --> D9[Desired phase<br/>vortex * mask + shift + lens]
        D3 --> D9
        D4 --> D9
        D6 --> D9
        D7 --> D9
        D8 --> D9
    end

    %% Phase-only encoding + saving
    subgraph Encoding[Phase-Only Encoding + Save]
        D9 --> E1[Superposition kinoform<br/>U = dc_bias + gamma * exp(i*desired)]
        E1 --> E2[Phase-only hologram<br/>phi = angle(U)]
        E2 --> E3[Optional phase noise]
        E3 --> E4[Wrap phase to [0, 2pi)<br/>phi_wrapped = mod(phi, 2pi)]
        E4 --> E5[Field after SLM<br/>E = Ein * exp(i*phi_wrapped)]
        E4 --> E6[Quantize phase to SLM grayscale]
        E6 --> E7[Save mask BMP<br/>imwrite slm_vortex_*.bmp]
    end

    %% Polarization model (used in far-field intensity)
    subgraph Pol[Polarization]
        E5 --> F1[Assume Ex = E, Ey = 0]
        F1 --> F2[Apply QWP<br/>apply_waveplate]
    end

    %% Simulation
    subgraph Sim[Simulation Outputs]
        F2 --> G0{Simulate?}
        G0 -->|Far-field FFT| G1[Zero-pad and FFT2]
        G1 --> G2[Intensity from Ex/Ey FFTs]
        G2 --> G3[Save sim_farfield_fft.bmp]
        G0 -->|Fresnel (optional)| H1[Angular spectrum propagation (uses E)]
        H1 --> H2[Save sim_fresnel_z.bmp]
    end
```

## Traceability (Key Calls in `donut_simulator.m`)

- Calibration mask load: `donut_simulator.m:9`
- Parameter loads: `donut_simulator.m:55`, `donut_simulator.m:63`
- Grid + beam: `donut_simulator.m:84`, `donut_simulator.m:87`
- 4f filter + crop: `donut_simulator.m:96`, `donut_simulator.m:98`
- Steering + clamp: `donut_simulator.m:138`, `donut_simulator.m:153`, `donut_simulator.m:157`, `donut_simulator.m:160`
- Phase construction: `donut_simulator.m:195`, `donut_simulator.m:201`, `donut_simulator.m:205`, `donut_simulator.m:210`
- Kinoform + wrap + field: `donut_simulator.m:221`, `donut_simulator.m:240`, `donut_simulator.m:286`
- Waveplate: `donut_simulator.m:297`
- Save mask: `donut_simulator.m:346`
- Far-field sim + save: `donut_simulator.m:363`, `donut_simulator.m:444`
- Fresnel sim + save: `donut_simulator.m:455`, `donut_simulator.m:473`

Key relations referenced:
- Carrier from angle: $f_{cp,x} = \theta_x p_x / \lambda$, clamp $\lVert f_{cp} \rVert \le 0.5$ cycles/pixel.
- Fourier-plane shift: $\Delta x = f \lambda f_{cp,x} / p_x$ (and $y$ likewise).
- Lens phase: $\phi_{\text{lens}} = -\pi (X^2+Y^2)/(\lambda f_{\text{focus}})$.
- Kinoform: $U = d_c + \gamma e^{i \phi_{\text{des}}}$, $\phi = \arg(U)$, wrap to $[0, 2\pi)$.
