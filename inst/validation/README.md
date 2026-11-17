# Validation of bayespk 0.1.0

All results below were produced with the 0.1.0 code on Windows 11 (AMD Ryzen 5 8640U, 15 GB RAM), R 4.5.3 and rstan 2.32.7. Scripts run from the package root, for example `Rscript inst/validation/sbc.R 1cmt_oral 200 8`. Result files are in `results/`.

## Closed-form solutions

`tests/testthat/test-closed-form.R` compares `pk_conc()` with rxode2 ODE solutions for every structure and route, including KA equal to a disposition rate. Every comparison has relative error < 1e-8. On the theophylline design the largest relative error is 3.07e-13.

## Simulation-based calibration (`sbc.R`)

Parameters are drawn from the prior, data are simulated, and the model is fitted with the same prior (2 chains × 1000 iterations; ranks among 100 thinned draws). The table gives chi-square tests of rank uniformity in 10 bins.

| Scenario | Replicates | p-values (range over parameters) |
| --- | --- | --- |
| 1-cmt oral, 12 subjects, IIV on CL, V, KA | 200 | 0.18 – 0.66 |
| 1-cmt oral, 20 subjects, estimated weight exponent on V | 200 | 0.086 – 0.83 (b_wt 0.83) |
| 2-cmt infusion, 20 subjects, IIV on CL, V1 | 100 | 0.012 (V2) – 0.76 |

No p-value is below the Bonferroni threshold for the number of parameters (0.05/7 or 0.05/8). In an earlier run of the 2-cmt scenario the lowest p-value was for a different parameter (V1), so the low V2 value is probably chance. These short SBC chains often have R-hat > 1.01.

## Public data compared with nlmixr2 FOCEI (`theophylline.R`, `warfarin.R`)

| Data | Model | Typical values: bayespk median / FOCEI | Run time (bayespk vs FOCEI) |
| --- | --- | --- | --- |
| theophylline (12 subjects) | 1-cmt oral, proportional error | CL 0.99, V 1.00, KA 1.05 | 24 s (4 chains × 2000, 4 cores) vs 10 s |
| warfarin PK (32 subjects) | 1-cmt oral, combined error | CL 0.99, V 0.99, KA 1.10 | not measured on an idle machine |

Between-subject SDs are 4–16% higher than FOCEI, as expected when a posterior median of a variance is compared with a maximum-likelihood estimate in small samples. Both fits had 0 divergences and R-hat ≤ 1.01.

## Two-compartment oral simulations (`coverage_2cmt_oral.R`)

The design has 40 subjects: half rich, half sparse sampling. IIV is on CL, V1 and KA; CL has a fixed weight effect and V1 an estimated one; the error is proportional. The fits use `ka_faster = TRUE`, 4 chains × 1500 iterations and adapt_delta 0.95, with 20 replicates.

- 90% interval coverage was 0.85–0.95 for all 10 parameters.
- There were no divergences.
- Each fit took about 17 minutes on one core.
- The weight exponent on V1 is shrunk toward its default prior N(0, 1): the median relative error was −0.24. SBC shows the covariate code is calibrated, so this is due to how little the design says about V1.

## Known limitations

- **Flip-flop.** In 2-cmt oral models without `ka_faster`, chains can settle in two modes in which KA and the fast disposition rate swap. `bpk_fit()` detects this and warns. Use `ka_faster = TRUE` only when absorption is known to be faster than distribution.
- **Variance parameters mix slowly in sparse 2-cmt oral designs.** The maximum R-hat was 1.006–1.033, above 1.01 in 12/20 replicates at 1500 iterations and 5/8 at 2000. Longer chains do not remove it. The fit warns when R-hat > 1.01.
- **Speed.** Fits are slower than FOCEI: about 2.4× on theophylline, and minutes per fit for 2-cmt oral with 40 subjects.
