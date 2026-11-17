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
if (requireNamespace("nlmixr2data", quietly = TRUE)) {
d <- nlmixr2data::theo_sd
mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
fit <- bpk_fit(mod, d, chains = 2, iter = 1000, seed = 1)
bpk_diagnostics(fit)
}
#> 12 observation(s) at or before the first dose were dropped.
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 1).
#> Chain 1: 
#> Chain 1: Gradient evaluation took 0.00019 seconds
#> Chain 1: 1000 transitions using 10 leapfrog steps per transition would take 1.9 seconds.
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
#> Chain 1:  Elapsed Time: 3.535 seconds (Warm-up)
#> Chain 1:                1.71 seconds (Sampling)
#> Chain 1:                5.245 seconds (Total)
#> Chain 1: 
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 2).
#> Chain 2: 
#> Chain 2: Gradient evaluation took 0.000116 seconds
#> Chain 2: 1000 transitions using 10 leapfrog steps per transition would take 1.16 seconds.
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
#> Chain 2:  Elapsed Time: 3.718 seconds (Warm-up)
#> Chain 2:                1.714 seconds (Sampling)
#> Chain 2:                5.432 seconds (Total)
#> Chain 2: 
#> Warning: Bulk Effective Samples Size (ESS) is too low, indicating posterior means and medians may be unreliable.
#> Running the chains for more iterations may help. See
#> https://mc-stan.org/misc/warnings.html#bulk-ess
#> Warning: R-hat > 1.01 (maximum 1.014) for omega_CL; chains have not mixed. Run longer (iter) before using the results.
#> Warning: Smallest effective sample size 200 (bulk) / 318 (tail) < 400.
#> $divergent
#> [1] 0
#> 
#> $max_treedepth
#> [1] 0
#> 
#> $ebfmi
#> [1] 0.5443271 0.5387187
#> 
#> $rhat_max
#> [1] 1.01408
#> 
#> $rhat_high
#> [1] "omega_CL"
#> 
#> $chains_apart
#> character(0)
#> 
#> $ess_bulk_min
#> [1] 200.4894
#> 
#> $ess_tail_min
#> [1] 318.2081
#> 
# }
```
