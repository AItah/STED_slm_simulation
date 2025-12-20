# two_delta

## Overview
Computes the convolution of two discrete delta impulses with a Gaussian PSF and compares numeric convolution to the analytic sum of two shifted Gaussians. Intended as a demonstration / unit check.

## Physics & Mathematics
Discrete representation of two Dirac deltas and convolution with a Gaussian PSF. Let the delta separation be $d$ and Gaussian standard deviation $\sigma$. The continuous analytic result is
$$y(x)=\frac{1}{\sigma\sqrt{2\pi}}\left[\exp\left(-\frac{(x-\tfrac{d}{2})^{2}}{2\sigma^{2}}\right)+\exp\left(-\frac{(x+\tfrac{d}{2})^{2}}{2\sigma^{2}}\right)\right].$$

The numeric convolution approximates
$$y_{num}(x)\approx\int s(\xi)g(x-\xi)\,d\xi\approx\sum_{n}s_n g(x_n)\,\Delta x$$
with discrete impulses $s_n$ having amplitude $1/\Delta x$ at the sample locations.

## Logical Flow
- Define parameters $d$, FWHM and compute $\sigma$.  
- Build fine grid $x$ and place two discrete impulses separated by $d$.  
- Create normalized Gaussian PSF $g(x)$.  
- Compute numeric convolution via `conv(...,'same')*\Delta x`.  
- Compute analytic sum of two shifted Gaussians and plot both.

## Architecture Diagram
```mermaid
sequenceDiagram
    participant Script as two_delta.m
    participant Grid as x samples
    participant Delta as discrete impulses s(x)
    participant PSF as Gaussian g(x)
    participant Output as y_num, y_ana, Figure

    Grid->>Delta: place two impulses at ±d/2
    Grid->>PSF: compute g(x;\sigma)
    Delta->>Script: s(x)
    PSF->>Script: g(x)
    Script->>Output: compute y_num = conv(s,g)*dx
    Script->>Output: compute y_ana = sum shifted Gaussians
    Script->>Output: plot comparison
```

## Interface (API)
| Name | Type | Description |
|---|---:|---|
| `d` | scalar [m] | separation between impulses (input parameter inside script) |
| `FWHM`, `sigma` | scalar [m] | Gaussian width (derived) |
| `x` | vector [m] | coordinate grid |
| `s` | vector | discrete impulses (internal) |
| `g` | vector | Gaussian PSF (internal) |
| `y_num`, `y_ana` | vector | numeric and analytic convolution results (plotted outputs) |
