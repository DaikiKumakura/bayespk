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
#> Chain 1: Gradient evaluation took 0.0001 seconds
#> Chain 1: 1000 transitions using 10 leapfrog steps per transition would take 1 seconds.
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
#> Chain 1:  Elapsed Time: 3.591 seconds (Warm-up)
#> Chain 1:                1.193 seconds (Sampling)
#> Chain 1:                4.784 seconds (Total)
#> Chain 1: 
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 2).
#> Chain 2: 
#> Chain 2: Gradient evaluation took 7.6e-05 seconds
#> Chain 2: 1000 transitions using 10 leapfrog steps per transition would take 0.76 seconds.
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
#> Chain 2:  Elapsed Time: 3.486 seconds (Warm-up)
#> Chain 2:                1.084 seconds (Sampling)
#> Chain 2:                4.57 seconds (Total)
#> Chain 2: 
#> Warning: Bulk Effective Samples Size (ESS) is too low, indicating posterior means and medians may be unreliable.
#> Running the chains for more iterations may help. See
#> https://mc-stan.org/misc/warnings.html#bulk-ess
#> Warning: Smallest effective sample size 197 (bulk) / 374 (tail) < 400.
head(posterior::as_draws_df(bpk_draws(fit)))
#> # A draws_df: 6 iterations, 1 chains, and 7 variables
#>    CL  V   KA omega_CL omega_V omega_KA sigma_prop
#> 1 2.8 28 0.91     0.24    0.26     0.30       0.15
#> 2 2.8 27 0.94     0.25    0.30     0.37       0.15
#> 3 2.9 29 0.88     0.26    0.27     0.37       0.16
#> 4 2.8 28 0.87     0.21    0.26     0.32       0.14
#> 5 2.7 29 0.89     0.28    0.26     0.28       0.15
#> 6 3.0 27 1.16     0.29    0.27     0.45       0.14
#> # ... hidden reserved variables {'.chain', '.iteration', '.draw'}
# }
```
