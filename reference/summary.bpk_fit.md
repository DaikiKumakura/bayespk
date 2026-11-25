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
#> Chain 1: Gradient evaluation took 0.000194 seconds
#> Chain 1: 1000 transitions using 10 leapfrog steps per transition would take 1.94 seconds.
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
#> Chain 1:  Elapsed Time: 5.808 seconds (Warm-up)
#> Chain 1:                1.949 seconds (Sampling)
#> Chain 1:                7.757 seconds (Total)
#> Chain 1: 
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 2).
#> Chain 2: 
#> Chain 2: Gradient evaluation took 0.000136 seconds
#> Chain 2: 1000 transitions using 10 leapfrog steps per transition would take 1.36 seconds.
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
#> Chain 2:  Elapsed Time: 5.873 seconds (Warm-up)
#> Chain 2:                1.874 seconds (Sampling)
#> Chain 2:                7.747 seconds (Total)
#> Chain 2: 
#> Warning: Bulk Effective Samples Size (ESS) is too low, indicating posterior means and medians may be unreliable.
#> Running the chains for more iterations may help. See
#> https://mc-stan.org/misc/warnings.html#bulk-ess
#> Warning: Smallest effective sample size 197 (bulk) / 374 (tail) < 400.
summary(fit, probs = c(0.025, 0.5, 0.975))
#>    variable   mean     sd   q2.5    q50  q97.5  rhat ess_bulk ess_tail
#>          CL  2.850 0.1350  2.610  2.850  3.120 1.000     1450      850
#>           V 27.800 1.6300 24.700 27.800 31.200 1.000     1210      796
#>          KA  0.974 0.0867  0.827  0.966  1.160 1.010      801      776
#>    omega_CL  0.256 0.0411  0.186  0.253  0.354 1.010      197      374
#>     omega_V  0.301 0.0474  0.220  0.298  0.403 1.000      319      443
#>    omega_KA  0.367 0.0823  0.228  0.359  0.560 0.998      449      615
#>  sigma_prop  0.156 0.0116  0.134  0.156  0.181 1.000      536      604
# }
```
