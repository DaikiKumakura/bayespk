# Sampler diagnostics

Sampler diagnostics

## Usage

``` r
bpk_diagnostics(x)
```

## Arguments

- x:

  A `bpk_fit`.

## Value

A list with the number of divergent transitions, iterations at the
maximum tree depth, E-BFMI per chain, maximum R-hat and minimum bulk and
tail effective sample sizes of the population parameters.

## Examples

``` r
# \donttest{
mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
fit <- bpk_fit(mod, bpk_example, chains = 2, iter = 1000, seed = 1)
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 1).
#> Chain 1: 
#> Chain 1: Gradient evaluation took 0.000176 seconds
#> Chain 1: 1000 transitions using 10 leapfrog steps per transition would take 1.76 seconds.
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
#> Chain 1:  Elapsed Time: 3.177 seconds (Warm-up)
#> Chain 1:                1.057 seconds (Sampling)
#> Chain 1:                4.234 seconds (Total)
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
#> Chain 2:  Elapsed Time: 3.192 seconds (Warm-up)
#> Chain 2:                1.013 seconds (Sampling)
#> Chain 2:                4.205 seconds (Total)
#> Chain 2: 
#> Warning: Bulk Effective Samples Size (ESS) is too low, indicating posterior means and medians may be unreliable.
#> Running the chains for more iterations may help. See
#> https://mc-stan.org/misc/warnings.html#bulk-ess
#> Warning: Smallest effective sample size 197 (bulk) / 374 (tail) < 400.
bpk_diagnostics(fit)
#> $divergent
#> [1] 0
#> 
#> $max_treedepth
#> [1] 0
#> 
#> $ebfmi
#> [1] 0.5178749 0.5532899
#> 
#> $rhat_max
#> [1] 1.00662
#> 
#> $rhat_high
#> character(0)
#> 
#> $chains_apart
#> character(0)
#> 
#> $ess_bulk_min
#> [1] 196.6288
#> 
#> $ess_tail_min
#> [1] 374.4252
#> 
# }
```
