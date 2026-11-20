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
  plus one dosing interval). Without `regimen`, giving `times` returns
  each subject's prediction at these times instead of at the observed
  times (`DV` is then `NA`).

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
mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
fit <- bpk_fit(mod, bpk_example, chains = 2, iter = 1000, seed = 1)
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 1).
#> Chain 1: 
#> Chain 1: Gradient evaluation took 0.00016 seconds
#> Chain 1: 1000 transitions using 10 leapfrog steps per transition would take 1.6 seconds.
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
#> Chain 1:  Elapsed Time: 7.482 seconds (Warm-up)
#> Chain 1:                2.484 seconds (Sampling)
#> Chain 1:                9.966 seconds (Total)
#> Chain 1: 
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 2).
#> Chain 2: 
#> Chain 2: Gradient evaluation took 0.000145 seconds
#> Chain 2: 1000 transitions using 10 leapfrog steps per transition would take 1.45 seconds.
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
#> Chain 2:  Elapsed Time: 7.57 seconds (Warm-up)
#> Chain 2:                2.4 seconds (Sampling)
#> Chain 2:                9.97 seconds (Total)
#> Chain 2: 
#> Warning: Bulk Effective Samples Size (ESS) is too low, indicating posterior means and medians may be unreliable.
#> Running the chains for more iterations may help. See
#> https://mc-stan.org/misc/warnings.html#bulk-ess
#> Warning: Smallest effective sample size 197 (bulk) / 374 (tail) < 400.
predict(fit, regimen = dose_regimen(100, ii = 12, n = 3), ndraws = 200)
#>           TIME         q5       q50      q95
#> 1    0.0000000 0.00000000 0.0000000 0.000000
#> 2    0.4848485 0.63767881 1.2924637 2.707013
#> 3    0.9696970 1.07703073 2.0253982 3.812560
#> 4    1.4545455 1.38674702 2.4531412 4.102231
#> 5    1.9393939 1.57123609 2.6850427 4.184516
#> 6    2.4242424 1.63246612 2.7722369 4.167660
#> 7    2.9090909 1.67220786 2.7657581 4.130272
#> 8    3.3939394 1.69749064 2.7216024 3.973993
#> 9    3.8787879 1.69820561 2.6407227 3.724169
#> 10   4.3636364 1.66927396 2.5547661 3.445997
#> 11   4.8484848 1.59119813 2.4335385 3.251456
#> 12   5.3333333 1.55516075 2.3053271 3.063123
#> 13   5.8181818 1.48436921 2.1845880 2.970119
#> 14   6.3030303 1.42163386 2.0477359 2.858756
#> 15   6.7878788 1.36143057 1.9381232 2.663364
#> 16   7.2727273 1.29777940 1.8392636 2.558794
#> 17   7.7575758 1.20474141 1.7468063 2.454466
#> 18   8.2424242 1.11692785 1.6716831 2.379278
#> 19   8.7272727 1.02511283 1.5831870 2.281751
#> 20   9.2121212 0.93520167 1.5051215 2.246421
#> 21   9.6969697 0.87676765 1.4383290 2.182018
#> 22  10.1818182 0.80333239 1.3679393 2.111594
#> 23  10.6666667 0.74377741 1.3172102 2.043065
#> 24  11.1515152 0.67334545 1.2393921 1.975651
#> 25  11.6363636 0.60951533 1.1922514 1.910080
#> 26  12.1212121 1.00695238 1.5699250 2.276478
#> 27  12.6060606 1.76390659 2.6943757 4.014620
#> 28  13.0909091 2.16604266 3.2571584 4.911292
#> 29  13.5757576 2.40665471 3.5847932 5.062281
#> 30  14.0606061 2.48842412 3.6705795 5.211336
#> 31  14.5454545 2.53405749 3.6677819 5.074168
#> 32  15.0303030 2.52632387 3.5682530 4.815488
#> 33  15.5151515 2.44166527 3.4571071 4.643480
#> 34  16.0000000 2.36666637 3.3014312 4.512450
#> 35  16.4848485 2.26463060 3.1449510 4.422300
#> 36  16.9696970 2.15913720 3.0014058 4.233333
#> 37  17.4545455 2.07605663 2.8614882 4.106290
#> 38  17.9393939 1.90375088 2.7380941 3.994230
#> 39  18.4242424 1.74036392 2.6109956 3.882726
#> 40  18.9090909 1.59145747 2.4764492 3.769319
#> 41  19.3939394 1.46687468 2.3666524 3.653505
#> 42  19.8787879 1.36114346 2.2668408 3.538681
#> 43  20.3636364 1.25501128 2.1706217 3.437929
#> 44  20.8484848 1.15265288 2.0856643 3.338408
#> 45  21.3333333 1.05999501 1.9691771 3.251674
#> 46  21.8181818 0.95972286 1.8689303 3.166198
#> 47  22.3030303 0.86899937 1.7814045 3.082222
#> 48  22.7878788 0.78675718 1.7005078 2.998841
#> 49  23.2727273 0.71220870 1.6117579 2.913473
#> 50  23.7575758 0.64477104 1.5241294 2.839197
#> 51  24.2424242 1.45215994 2.2633426 3.436321
#> 52  24.7272727 2.07828271 3.2156650 4.843216
#> 53  25.2121212 2.46548807 3.7084260 5.319695
#> 54  25.6969697 2.72638956 3.9574183 5.522283
#> 55  26.1818182 2.81190156 4.0036920 5.426554
#> 56  26.6666667 2.78656833 3.9524381 5.341949
#> 57  27.1515152 2.68933629 3.8074877 5.252481
#> 58  27.6363636 2.61505731 3.6535738 5.187364
#> 59  28.1212121 2.53093553 3.4858737 5.066718
#> 60  28.6060606 2.42107456 3.3352949 4.924333
#> 61  29.0909091 2.25938124 3.1957818 4.783173
#> 62  29.5757576 2.09311190 3.0302776 4.643666
#> 63  30.0606061 1.90884515 2.9041869 4.520721
#> 64  30.5454545 1.71947281 2.7923608 4.399018
#> 65  31.0303030 1.61026011 2.6778145 4.296195
#> 66  31.5151515 1.46983829 2.5560370 4.193143
#> 67  32.0000000 1.36199226 2.4170646 4.101175
#> 68  32.4848485 1.25216643 2.2999037 4.009813
#> 69  32.9696970 1.14930782 2.1953143 3.878593
#> 70  33.4545455 1.04076350 2.0875698 3.774818
#> 71  33.9393939 0.94232144 1.9832782 3.643341
#> 72  34.4242424 0.85323899 1.8769686 3.510575
#> 73  34.9090909 0.77245896 1.8014371 3.381451
#> 74  35.3939394 0.69928417 1.7188145 3.256135
#> 75  35.8787879 0.63318810 1.6277738 3.135502
#> 76  36.3636364 0.57331216 1.5364772 3.019393
#> 77  36.8484848 0.52074211 1.4586956 2.907132
#> 78  37.3333333 0.47464003 1.3850076 2.798693
#> 79  37.8181818 0.43261824 1.3070259 2.694022
#> 80  38.3030303 0.39431635 1.2358522 2.618836
#> 81  38.7878788 0.35940551 1.1830532 2.572616
#> 82  39.2727273 0.32758575 1.1281405 2.528010
#> 83  39.7575758 0.29886430 1.0694836 2.480475
#> 84  40.2424242 0.27270704 1.0114671 2.428156
#> 85  40.7272727 0.24923217 0.9620911 2.366654
#> 86  41.2121212 0.23057951 0.9112116 2.292838
#> 87  41.6969697 0.21332515 0.8629991 2.221346
#> 88  42.1818182 0.19697035 0.8173186 2.152102
#> 89  42.6666667 0.17822249 0.7740409 2.085037
#> 90  43.1515152 0.16125946 0.7331243 2.020329
#> 91  43.6363636 0.14591134 0.6981958 1.961213
#> 92  44.1212121 0.13202435 0.6610690 1.903719
#> 93  44.6060606 0.11945938 0.6259104 1.847911
#> 94  45.0909091 0.10836456 0.5926168 1.793740
#> 95  45.5757576 0.09876635 0.5610905 1.741157
#> 96  46.0606061 0.09001856 0.5312383 1.690115
#> 97  46.5454545 0.08204582 0.5029719 1.640571
#> 98  47.0303030 0.07477943 0.4762078 1.592479
#> 99  47.5151515 0.06815679 0.4522098 1.551198
#> 100 48.0000000 0.06212086 0.4303650 1.523082
# }
```
