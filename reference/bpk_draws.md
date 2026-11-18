# Posterior draws of population parameters

Posterior draws of population parameters

## Usage

``` r
bpk_draws(x)
```

## Arguments

- x:

  A `bpk_fit`.

## Value

A `draws_df` (posterior package) with typical values on the natural
scale, estimated covariate effects, standard deviations of
between-subject variability (log scale), correlations and residual
error.

## Examples

``` r
# \donttest{
mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
fit <- bpk_fit(mod, bpk_example, chains = 2, iter = 1000, seed = 1)
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 1).
#> Chain 1: 
#> Chain 1: Gradient evaluation took 0.000186 seconds
#> Chain 1: 1000 transitions using 10 leapfrog steps per transition would take 1.86 seconds.
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
#> Chain 1:  Elapsed Time: 9.495 seconds (Warm-up)
#> Chain 1:                3.08 seconds (Sampling)
#> Chain 1:                12.575 seconds (Total)
#> Chain 1: 
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 2).
#> Chain 2: 
#> Chain 2: Gradient evaluation took 0.000175 seconds
#> Chain 2: 1000 transitions using 10 leapfrog steps per transition would take 1.75 seconds.
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
#> Chain 2:  Elapsed Time: 10.573 seconds (Warm-up)
#> Chain 2:                3.376 seconds (Sampling)
#> Chain 2:                13.949 seconds (Total)
#> Chain 2: 
#> Warning: Smallest effective sample size 271 (bulk) / 333 (tail) < 400.
head(posterior::as_draws_df(bpk_draws(fit)))
#> # A draws_df: 6 iterations, 1 chains, and 7 variables
#>    CL  V   KA omega_CL omega_V omega_KA sigma_prop
#> 1 3.1 28 1.21     0.20    0.29     0.37       0.15
#> 2 2.8 27 0.80     0.21    0.30     0.35       0.14
#> 3 3.0 29 1.12     0.23    0.32     0.32       0.14
#> 4 2.7 28 0.98     0.20    0.29     0.42       0.16
#> 5 3.2 28 0.99     0.22    0.33     0.37       0.14
#> 6 3.3 27 0.95     0.24    0.33     0.35       0.14
#> # ... hidden reserved variables {'.chain', '.iteration', '.draw'}
# }
```
