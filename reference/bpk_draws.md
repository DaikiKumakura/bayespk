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
if (requireNamespace("nlmixr2data", quietly = TRUE)) {
d <- nlmixr2data::theo_sd
mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
fit <- bpk_fit(mod, d, chains = 2, iter = 1000, seed = 1)
head(posterior::as_draws_df(bpk_draws(fit)))
}
#> 12 observation(s) at or before the first dose were dropped.
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 1).
#> Chain 1: 
#> Chain 1: Gradient evaluation took 0.000126 seconds
#> Chain 1: 1000 transitions using 10 leapfrog steps per transition would take 1.26 seconds.
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
#> Chain 1:  Elapsed Time: 3.545 seconds (Warm-up)
#> Chain 1:                1.717 seconds (Sampling)
#> Chain 1:                5.262 seconds (Total)
#> Chain 1: 
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 2).
#> Chain 2: 
#> Chain 2: Gradient evaluation took 0.000115 seconds
#> Chain 2: 1000 transitions using 10 leapfrog steps per transition would take 1.15 seconds.
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
#> Chain 2:  Elapsed Time: 3.328 seconds (Warm-up)
#> Chain 2:                1.725 seconds (Sampling)
#> Chain 2:                5.053 seconds (Total)
#> Chain 2: 
#> Warning: Bulk Effective Samples Size (ESS) is too low, indicating posterior means and medians may be unreliable.
#> Running the chains for more iterations may help. See
#> https://mc-stan.org/misc/warnings.html#bulk-ess
#> Warning: R-hat > 1.01 (maximum 1.014) for omega_CL; chains have not mixed. Run longer (iter) before using the results.
#> Warning: Smallest effective sample size 200 (bulk) / 318 (tail) < 400.
#> # A draws_df: 6 iterations, 1 chains, and 7 variables
#>    CL  V  KA omega_CL omega_V omega_KA sigma_prop
#> 1 2.6 31 1.7     0.36   0.109     0.86       0.15
#> 2 2.4 34 1.5     0.32   0.222     0.83       0.17
#> 3 2.4 32 1.6     0.32   0.199     0.79       0.16
#> 4 2.8 32 1.3     0.28   0.079     0.74       0.17
#> 5 2.9 34 1.8     0.25   0.121     0.70       0.17
#> 6 2.8 34 1.2     0.26   0.107     0.57       0.15
#> # ... hidden reserved variables {'.chain', '.iteration', '.draw'}
# }
```
