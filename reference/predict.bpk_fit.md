# Posterior predictions

Without `regimen`, returns individual predictions at the observed times
of the fitted subjects. With `regimen`, simulates concentrations for
that regimen: `type = "population"` draws new subjects from the
estimated between-subject distribution, `type = "typical"` uses the
typical subject. Predictions are computed in R from posterior draws with
the closed-form solutions; no refit is needed.

## Usage

``` r
# S3 method for class 'bpk_fit'
predict(
  object,
  regimen = NULL,
  times = NULL,
  type = c("population", "typical"),
  covariates = list(),
  ndraws = 1000,
  probs = c(0.05, 0.5, 0.95),
  residual = FALSE,
  seed = 1,
  ...
)
```

## Arguments

- object:

  A `bpk_fit`.

- regimen:

  Optional dosing regimen from
  [`dose_regimen()`](https://daikikumakura.github.io/bayespk/reference/dose_regimen.md).

- times:

  Times for `regimen` predictions (default: 100 points over the regimen
  plus one dosing interval).

- type:

  `"population"` or `"typical"` (used with `regimen`).

- covariates:

  Named list of covariate values for `regimen` predictions; unspecified
  covariates are set to the reference value of each term (categorical
  terms to their non-reference state, i.e. indicator 0).

- ndraws:

  Number of posterior draws used.

- probs:

  Quantiles to report.

- residual:

  Logical; add residual error (prediction intervals for observations
  rather than for the concentration).

- seed:

  Random seed.

- ...:

  Unused.

## Value

A data frame of predictions with quantiles.

## Examples

``` r
# \donttest{
if (requireNamespace("nlmixr2data", quietly = TRUE)) {
d <- nlmixr2data::theo_sd
mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
fit <- bpk_fit(mod, d, chains = 2, iter = 1000, seed = 1)
predict(fit, regimen = dose_regimen(320, ii = 12, n = 3), ndraws = 200)
}
#> 12 observation(s) at or before the first dose were dropped.
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 1).
#> Chain 1: 
#> Chain 1: Gradient evaluation took 0.000146 seconds
#> Chain 1: 1000 transitions using 10 leapfrog steps per transition would take 1.46 seconds.
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
#> Chain 1:  Elapsed Time: 3.529 seconds (Warm-up)
#> Chain 1:                1.709 seconds (Sampling)
#> Chain 1:                5.238 seconds (Total)
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
#> Chain 2:  Elapsed Time: 3.326 seconds (Warm-up)
#> Chain 2:                1.727 seconds (Sampling)
#> Chain 2:                5.053 seconds (Total)
#> Chain 2: 
#> Warning: Bulk Effective Samples Size (ESS) is too low, indicating posterior means and medians may be unreliable.
#> Running the chains for more iterations may help. See
#> https://mc-stan.org/misc/warnings.html#bulk-ess
#> Warning: R-hat > 1.01 (maximum 1.014) for omega_CL; chains have not mixed. Run longer (iter) before using the results.
#> Warning: Smallest effective sample size 200 (bulk) / 318 (tail) < 400.
#>           TIME        q5       q50       q95
#> 1    0.0000000 0.0000000  0.000000  0.000000
#> 2    0.4848485 2.0354145  4.995257  9.555287
#> 3    0.9696970 3.5401163  7.066873 10.708989
#> 4    1.4545455 4.6899514  7.751656 10.757770
#> 5    1.9393939 5.3968824  7.960354 10.570017
#> 6    2.4242424 5.7075586  7.888555 10.194516
#> 7    2.9090909 5.5541261  7.779636  9.931833
#> 8    3.3939394 5.5604694  7.582264  9.501129
#> 9    3.8787879 5.3334772  7.366967  9.201955
#> 10   4.3636364 5.3299884  7.107530  8.878892
#> 11   4.8484848 5.1891390  6.839359  8.519467
#> 12   5.3333333 5.0366441  6.565731  8.273758
#> 13   5.8181818 4.7438756  6.319048  8.028189
#> 14   6.3030303 4.6114562  6.059580  7.783110
#> 15   6.7878788 4.3648221  5.819327  7.616605
#> 16   7.2727273 4.0882400  5.567825  7.408950
#> 17   7.7575758 3.7997273  5.342158  7.204799
#> 18   8.2424242 3.6392372  5.122954  7.025951
#> 19   8.7272727 3.4835074  4.916243  6.886636
#> 20   9.2121212 3.2481418  4.729971  6.760579
#> 21   9.6969697 3.0286900  4.541022  6.568024
#> 22  10.1818182 2.8240758  4.347682  6.389727
#> 23  10.6666667 2.6340223  4.178456  6.377961
#> 24  11.1515152 2.4587881  4.028851  6.251494
#> 25  11.6363636 2.2895578  3.877427  6.107388
#> 26  12.1212121 3.5336846  5.565205  8.845770
#> 27  12.6060606 5.8536768  9.152197 14.168262
#> 28  13.0909091 7.1664013 10.624180 14.761157
#> 29  13.5757576 7.8543679 11.130104 14.887656
#> 30  14.0606061 7.9047070 10.998570 14.739707
#> 31  14.5454545 8.1363693 10.798107 14.189419
#> 32  15.0303030 7.8639907 10.510429 13.852972
#> 33  15.5151515 7.6771578 10.233405 13.506343
#> 34  16.0000000 7.3481728  9.891469 13.205836
#> 35  16.4848485 7.1119720  9.501323 12.941393
#> 36  16.9696970 6.7412759  9.144819 12.813618
#> 37  17.4545455 6.3213011  8.778952 12.604165
#> 38  17.9393939 6.0101977  8.476478 12.209167
#> 39  18.4242424 5.7140641  8.138437 11.918572
#> 40  18.9090909 5.3309370  7.833048 11.638885
#> 41  19.3939394 4.9707838  7.541935 11.365069
#> 42  19.8787879 4.6349682  7.248595 11.280066
#> 43  20.3636364 4.3253677  6.966669 11.108824
#> 44  20.8484848 4.0672242  6.686994 10.829449
#> 45  21.3333333 3.7686834  6.416376 10.614208
#> 46  21.8181818 3.5391110  6.152039 10.471530
#> 47  22.3030303 3.3541176  5.910494 10.255384
#> 48  22.7878788 3.1415150  5.688647  9.968466
#> 49  23.2727273 2.9285929  5.464403  9.689576
#> 50  23.7575758 2.7553529  5.253734  9.418491
#> 51  24.2424242 4.8634822  8.393456 13.382957
#> 52  24.7272727 7.1834240 11.305324 16.586223
#> 53  25.2121212 8.1226428 12.335046 17.108133
#> 54  25.6969697 8.5299391 12.405865 17.092750
#> 55  26.1818182 8.8677241 12.245016 16.733864
#> 56  26.6666667 8.8031096 11.931053 16.554295
#> 57  27.1515152 8.3877577 11.484795 16.335450
#> 58  27.6363636 8.0280700 11.078002 16.121864
#> 59  28.1212121 7.6988907 10.716940 15.769776
#> 60  28.6060606 7.4023184 10.378592 15.592747
#> 61  29.0909091 7.0020824  9.982630 15.229071
#> 62  29.5757576 6.6195993  9.594183 15.033186
#> 63  30.0606061 6.1862110  9.270540 14.817932
#> 64  30.5454545 5.7683273  8.903570 14.471638
#> 65  31.0303030 5.3819882  8.524824 14.346729
#> 66  31.5151515 5.0271950  8.156684 14.054735
#> 67  32.0000000 4.7405844  7.840146 13.661543
#> 68  32.4848485 4.3926123  7.541678 13.279342
#> 69  32.9696970 4.1040461  7.255640 12.907830
#> 70  33.4545455 3.8892126  6.970264 12.546712
#> 71  33.9393939 3.6461235  6.698836 12.195697
#> 72  34.4242424 3.3990105  6.447029 11.854504
#> 73  34.9090909 3.1883514  6.193409 11.570128
#> 74  35.3939394 3.0007936  5.958057 11.353890
#> 75  35.8787879 2.8186149  5.720170 11.068988
#> 76  36.3636364 2.6505016  5.469582 10.782150
#> 77  36.8484848 2.4924320  5.246068 10.502780
#> 78  37.3333333 2.3438051  5.037454 10.230682
#> 79  37.8181818 2.1844226  4.845838  9.965666
#> 80  38.3030303 2.0267101  4.661130  9.707547
#> 81  38.7878788 1.8803657  4.482344  9.454945
#> 82  39.2727273 1.7446746  4.311274  9.207547
#> 83  39.7575758 1.6188637  4.115771  8.966621
#> 84  40.2424242 1.5021203  3.928037  8.771731
#> 85  40.7272727 1.3937930  3.774040  8.590788
#> 86  41.2121212 1.2932760  3.626270  8.413579
#> 87  41.6969697 1.2000072  3.484288  8.240028
#> 88  42.1818182 1.1134645  3.347596  8.070059
#> 89  42.6666667 1.0331630  3.206725  7.903598
#> 90  43.1515152 0.9586531  3.071772  7.740575
#> 91  43.6363636 0.8895170  2.952249  7.580916
#> 92  44.1212121 0.8268145  2.838908  7.424554
#> 93  44.6060606 0.7702188  2.719316  7.271420
#> 94  45.0909091 0.7174978  2.599633  7.121448
#> 95  45.5757576 0.6683862  2.490156  6.974571
#> 96  46.0606061 0.6226367  2.385873  6.830727
#> 97  46.5454545 0.5800191  2.288664  6.689853
#> 98  47.0303030 0.5404052  2.197656  6.551886
#> 99  47.5151515 0.5035310  2.110268  6.416768
#> 100 48.0000000 0.4691729  2.026354  6.284440
# }
```
