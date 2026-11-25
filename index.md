# bayespk

[![R-CMD-check](https://github.com/DaikiKumakura/bayespk/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/DaikiKumakura/bayespk/actions/workflows/R-CMD-check.yaml)
[![R-universe](https://daikikumakura.r-universe.dev/badges/bayespk)](https://daikikumakura.r-universe.dev/bayespk)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.24325845.svg)](https://doi.org/10.5281/zenodo.24325845)

Bayesian population pharmacokinetics in R **without writing Stan**.

## Installation

From R-universe (binaries for Windows, macOS and Linux):

``` r

install.packages("bayespk", repos = c("https://daikikumakura.r-universe.dev", "https://cloud.r-project.org"))
```

From GitHub (compiles the Stan program once; needs a C++ toolchain,
about 1.5 minutes on Windows):

``` r

# install.packages("remotes")
remotes::install_github("DaikiKumakura/bayespk")
```

Not on CRAN.

## Quick start

``` r

library(bayespk)

mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"), error = "proportional")
fit <- bpk_fit(mod, bpk_example, chains = 4, cores = 4, seed = 1)   # 30 simulated subjects
summary(fit)
#>    variable   mean     sd     q5    q50    q95 rhat ess_bulk ess_tail
#>          CL  2.860 0.1420  2.630  2.860  3.100 1.00     6530     2740
#>           V 27.700 1.6400 25.100 27.700 30.600 1.00     4760     3040
#>          KA  0.976 0.0905  0.840  0.971  1.130 1.00     4750     2980
#>    omega_CL  0.257 0.0405  0.199  0.252  0.330 1.01      910     1500
#>     omega_V  0.298 0.0486  0.226  0.295  0.384 1.00     1050     2090
#>    omega_KA  0.365 0.0849  0.238  0.358  0.515 1.00     1490     2030
#>  sigma_prop  0.157 0.0117  0.139  0.156  0.176 1.00     2030     2860

plot(fit)   # individual fits
```

![Individual fits: observed concentrations (red) with posterior median
and 90% interval per subject](reference/figures/README-individual.png)

Individual fits: observed concentrations (red) with posterior median and
90% interval per subject

Compare dosing regimens for new patients (from the [two-compartment
vignette](https://daikikumakura.github.io/bayespk/articles/two-compartment.html)):

``` r

a <- predict(fit2, regimen = dose_regimen(500, ii = 12, n = 8, rate = 500), times = t)
b <- predict(fit2, regimen = dose_regimen(1000, ii = 24, n = 4, rate = 1000), times = t)
plot(a, compare = b, log = TRUE, labels = c("500 mg every 12 h", "1000 mg every 24 h"))
```

![Predicted concentrations for two regimens, median and 90% interval of
new subjects](reference/figures/README-regimens.png)

Predicted concentrations for two regimens, median and 90% interval of
new subjects

## Documentation

[Package website](https://daikikumakura.github.io/bayespk/) · [Function
reference](https://daikikumakura.github.io/bayespk/reference/) ·
[Changelog](https://daikikumakura.github.io/bayespk/news/) ·
[Releases](https://github.com/DaikiKumakura/bayespk/releases) ·
[R-universe](https://daikikumakura.r-universe.dev/bayespk)

- [Getting
  started](https://daikikumakura.github.io/bayespk/articles/bayespk.html):
  model, fit, results, plots and predictions.
- [Covariates and informative
  priors](https://daikikumakura.github.io/bayespk/articles/covariates-priors.html):
  weight effects, borrowing from earlier studies, prior sensitivity.
- [Two-compartment models and regimen
  comparison](https://daikikumakura.github.io/bayespk/articles/two-compartment.html):
  infusion data, comparing regimens, flip-flop.
- [Steady state and data below the quantification
  limit](https://daikikumakura.github.io/bayespk/articles/data-features.html):
  `SS = 1` and `CENS = 1` records.
- [Function
  reference](https://daikikumakura.github.io/bayespk/reference/).

## Overview

Show details

- **One line per model.**
  `pk_model("2cmt", route = "oral", iiv = c("CL", "V1", "KA"), covariates = list(CL ~ (WT / 70)^0.75))`.
- **Your NONMEM data set as it is.** `ID`, `TIME`, `DV`, `AMT`, `EVID`,
  `RATE`, `ADDL`/`II`, `SS = 1` (steady state), `CENS = 1` (below the
  quantification limit, Beal’s M3), and `"."` for missing values.
- **Nothing to compile.** The Stan programs are precompiled and use
  closed-form solutions, so a fit starts at once. Binaries are on
  R-universe.
- **Priors you can state and check.** Use earlier studies with
  [`pk_priors()`](https://daikikumakura.github.io/bayespk/reference/pk_priors.md).
  Defaults are printed, and
  [`prior_sensitivity()`](https://daikikumakura.github.io/bayespk/reference/prior_sensitivity.md)
  shows whether conclusions depend on the prior.
- **Diagnostics by default.** Warnings for divergences, R-hat, effective
  sample size and chains stuck in different modes.
- **Predictions for new regimens.** Simulate new subjects from the
  posterior, with uncertainty and between-subject variability.

## What it covers

Show details

- **Models:** linear 1- and 2-compartment; IV bolus, zero-order infusion
  (`RATE`) and first-order oral absorption. Parameters `CL`, `V` (or
  `CL`, `V1`, `Q`, `V2`) and `KA`; for oral dosing they are apparent
  values (divided by bioavailability).
- **Variability:** log-normal between-subject variability on any
  parameter, optionally correlated.
- **Covariates:** `CL ~ (WT / 70)^0.75` (fixed exponent),
  `CL ~ (WT / 70)^b_wt` (estimated), `CL ~ exp(b_age * (AGE - 40))`,
  `CL ~ (SEX == 1)^b_sex`.
- **Residual error:** additive, proportional, combined, or additive on
  the log scale.
- **Flip-flop:** in oral models, `ka_faster = TRUE` keeps the typical KA
  above the disposition rate when absorption is known to be faster than
  distribution (off by default).

Not in this version: user-written ODE models, Michaelis–Menten or
target-mediated elimination, inter-occasion variability, time-varying
covariates and pharmacodynamics.

## Getting help

Show details

Questions, bugs and requests for models: [GitHub
issues](https://github.com/DaikiKumakura/bayespk/issues).

## Validation and limitations

Details are in
[`inst/validation/README.md`](https://daikikumakura.github.io/bayespk/inst/validation/README.md).

- Closed-form concentrations agree with rxode2 ODE solutions (relative
  error \< 1e-8).
- Simulation-based calibration in four scenarios (100 to 400 replicates
  each): no test is below the correction for the number of parameters.
  Of 29 tests, two have p \< 0.05 (1.5 expected by chance). One is
  sigma_log with log-scale error and censoring (p = 0.014, true values
  ranked slightly low); the cause is unknown.
- On the public theophylline and warfarin data (nlmixr2data), posterior
  medians of typical values are within 1–10% of nlmixr2 FOCEI estimates.
- **Limitations.** Fits are slower than FOCEI: 38 s against 15 s on
  theophylline, and about 16 minutes on one core for a 40-subject
  2-compartment oral study. In sparse 2-compartment oral designs the
  variance parameters mix slowly. In 20 simulated studies, 11 fits had
  zero divergences and maximum R-hat ≤ 1.01, and the others had R-hat up
  to 1.023. Check `bpk_diagnostics(fit)` and `plot(fit, type = "trace")`
  before interpreting results.

## Citation

``` r

citation("bayespk")
```

Kumakura D (2026). bayespk: Bayesian Population Pharmacokinetics Without
Writing Stan. <https://doi.org/10.5281/zenodo.24325845>

## License

This project is licensed under GPL-3.0-or-later. See
[LICENSE.md](https://daikikumakura.github.io/bayespk/LICENSE.md) for the
license terms.
