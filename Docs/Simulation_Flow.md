flowchart TD
  %% ---------- Styles ----------
  classDef startend fill:#111827,stroke:#111827,color:#ffffff;
  classDef io fill:#e7f1ff,stroke:#2563eb,color:#0f172a;
  classDef process fill:#f8fafc,stroke:#64748b,color:#0f172a;
  classDef decision fill:#fff7ed,stroke:#f59e0b,color:#7c2d12;
  classDef output fill:#ecfdf5,stroke:#10b981,color:#064e3b;
  classDef note fill:#f3f4f6,stroke:#9ca3af,color:#111827,stroke-dasharray: 4 3;

  %% ---------- Inputs ----------
  A([Start]):::startend

  subgraph IN[Inputs]
    A1[LCOS_SLM_X15213.json]:::io
    A2[GaussianBeam.json]:::io
    A3[Calibration BMP]:::io
  end

  %% ---------- Preprocess ----------
  subgraph PRE[Preprocess]
    B[make_coordinates]:::process
    C[make_gaussian_input_beam]:::process
  end

  %% ---------- Spatial filter ----------
  subgraph SF[Optional 4f Spatial Filter]
    D{Apply 4f filter?}:::decision
    D1[FFT → pinhole mask<br/>XB = λ·f1·fx]:::process
    D2[iFFT → scale / invert / crop]:::process
    E[SLM-plane field]:::process
  end

  %% ---------- Hologram / SLM mask ----------
  subgraph HLG[Hologram & SLM Mask]
    F{Steer mode?}:::decision
    G1[Shift → θ = atan(Δ/f)]:::process
    G2[Use θ from inputs]:::process

    H[f_cp = θ·p/λ<br/>clamp |f_cp| ≤ 0.5]:::process

    I[Phase terms<br/>φ_vortex + φ_shift + φ_lens]:::process

    J{Circular mask?}:::decision
    J1[Apply M_circ]:::process

    K[Desired phase φ_des]:::process
    L[Kinoform<br/>U = d_c + γ·e^{iφ_des}<br/>φ = arg(U) → wrap]:::process
    M[Map to SLM units<br/>gray = round(φ/2π · c2pi2unit)]:::process
    N[Save mask BMP<br/>slm_vortex_*.bmp]:::output
  end

  %% ---------- After SLM ----------
  subgraph POST[After SLM]
    O[Field after SLM<br/>E = |E_beam| · e^{iφ}]:::process
    P[Polarization<br/>apply_waveplate(QWP)]:::process
  end

  %% ---------- Simulation ----------
  subgraph SIM[Simulation (Optional)]
    Q{Simulate?}:::decision

    R[Far-field FFT<br/>pad → FFT2 → I = |E|^2<br/>Δx = fλ/(N·p)/P]:::process
    S[Save sim_farfield_fft.bmp]:::output

    T[Fresnel / Angular spectrum<br/>H = exp(i k z √(1-(λf)^2))<br/>E_z = F⁻¹(FE · H)]:::process
    U[Save sim_fresnel_z.bmp]:::output
  end

  Z([End]):::startend

  %% ---------- Connections ----------
  A --> A1
  A --> A2
  A --> A3

  A1 --> B
  A2 --> B
  A3 --> B

  B --> C
  C --> D

  D -- Yes --> D1 --> D2 --> E
  D -- No  --> E

  E --> F
  F -- Shift --> G1 --> H
  F -- Angle --> G2 --> H

  H --> I --> J
  J -- Yes --> J1 --> K
  J -- No  --> K

  K --> L --> M
  M --> N
  M --> O --> P --> Q

  Q -- "Far-field FFT" --> R --> S --> Z
  Q -- "Fresnel (optional)" --> T --> U --> Z
  Q -- No --> Z
