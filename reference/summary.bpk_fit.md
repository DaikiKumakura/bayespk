# Summarise a fit

Summarise a fit

## Usage

``` r
# S3 method for class 'bpk_fit'
summary(object, probs = c(0.05, 0.5, 0.95), ...)
```

## Arguments

- object:

  A `bpk_fit`.

- probs:

  Quantiles to report.

- ...:

  Unused.

## Value

A data frame of posterior summaries and convergence diagnostics.

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
#> Chain 1:  Elapsed Time: 9.501 seconds (Warm-up)
#> Chain 1:                3.107 seconds (Sampling)
#> Chain 1:                12.608 seconds (Total)
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
#> Chain 2:  Elapsed Time: 10.576 seconds (Warm-up)
#> Chain 2:                3.378 seconds (Sampling)
#> Chain 2:                13.954 seconds (Total)
#> Chain 2: 
#> Warning: Smallest effective sample size 271 (bulk) / 333 (tail) < 400.
summary(fit, probs = c(0.025, 0.5, 0.975))
#>    variable   mean     sd   q2.5    q50  q97.5  rhat ess_bulk ess_tail
#>          CL  2.860 0.1380  2.580  2.860  3.130 1.000     1250      756
#>           V 27.800 1.7900 24.600 27.700 31.700 1.000     1390      625
#>          KA  0.982 0.0983  0.813  0.974  1.190 1.000     1370      877
#>    omega_CL  0.260 0.0413  0.191  0.255  0.354 1.000      271      333
#>     omega_V  0.299 0.0500  0.219  0.292  0.414 1.010      373      538
#>    omega_KA  0.371 0.0909  0.226  0.361  0.563 1.000      425      447
#>  sigma_prop  0.156 0.0115  0.136  0.156  0.181 0.999      624      799
# }
```
