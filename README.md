# bayespk

<!-- badges: start -->
[![R-universe](https://daikikumakura.r-universe.dev/badges/bayespk)](https://daikikumakura.r-universe.dev/bayespk)
[![R-CMD-check](https://github.com/DaikiKumakura/bayespk/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/DaikiKumakura/bayespk/actions/workflows/R-CMD-check.yaml)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.24325845.svg)](https://doi.org/10.5281/zenodo.24325845)
<!-- badges: end -->

Bayesian population pharmacokinetics in R **without writing Stan**.

## Installation

From R-universe (binaries for Windows, macOS and Linux):

```r
install.packages("bayespk", repos = c("https://daikikumakura.r-universe.dev", "https://cloud.r-project.org"))
```

## Quick start

```r
library(bayespk)

mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"), error = "proportional")
fit <- bpk_fit(mod, bpk_example, chains = 4, cores = 4, seed = 1)   # 30 simulated subjects
summary(fit)

plot(fit)   # individual fits
```

## Documentation

[Package website](https://daikikumakura.github.io/bayespk/) · [Function reference](https://daikikumakura.github.io/bayespk/reference/) · [Changelog](https://daikikumakura.github.io/bayespk/news/) · [Releases](https://github.com/DaikiKumakura/bayespk/releases) · [R-universe](https://daikikumakura.r-universe.dev/bayespk) · [Usage guide](https://github.com/DaikiKumakura/bayespk/blob/main/README-GUIDE.md)

## Validation and limitations

- **Validation:** Compared closed-form PK with rxode2, ran simulation-based calibration, and compared fits on public theophylline and warfarin data.
- **Results:** The concentration checks agreed within 1e-8 relative error; typical parameter estimates differed from FOCEI by about 1–10%.
- **Limitations:** Sparse oral two-compartment fits can mix slowly. The log-error and censoring scenario showed a small rank imbalance.
- **Reproduction:** [inst/validation/README.md](https://github.com/DaikiKumakura/bayespk/blob/main/inst/validation/README.md).

## Citation

Kumakura, D. (2026). *bayespk: Bayesian Population Pharmacokinetics Without Writing Stan* [Software]. [DOI: 10.5281/zenodo.24325845](https://doi.org/10.5281/zenodo.24325845).

Citation metadata: [CITATION.cff](CITATION.cff).

## License

This project is licensed under GPL-3.0-or-later. See [LICENSE.md](LICENSE.md) for the license terms.
