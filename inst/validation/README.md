# Validation of bayespk 0.2.0

All results below were produced with the 0.1.0 code on Windows 11 (AMD Ryzen 5 8640U, 15 GB RAM), R 4.5.3 and rstan 2.32.7. Scripts run from the package root, for example `Rscript inst/validation/sbc.R 1cmt_oral 200 8`. Result files are in `results/`.

## Closed-form solutions

`tests/testthat/test-closed-form.R` compares `pk_conc()` with rxode2 ODE solutions for every structure and route, including KA equal to a disposition rate. Every comparison has relative error < 1e-8. On the theophylline design the largest relative error is 3.07e-13.

## Simulation-based calibration (`sbc.R`)

Parameters are drawn from the prior, data are simulated, and the model is fitted with the same prior (2 chains × 1000 iterations; ranks among 100 thinned draws). The table gives chi-square tests of rank uniformity in 10 bins, per parameter.

| Scenario | Replicates | p-values (range over parameters) |
| --- | --- | --- |
| 1-cmt oral, 12 subjects, IIV on CL, V, KA | 200 | 0.04 (omega_V) – 1.00 |
| 1-cmt oral, 20 subjects, estimated weight exponent on V | 200 | 0.086 – 0.83 (b_wt 0.83) |
| 2-cmt infusion, 20 subjects, IIV on CL, V1 | 100 | 0.076 – 0.87 |
| 1-cmt oral, 16 subjects, log-scale error, 0.5 mg/L limit with M3 censoring | 400 (two runs of 200) | 0.014 (sigma_log) – 0.97 |

Across the 29 tests of the final runs, 2 gave p < 0.05 (about 1.5 expected by chance): omega_V in the 1-cmt oral scenario (0.039) and sigma_log in the pooled log-error scenario (0.014). Neither is below the Bonferroni threshold for the number of parameters in its scenario (0.05/7). The low p-values change from run to run: omega_V was 0.38 and 0.21 in earlier runs of the 1-cmt oral scenario, and the first 200 replicates of the log-error scenario had p = 0.011 for CL and 0.017 for sigma_log, while the next 200 had 0.42 and 0.37. For sigma_log, the mean rank fraction is 0.470 in the pooled 400 (a standard error of 0.014 for uniform ranks), and 0.441 when the true sigma_log is in the lowest third. The cause has not been found. These short SBC chains often have R-hat > 1.01.

## Public data compared with nlmixr2 FOCEI (`theophylline.R`, `warfarin.R`)

| Data | Model | Typical values: bayespk median / FOCEI | Run time (bayespk vs FOCEI) |
| --- | --- | --- | --- |
| theophylline (12 subjects) | 1-cmt oral, proportional error | CL 0.98, V 1.00, KA 1.06 | 37.5 s (4 chains × 2000, 4 cores) vs 14.5 s |
| warfarin PK (32 subjects) | 1-cmt oral, combined error | CL 0.99, V 0.99, KA 1.10 | 92 s vs 13 s |

Between-subject SDs are 4–16% higher than FOCEI, as expected when a posterior median of a variance is compared with a maximum-likelihood estimate in small samples. Both fits had 0 divergences and R-hat ≤ 1.01.

## Data features

The steady-state closed forms equal the sum of 400 earlier doses to a relative tolerance of 1e-8 for 7 structure, route and rate combinations, including KA equal to a disposition rate, and agree with rxode2 for a 1-compartment oral dose. Censored (M3) rows give the log of the normal CDF at the limit (checked against `pnorm`). With log-scale error, versions before 0.2.0 compared the untransformed DV with log concentrations; this was fixed in 0.2.0 and is covered by a recovery test.

## Two-compartment oral simulations (`coverage_2cmt_oral.R`)

The design has 40 subjects: half rich, half sparse sampling. IIV is on CL, V1 and KA; CL has a fixed weight effect and V1 an estimated one; the error is proportional. The fits use `ka_faster = TRUE`, 4 chains × 1500 iterations and adapt_delta 0.95, with 20 replicates.

- 90% interval coverage was 0.85–1.00 for all 10 parameters.
- 1 of 20 fits had divergences; the maximum R-hat was 1.009 in the median fit and 1.023 at most, above 1.01 in 9 fits.
- Each fit took about 16 minutes on one core.
- The weight exponent on V1 is shrunk toward its default prior N(0, 1): the median relative error was −0.24. SBC shows the covariate code is calibrated, so this is due to how little the design says about V1.

## Known limitations

- **Flip-flop.** In 2-cmt oral models without `ka_faster`, chains can settle in two modes in which KA and the fast disposition rate swap. `bpk_fit()` detects this and warns. Use `ka_faster = TRUE` only when absorption is known to be faster than distribution.
- **Variance parameters mix slowly in sparse 2-cmt oral designs.** The maximum R-hat was at most 1.023, above 1.01 in 9 of 20 replicates at 1500 iterations and 5 of 8 at 2000. Longer chains do not remove it. The fit warns when R-hat > 1.01.
- **Speed.** Fits are slower than FOCEI: about 2.4× on theophylline, and minutes per fit for 2-cmt oral with 40 subjects.
