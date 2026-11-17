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
if (requireNamespace("nlmixr2data", quietly = TRUE)) {
d <- nlmixr2data::theo_sd
mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
fit <- bpk_fit(mod, d, chains = 2, iter = 1000, seed = 1)
summary(fit, probs = c(0.025, 0.5, 0.975))
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
#> Chain 1:  Elapsed Time: 2.156 seconds (Warm-up)
#> Chain 1:                1.046 seconds (Sampling)
#> Chain 1:                3.202 seconds (Total)
#> Chain 1: 
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 2).
#> Chain 2: 
#> Chain 2: Gradient evaluation took 9.8e-05 seconds
#> Chain 2: 1000 transitions using 10 leapfrog steps per transition would take 0.98 seconds.
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
#> Chain 2:  Elapsed Time: 2.02 seconds (Warm-up)
#> Chain 2:                1.045 seconds (Sampling)
#> Chain 2:                3.065 seconds (Total)
#> Chain 2: 
#> Warning: Bulk Effective Samples Size (ESS) is too low, indicating posterior means and medians may be unreliable.
#> Running the chains for more iterations may help. See
#> https://mc-stan.org/misc/warnings.html#bulk-ess
#> Warning: R-hat > 1.01 (maximum 1.014) for omega_CL; chains have not mixed. Run longer (iter) before using the results.
#> Warning: Smallest effective sample size 200 (bulk) / 318 (tail) < 400.
#>    variable   mean     sd    q2.5    q50  q97.5  rhat ess_bulk ess_tail
#>          CL  2.750 0.2470  2.2500  2.750  3.240 0.999     1590      657
#>           V 32.400 1.7500 29.2000 32.300 36.100 1.000     1390      703
#>          KA  1.580 0.3920  1.0100  1.540  2.450 1.000     1810      691
#>    omega_CL  0.292 0.0809  0.1750  0.277  0.494 1.010      200      408
#>     omega_V  0.144 0.0519  0.0519  0.139  0.260 1.000      295      318
#>    omega_KA  0.754 0.2080  0.4390  0.725  1.270 1.010      269      486
#>  sigma_prop  0.163 0.0134  0.1410  0.162  0.192 1.000      484      609
# }
```
