# Physics Sequence for `donut_simulator.m`

Step-by-step equations that mirror the script and helpers. Symbols: $x,y$ in meters unless noted; pixel pitches $p_x,p_y$; wavelength $\lambda$; focal lengths $f,f_1,f_2$; topological charge $\ell$; steering carrier $f_{cp}$ in cycles/pixel.

## 1) Coordinates and Input Beam
- Grid (from `make_coordinates`):
  $$x_i = \big(i - \tfrac{N_x-1}{2}\big)\,p_x,\qquad y_j = \big(j - \tfrac{N_y-1}{2}\big)\,p_y$$
- Gaussian amplitude (1/e$^2$ radii $w_{0x}, w_{0y}$):
  $$E_{\text{in}}(X,Y) = \exp\!\left(-\frac{X^2}{w_{0x}^2} - \frac{Y^2}{w_{0y}^2}\right)$$

## 2) 4f Spatial Filter (`apply_spatial_filter_4f`)
- Forward FT:
  $$F(f_x,f_y) = \iint E_{\text{in}}(x,y)\,e^{-i2\pi(f_x x + f_y y)}\,dx\,dy$$
- Lens-1 focal plane mapping:
  $$X_B = \lambda f_1 f_x,\qquad Y_B = \lambda f_1 f_y$$
- Pinhole mask with diameter $d$:
  $$M_p(X_B,Y_B) = \mathbf{1}\{\sqrt{X_B^2 + Y_B^2} \le d/2\}$$
- Filtered spectrum: $F_{\text{after}} = F\,M_p$.
- Inverse FT to object coordinates; magnification $M = f_2/f_1$, parity flip: $x_C = -M x,\ y_C = -M y$; amplitude optionally scaled by $(f_1/f_2)$.

## 3) Steering Choice and Safety
- Shift $\rightarrow$ angle:
  $$\theta_x = \arctan\!\left(\frac{\Delta_x}{f}\right),\qquad \theta_y = \arctan\!\left(\frac{\Delta_y}{f}\right)$$
- Angle $\rightarrow$ carrier:
  $$f_{cp,x} = \theta_x\,\frac{p_x}{\lambda},\qquad f_{cp,y} = \theta_y\,\frac{p_y}{\lambda}$$
- Nyquist clamp: if $\sqrt{f_{cp,x}^2 + f_{cp,y}^2} > 0.5$, scale both by $0.5/\|f_{cp}\|$.
- Predicted Fourier-plane shift:
  $$\Delta_x = f\,\lambda\,\frac{f_{cp,x}}{p_x},\qquad \Delta_y = f\,\lambda\,\frac{f_{cp,y}}{p_y}$$

## 4) Phase Building Blocks
- Vortex:
  $$\phi_{\text{vortex}} = \ell\,\operatorname{atan2}(Y, X)$$
- Steering grating (pixel indices $\xi,\eta$):
  $$\phi_{\text{shift}} = 2\pi\big(f_{cp,x}\,\xi + f_{cp,y}\,\eta\big)$$
- Digital lens (optional):
  $$\phi_{\text{lens}} = -\frac{\pi}{\lambda f_{\text{focus}}}(X^2 + Y^2)$$
- Optional circular aperture mask $M_{\text{circ}}$ multiplies $\phi_{\text{vortex}}$ region.

## 5) Phase-Only Hologram Encoding
- Desired phase:
  $$\phi_{\text{des}} = M_{\text{circ}}\,\phi_{\text{vortex}} + \phi_{\text{shift}} + \phi_{\text{lens}}$$
- Superposition kinoform:
  $$U = d_c + \gamma\,e^{i\phi_{\text{des}}}$$
- Display phase: $\phi = \operatorname{angle}(U)$; optional noise: $\phi \mathrel{+}= \mathcal{N}(0,\sigma^2)$.
- Wrap: $\phi_{\text{wrap}} = \operatorname{mod}(\phi, 2\pi)$.
- SLM mapping:
  $$\text{gray} = \operatorname{clip}\!\left( \operatorname{round}\!\left( \frac{\phi_{\text{wrap}}}{2\pi} \cdot c2pi2unit \right),\ 0,\ c2pi2unit \right)$$
- Field after SLM (pre-polarization):
  $$E = |E_{\text{beam}}|\,e^{i\phi_{\text{wrap}}}$$

## 6) Polarization Waveplate (`apply_waveplate`)
- Rotation:
  $$R(\alpha) = \begin{bmatrix}\cos\alpha & -\sin\alpha\\ \sin\alpha & \cos\alpha\end{bmatrix}$$
- Waveplate (fast axis $x'$): $J_0 = \operatorname{diag}(1, e^{i\delta})$.
- Jones matrix in lab frame:
  $$J = R^T\! J_0\, R$$
- Output field:
  $$\begin{bmatrix}E_x\\E_y\end{bmatrix} = J\,\begin{bmatrix}E_{x,\text{in}}\\E_{y,\text{in}}\end{bmatrix}$$
(Quarter-wave when $\delta = \pi/2$, $\alpha = 45^\circ$.)

## 7) Far-Field FFT (Fourier Plane)
- Pad by factor $P$; center $E$ in zero array, FFT: $E_{\text{FF}} = \operatorname{FFT2}_{\text{shifted}}(E_{\text{pad}})$.
- Intensity: $I_{\text{FF}} = |E_{\text{FF}}|^2$, normalized to max $=1$.
- Physical sampling:
  $$\Delta x_F^{\text{native}} = \frac{f\,\lambda}{N_x p_x},\qquad \Delta x_F = \frac{\Delta x_F^{\text{native}}}{P}$$
  $$x_F = k\,\Delta x_F,\quad k\in\left[-\tfrac{N_x P}{2},\tfrac{N_x P}{2}-1\right]$$
  (same for $y_F$). Small-angle steering: $\theta \approx \lambda f_{cp}/p$ places the donut near $(\Delta_x, \Delta_y)$.

## 8) Fresnel Propagation (Angular Spectrum, optional)
- Wavenumber: $k = 2\pi/\lambda$; spatial frequencies from array size and pitch: $f_x,f_y$.
- Transfer function:
  $$H(f_x,f_y) = \exp\!\Big(i k z\,\sqrt{\max\big(0,\,1 - (\lambda f_x)^2 - (\lambda f_y)^2\big)}\Big)$$
- Propagated field:
  $$E_z = \mathcal{F}^{-1}\!\big( \mathcal{F}(E)\, H \big),\qquad I_z = |E_z|^2$$

## 9) STED-Style Radius Estimate (script diagnostic)
- Rough diameter printed by script:
  $$R_{\text{STED}} \approx \frac{2\,\lambda\, f}{\pi\sqrt{2}\,w_{0x}}$$

## 10) File I/O Landmarks
- Inputs: `LCOS_SLM_X15213.json` ($N_x, N_y, p_x, p_y, c2pi2unit, \text{fill}$), `GaussianBeam.json` ($\lambda, w_{0x}, w_{0y}, M^2, \text{centers}$), optional calibration BMP in `Correction_patterns/`.
- Outputs: mask BMP `slm_vortex_*.bmp`, simulated `sim_farfield_fft.bmp`, optional `sim_fresnel_z.bmp`.
