# donut_simulator

## Overview
High-level script to build SLM phase masks (vortex, forked/steered, digital lens), encode phase-only kinoforms, apply polarization model and simulate far-field and Fresnel propagation. Saves masks and diagnostic images.

## Physics & Mathematics
Combines vortex phase $\ell\theta$, linear grating phase for steering, and quadratic Fresnel lens phase. Phase-only hologram formed from complex field
$$U=d_c+\gamma e^{i\phi_{combined}},\qquad\phi=\operatorname{angle}(U).$$
Far-field of SLM pattern computed via padded FFT; mapping from FFT bins to focal-plane distances uses $x_F=\lambda f f_x$.

## Logical Flow
- Load calibration and device JSONs.  
- Build input Gaussian beam and (optionally) 4f spatial filtering.  
- Determine steering mode, compute `fcp` and clamp to Nyquist.  
- Build phase masks (`vortex`, `shift`, `lens`) and combine.  
- Encode phase-only hologram with DC bias and weights, optionally add phase noise, wrap to [0,2π) and map to device units.  
- Apply waveplate Jones matrix, compute far-field via padded FFT or Fresnel propagation and save images.

## Architecture Diagram
```mermaid
sequenceDiagram
    participant User
    participant donut_simulator
    User->>donut_simulator: run script
    donut_simulator->>load_slm_params: load SLM JSON
    donut_simulator->>load_gaussian_beam_params: load beam JSON
    donut_simulator->>make_gaussian_input_beam: input beam
    donut_simulator->>apply_spatial_filter_4f: optional filtering
    donut_simulator->>make_vortex_phase: create vortex
    donut_simulator->>make_shift_phase: create steering ramp
    donut_simulator->>make_lens_phase: create digital lens
    donut_simulator->>apply_waveplate: polarization transform
    donut_simulator->>FFT: far-field simulation
    donut_simulator->>IO: save mask images
```

## Interface (API)
| Name | Type | Description |
|---|---:|---|
| Script | script | top-level driver reading JSONs and saving outputs |
| Outputs | files | SLM mask bitmap, FFT images, optional Fresnel images |
