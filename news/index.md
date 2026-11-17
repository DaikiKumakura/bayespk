# Changelog

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
