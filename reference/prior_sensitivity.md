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
mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
fit <- bpk_fit(mod, bpk_example, chains = 2, iter = 1000, seed = 1)
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 1).
#> Chain 1: 
#> Chain 1: Gradient evaluation took 9.9e-05 seconds
#> Chain 1: 1000 transitions using 10 leapfrog steps per transition would take 0.99 seconds.
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
#> Chain 1:  Elapsed Time: 3.386 seconds (Warm-up)
#> Chain 1:                1.126 seconds (Sampling)
#> Chain 1:                4.512 seconds (Total)
#> Chain 1: 
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 2).
#> Chain 2: 
#> Chain 2: Gradient evaluation took 7.8e-05 seconds
#> Chain 2: 1000 transitions using 10 leapfrog steps per transition would take 0.78 seconds.
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
#> Chain 2:  Elapsed Time: 3.449 seconds (Warm-up)
#> Chain 2:                1.094 seconds (Sampling)
#> Chain 2:                4.543 seconds (Total)
#> Chain 2: 
#> Warning: Bulk Effective Samples Size (ESS) is too low, indicating posterior means and medians may be unreliable.
#> Running the chains for more iterations may help. See
#> https://mc-stan.org/misc/warnings.html#bulk-ess
#> Warning: Smallest effective sample size 197 (bulk) / 374 (tail) < 400.
if (requireNamespace("priorsense", quietly = TRUE)) prior_sensitivity(fit)
#> Sensitivity based on cjs_dist
#> Prior selection: all priors
#> Likelihood selection: all data
#> 
#>    variable prior likelihood diagnosis
#>          CL 0.001      0.069         -
#>           V 0.000      0.098         -
#>          KA 0.002      0.160         -
#>    omega_CL 0.002      0.159         -
#>     omega_V 0.003      0.261         -
#>    omega_KA 0.008      0.249         -
#>  sigma_prop 0.001      1.085         -
# }
```
