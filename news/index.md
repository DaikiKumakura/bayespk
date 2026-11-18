# Changelog

## bayespk 0.1.1

- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods:
  individual fits on a fine time grid, observed vs predicted, trace
  plots, and predicted concentrations for new regimens with `compare =`
  for two regimens. All use Okabe-Ito colours.
- [`predict()`](https://rdrr.io/r/stats/predict.html) without `regimen`
  accepts `times` to return each subject’s prediction on a time grid.
  Predictions are returned as class `bpk_prediction` (a data frame).
- [`prior_sensitivity()`](https://daikikumakura.github.io/bayespk/reference/prior_sensitivity.md)
  reports parameters by their names (`CL`, `b_wt`, `omega_V`, …).
- New simulated data set `bpk_example`, used by every example.
- Three vignettes with precomputed results and figures: getting started,
  covariates and informative priors, two-compartment models and regimen
  comparison.
- `citation("bayespk")`, issue templates, and a README with figures and
  results.

## bayespk 0.1.0

- First release: 1- and 2-compartment linear models (IV bolus, infusion,
  first-order oral), closed-form solutions, log-normal between-subject
  variability (optionally correlated), covariate formulas, four residual
  error models, weakly informative default priors, diagnostics with
  warnings, predictions for new regimens, prior sensitivity.
- `pk_model(ka_faster = TRUE)` constrains the typical KA above the
  disposition rate to remove flip-flop modes (off by default).
- Random effects are sampled as a sample mean plus Helmert deviations,
  which removes the correlation between typical values and the mean
  random effect.
