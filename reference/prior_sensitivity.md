# Prior sensitivity by power-scaling

Calls
[`priorsense::powerscale_sensitivity()`](https://mc-stan.org/priorsense/reference/powerscale-sensitivity.html)
on the population parameters.

## Usage

``` r
prior_sensitivity(x, ...)
```

## Arguments

- x:

  A `bpk_fit`.

- ...:

  Passed to
  [`priorsense::powerscale_sensitivity()`](https://mc-stan.org/priorsense/reference/powerscale-sensitivity.html).

## Value

The result of
[`priorsense::powerscale_sensitivity()`](https://mc-stan.org/priorsense/reference/powerscale-sensitivity.html).

## Examples

``` r
# \donttest{
if (requireNamespace("nlmixr2data", quietly = TRUE)) {
d <- nlmixr2data::theo_sd
mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
fit <- bpk_fit(mod, d, chains = 2, iter = 1000, seed = 1)
if (requireNamespace("priorsense", quietly = TRUE)) prior_sensitivity(fit)
}
#> 12 observation(s) at or before the first dose were dropped.
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 1).
#> Chain 1: 
#> Chain 1: Gradient evaluation took 0.000138 seconds
#> Chain 1: 1000 transitions using 10 leapfrog steps per transition would take 1.38 seconds.
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
#> Chain 1:  Elapsed Time: 2.161 seconds (Warm-up)
#> Chain 1:                1.041 seconds (Sampling)
#> Chain 1:                3.202 seconds (Total)
#> Chain 1: 
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 2).
#> Chain 2: 
#> Chain 2: Gradient evaluation took 8.8e-05 seconds
#> Chain 2: 1000 transitions using 10 leapfrog steps per transition would take 0.88 seconds.
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
#> Chain 2:  Elapsed Time: 2.032 seconds (Warm-up)
#> Chain 2:                1.044 seconds (Sampling)
#> Chain 2:                3.076 seconds (Total)
#> Chain 2: 
#> Warning: Bulk Effective Samples Size (ESS) is too low, indicating posterior means and medians may be unreliable.
#> Running the chains for more iterations may help. See
#> https://mc-stan.org/misc/warnings.html#bulk-ess
#> Warning: R-hat > 1.01 (maximum 1.014) for omega_CL; chains have not mixed. Run longer (iter) before using the results.
#> Warning: Smallest effective sample size 200 (bulk) / 318 (tail) < 400.
#> Sensitivity based on cjs_dist
#> Prior selection: all priors
#> Likelihood selection: all data
#> 
#>      variable prior likelihood diagnosis
#>  log_theta[1] 0.003      0.048         -
#>  log_theta[2] 0.002      0.146         -
#>  log_theta[3] 0.010      0.093         -
#>      omega[1] 0.008      0.120         -
#>      omega[2] 0.005      0.356         -
#>      omega[3] 0.048      0.136         -
#>      sigma[1] 0.002      0.777         -
# }
```
