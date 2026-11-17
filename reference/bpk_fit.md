# Fit a Bayesian population pharmacokinetic model

Samples the posterior with Stan (NUTS) using a precompiled closed-form
model. The data are a NONMEM-style data frame used as is.

## Usage

``` r
bpk_fit(
  model,
  data,
  priors = NULL,
  chains = 4,
  iter = 2000,
  warmup = floor(iter/2),
  cores = getOption("mc.cores", 1L),
  seed = sample.int(.Machine$integer.max, 1),
  adapt_delta = 0.9,
  prior_only = FALSE,
  ...
)
```

## Arguments

- model:

  A model from
  [`pk_model()`](https://daikikumakura.github.io/bayespk/reference/pk_model.md).

- data:

  NONMEM-style data frame.

- priors:

  Priors from
  [`pk_priors()`](https://daikikumakura.github.io/bayespk/reference/pk_priors.md);
  unspecified ones get defaults.

- chains, iter, warmup, cores, seed:

  Passed to
  [`rstan::sampling()`](https://mc-stan.org/rstan/reference/stanmodel-method-sampling.html).

- adapt_delta:

  Target acceptance rate of NUTS.

- prior_only:

  Logical; sample from the prior only (ignores `DV`).

- ...:

  Further arguments to
  [`rstan::sampling()`](https://mc-stan.org/rstan/reference/stanmodel-method-sampling.html).

## Value

An object of class `bpk_fit`.

## Details

Data columns (case-insensitive): `ID`, `TIME`, `DV`, `AMT` (required);
`EVID`, `MDV`, `RATE`, `ADDL`, `II` (optional) and any covariates used
in the model. `"."` is read as missing. Doses are records with
`EVID == 1` (or `AMT > 0` when `EVID` is absent); observations are
records with `EVID == 0`, `MDV != 1` and a non-missing `DV`.
Observations at or before the first dose of a subject are dropped with a
message. Not supported in this version: steady-state records, reset
events, modelled rates, time-varying covariates and below-quantification
records.

## Examples

``` r
# \donttest{
if (requireNamespace("nlmixr2data", quietly = TRUE)) {
d <- nlmixr2data::theo_sd
mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
fit <- bpk_fit(mod, d, chains = 2, iter = 1000, seed = 1)
summary(fit)
}
#> 12 observation(s) at or before the first dose were dropped.
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 1).
#> Chain 1: 
#> Chain 1: Gradient evaluation took 0.000116 seconds
#> Chain 1: 1000 transitions using 10 leapfrog steps per transition would take 1.16 seconds.
#> Chain 1: Adjust your expectations accordingly!
#> Chain 1: 
#> Chain 1: 
#> Chain 1: Iteration:   1 / 1000 [  0%]  (Warmup)
#> Chain 1: Iteration: 100 / 1000 [ 10%]  (Warmup)
#> Chain 1: Iteration: 200 / 1000 [ 20%]  (Warmup)
#> Chain 1: Iteration: 300 / 1000 [ 30%]  (Warmup)
#> Chain 1: Iteration: 400 / 1000 [ 40%]  (Warmup)
#> Chain 1: Iteration: 500 / 1000 [ 50%]  (Warmup)
#> Chain 1: Iteration: 501 / 1000 [ 50%]  (Sampling)
#> Chain 1: Iteration: 600 / 1000 [ 60%]  (Sampling)
#> Chain 1: Iteration: 700 / 1000 [ 70%]  (Sampling)
#> Chain 1: Iteration: 800 / 1000 [ 80%]  (Sampling)
#> Chain 1: Iteration: 900 / 1000 [ 90%]  (Sampling)
#> Chain 1: Iteration: 1000 / 1000 [100%]  (Sampling)
#> Chain 1: 
#> Chain 1:  Elapsed Time: 2.173 seconds (Warm-up)
#> Chain 1:                1.043 seconds (Sampling)
#> Chain 1:                3.216 seconds (Total)
#> Chain 1: 
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 2).
#> Chain 2: 
#> Chain 2: Gradient evaluation took 0.000111 seconds
#> Chain 2: 1000 transitions using 10 leapfrog steps per transition would take 1.11 seconds.
#> Chain 2: Adjust your expectations accordingly!
#> Chain 2: 
#> Chain 2: 
#> Chain 2: Iteration:   1 / 1000 [  0%]  (Warmup)
#> Chain 2: Iteration: 100 / 1000 [ 10%]  (Warmup)
#> Chain 2: Iteration: 200 / 1000 [ 20%]  (Warmup)
#> Chain 2: Iteration: 300 / 1000 [ 30%]  (Warmup)
#> Chain 2: Iteration: 400 / 1000 [ 40%]  (Warmup)
#> Chain 2: Iteration: 500 / 1000 [ 50%]  (Warmup)
#> Chain 2: Iteration: 501 / 1000 [ 50%]  (Sampling)
#> Chain 2: Iteration: 600 / 1000 [ 60%]  (Sampling)
#> Chain 2: Iteration: 700 / 1000 [ 70%]  (Sampling)
#> Chain 2: Iteration: 800 / 1000 [ 80%]  (Sampling)
#> Chain 2: Iteration: 900 / 1000 [ 90%]  (Sampling)
#> Chain 2: Iteration: 1000 / 1000 [100%]  (Sampling)
#> Chain 2: 
#> Chain 2:  Elapsed Time: 2.03 seconds (Warm-up)
#> Chain 2:                1.045 seconds (Sampling)
#> Chain 2:                3.075 seconds (Total)
#> Chain 2: 
#> Warning: Bulk Effective Samples Size (ESS) is too low, indicating posterior means and medians may be unreliable.
#> Running the chains for more iterations may help. See
#> https://mc-stan.org/misc/warnings.html#bulk-ess
#> Warning: R-hat > 1.01 (maximum 1.014) for omega_CL; chains have not mixed. Run longer (iter) before using the results.
#> Warning: Smallest effective sample size 200 (bulk) / 318 (tail) < 400.
#>    variable   mean     sd      q5    q50    q95  rhat ess_bulk ess_tail
#>          CL  2.750 0.2470  2.3700  2.750  3.160 0.999     1590      657
#>           V 32.400 1.7500 29.7000 32.300 35.300 1.000     1390      703
#>          KA  1.580 0.3920  1.0900  1.540  2.260 1.000     1810      691
#>    omega_CL  0.292 0.0809  0.1890  0.277  0.444 1.010      200      408
#>     omega_V  0.144 0.0519  0.0672  0.139  0.237 1.000      295      318
#>    omega_KA  0.754 0.2080  0.4820  0.725  1.130 1.010      269      486
#>  sigma_prop  0.163 0.0134  0.1430  0.162  0.186 1.000      484      609
# }
```
