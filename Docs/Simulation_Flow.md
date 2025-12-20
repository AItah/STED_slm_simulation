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

    %% Input beam preparation
    subgraph BeamPrep[Input Beam Prep]
        B1[Build expanded coordinates<br/>make_coordinates] --> B2[Generate input beam amplitude<br/>make_gaussian_input_beam]
        B2 --> B3[Apply 4f spatial filter<br/>apply_spatial_filter_4f]
        B3 --> B4[Crop field to SLM grid<br/>crop_field_to_slm]
    end

    A2 --> B1
    B4 --> C0[Cropped field = SLM input amplitude]

    %% Steering
    subgraph Steering[Steering]
        C0 --> C1{Choose steering mode}
        C1 -- shift --> C2[Convert shift to angles<br/>theta_from_shift]
        C1 -- angle --> C3[Use user angles]
        C2 --> C4[Convert angles to carrier<br/>fcp_from_theta]
        C3 --> C4
        C4 --> C5[Clamp to Nyquist<br/>clamp_fcp_nyquist]
    end

    %% Mask construction
    subgraph Mask[Mask Construction]
        C5 --> D_Logic{Feature Check}
        D_Logic --> D1[Vortex phase<br/>make_vortex_phase]
        D_Logic --> D2{Forked mode?}
        D2 -- yes --> D3[Shift phase<br/>make_shift_phase]
        D2 -- no --> D4[No shift term]
        
        D_Logic --> D5{Digital lens?}
        D5 -- yes --> D6[Lens phase<br/>make_lens_phase]
        D5 -- no --> D7[No lens term]
        
        D_Logic --> D8[Circular aperture mask<br/>make_circular_mask]

        D1 & D3 & D4 & D6 & D7 & D8 --> D9[Sum Desired Phase<br/>vortex*mask + shift + lens]
    end

    %% Phase-only encoding
    subgraph Encoding[Phase-Only Encoding + Save]
        D9 --> E1[Superposition kinoform<br/>U = dc + gamma * exp]
        E1 --> E2[Phase-only hologram<br/>phi = angle_U]
        E2 --> E3[Optional phase noise]
        E3 --> E4[Wrap phase to 0, 2pi]
        E4 --> E5[Field after SLM<br/>E = Ein * exp]
        E4 --> E6[Quantize to SLM grayscale]
        E6 --> E7[Save mask BMP]
    end

    %% Polarization
    subgraph Pol[Polarization]
        E5 --> F1[Assume Ex = E, Ey = 0]
        F1 --> F2[Apply QWP<br/>apply_waveplate]
    end

    %% Simulation
    subgraph Sim[Simulation Outputs]
        F2 --> G0{Simulate?}
        G0 -- Far-field --> G1[Zero-pad and FFT2]
        G1 --> G2[Intensity calculation]
        G2 --> G3[Save sim_farfield_fft.bmp]
        
        G0 -- Fresnel --> H1[Angular spectrum propagation]
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
