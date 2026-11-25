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
mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
fit <- bpk_fit(mod, bpk_example, chains = 2, iter = 1000, seed = 1)
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 1).
#> Chain 1: 
#> Chain 1: Gradient evaluation took 8.9e-05 seconds
#> Chain 1: 1000 transitions using 10 leapfrog steps per transition would take 0.89 seconds.
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
#> Chain 1:  Elapsed Time: 3.161 seconds (Warm-up)
#> Chain 1:                1.068 seconds (Sampling)
#> Chain 1:                4.229 seconds (Total)
#> Chain 1: 
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 2).
#> Chain 2: 
#> Chain 2: Gradient evaluation took 6.8e-05 seconds
#> Chain 2: 1000 transitions using 10 leapfrog steps per transition would take 0.68 seconds.
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
#> Chain 2:  Elapsed Time: 3.25 seconds (Warm-up)
#> Chain 2:                1.03 seconds (Sampling)
#> Chain 2:                4.28 seconds (Total)
#> Chain 2: 
#> Warning: Bulk Effective Samples Size (ESS) is too low, indicating posterior means and medians may be unreliable.
#> Running the chains for more iterations may help. See
#> https://mc-stan.org/misc/warnings.html#bulk-ess
#> Warning: Smallest effective sample size 197 (bulk) / 374 (tail) < 400.
summary(fit)
#>    variable   mean     sd     q5    q50    q95  rhat ess_bulk ess_tail
#>          CL  2.850 0.1350  2.640  2.850  3.080 1.000     1450      850
#>           V 27.800 1.6300 25.200 27.800 30.600 1.000     1210      796
#>          KA  0.974 0.0867  0.842  0.966  1.130 1.010      801      776
#>    omega_CL  0.256 0.0411  0.197  0.253  0.328 1.010      197      374
#>     omega_V  0.301 0.0474  0.229  0.298  0.379 1.000      319      443
#>    omega_KA  0.367 0.0823  0.246  0.359  0.515 0.998      449      615
#>  sigma_prop  0.156 0.0116  0.138  0.156  0.176 1.000      536      604
# }
```
