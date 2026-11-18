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
#> Chain 1: Gradient evaluation took 0.000189 seconds
#> Chain 1: 1000 transitions using 10 leapfrog steps per transition would take 1.89 seconds.
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
#> Chain 1:  Elapsed Time: 9.455 seconds (Warm-up)
#> Chain 1:                3.08 seconds (Sampling)
#> Chain 1:                12.535 seconds (Total)
#> Chain 1: 
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 2).
#> Chain 2: 
#> Chain 2: Gradient evaluation took 0.000176 seconds
#> Chain 2: 1000 transitions using 10 leapfrog steps per transition would take 1.76 seconds.
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
#> Chain 2:  Elapsed Time: 10.528 seconds (Warm-up)
#> Chain 2:                3.367 seconds (Sampling)
#> Chain 2:                13.895 seconds (Total)
#> Chain 2: 
#> Warning: Smallest effective sample size 271 (bulk) / 333 (tail) < 400.
summary(fit)
#>    variable   mean     sd     q5    q50    q95  rhat ess_bulk ess_tail
#>          CL  2.860 0.1380  2.640  2.860  3.080 1.000     1250      756
#>           V 27.800 1.7900 25.000 27.700 30.900 1.000     1390      625
#>          KA  0.982 0.0983  0.836  0.974  1.140 1.000     1370      877
#>    omega_CL  0.260 0.0413  0.198  0.255  0.335 1.000      271      333
#>     omega_V  0.299 0.0500  0.229  0.292  0.391 1.010      373      538
#>    omega_KA  0.371 0.0909  0.240  0.361  0.537 1.000      425      447
#>  sigma_prop  0.156 0.0115  0.138  0.156  0.177 0.999      624      799
# }
```
