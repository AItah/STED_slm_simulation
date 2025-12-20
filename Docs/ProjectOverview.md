# SLM FFT Mask Simulation (Draft Documentation)

## What This Project Does
- Simulates SLM phase masks and beam propagation for donut/vortex beams, including steering, digital lens terms, and polarization effects.
- Provides utilities for beam generation, 4f spatial filtering, Nyquist-safe steering, mask synthesis, and far-field/Fresnel simulations.
- Ships ready-to-run scripts (`Main.m`, `donut_simulator.m`, `donut_vortex_with_pixel_MTF.m`) plus per-function docs in `Docs/`.

## Quick Start (MATLAB)
1) Add repo folder to MATLAB path. No toolboxes required.
2) Check inputs: `LCOS_SLM_X15213.json` (device), `GaussianBeam.json` (beam), optional `Correction_patterns/*.bmp` (calibration).
3) Run a basic FFT mask demo: `Main` (creates rectangular mask + FFT magnitude plots).
4) Run full vortex/donut workflow: `donut_simulator` (builds vortex/forked mask, applies 4f filter, optional digital lens, polarization, far-field FFT/Fresnel). Outputs `slm_vortex_*.bmp`, `sim_farfield_fft.bmp`, `sim_fresnel_z.bmp`.
5) Pixel-aperture study: `donut_vortex_with_pixel_MTF` (models finite fill factor with oversampling OS, plots aperture, SLM field, far-field cuts).

## Key Inputs & Outputs
- Inputs: `GaussianBeam.json` (λ, waist, M², center), `LCOS_SLM_X15213.json` (resolution, pitch, fill factor, 2π→unit scale), optional correction mask in `Correction_patterns/`.
- Outputs: mask bitmaps in project root (`slm_vortex_*`), simulated intensity bitmaps (`sim_farfield_fft.bmp`, `sim_fresnel_z.bmp`), figures on-screen.
- Temporary/optional: `sim_outputs/` can store extra runs; large raw BMPs already included for reference.

## Core Scripts
- `Main.m` – simple rectangular mask + 2-D FFT visualization with physical axes.
- `donut_simulator.m` – end-to-end vortex/forked mask creation, Nyquist-safe steering, optional digital lens, polarization (QWP), far-field and Fresnel sims, save masks.
- `donut_vortex_with_pixel_MTF.m` – high-res pixel-aperture model (fill factor) and far-field FFT with optional focal-plane mapping.

## Important Utilities (see per-file docs in `Docs/`)
- Beam & coords: `make_gaussian_input_beam`, `make_coordinates`, `crop_field_to_slm`, `crop_field_to_slm_4plot`.
- Phase building: `make_vortex_phase`, `make_shift_phase`, `make_lens_phase`, `make_circular_mask`.
- Steering helpers: `choose_steer_mode`, `theta_from_shift`, `fcp_from_theta`, `clamp_fcp_nyquist`.
- Optics blocks: `apply_spatial_filter_4f`, `apply_spatial_filter_4f_hybrid`, `apply_waveplate`, `plot_intensity_with_1e2_contour`, `show_1e2_radius`.
- I/O: `load_slm_params`, `load_gaussian_beam_params`, `load_grayscale_bmp`, `read_json_file`.

## Typical Workflow (donut_simulator)
1) Load device/beam JSON → build expanded Gaussian beam.
2) (Optional) 4f spatial filter and crop to SLM grid.
3) Decide steering (angle vs. shift) → compute `fcp` → clamp to Nyquist.
4) Compose phase (`vortex + shift + optional lens`) → encode phase-only kinoform with DC bias.
5) Apply waveplate → map to 8-bit units → save mask; run FFT/Fresnel sims; log steering predictions.

## Tuning Tips
- Steering: adjust `theta_*` or `Delta_*`; watch console for clamped values.
- Sampling: increase `P_pad` (FFT oversampling) or `OS` (pixel-aperture oversampling) for finer grids.
- Mask noise: set `phase_sigma_mask_rad` > 0 to study robustness.
- Digital lens: enable `use_digital_lens` and set `f_focus` to remove physical lens.
- Pinhole: tweak `pinhole_d` and focal lengths `f1/f2` in 4f filter; ensure `M_4f`≥1 to avoid undersampling.

## References
- Detailed per-function notes live in `Docs/*.md` (already checked in).
- Math snippets: see `Docs/Simulation_Summary.tex` for derivations and workflow diagrams.
