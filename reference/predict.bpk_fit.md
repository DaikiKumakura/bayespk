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
#> Chain 1: Gradient evaluation took 0.000181 seconds
#> Chain 1: 1000 transitions using 10 leapfrog steps per transition would take 1.81 seconds.
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
#> Chain 1:  Elapsed Time: 8.638 seconds (Warm-up)
#> Chain 1:                2.819 seconds (Sampling)
#> Chain 1:                11.457 seconds (Total)
#> Chain 1: 
#> 
#> SAMPLING FOR MODEL 'popk' NOW (CHAIN 2).
#> Chain 2: 
#> Chain 2: Gradient evaluation took 0.000177 seconds
#> Chain 2: 1000 transitions using 10 leapfrog steps per transition would take 1.77 seconds.
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
#> Chain 2:  Elapsed Time: 9.575 seconds (Warm-up)
#> Chain 2:                3.066 seconds (Sampling)
#> Chain 2:                12.641 seconds (Total)
#> Chain 2: 
#> Warning: Smallest effective sample size 271 (bulk) / 333 (tail) < 400.
predict(fit, regimen = dose_regimen(100, ii = 12, n = 3), ndraws = 200)
#>           TIME         q5       q50      q95
#> 1    0.0000000 0.00000000 0.0000000 0.000000
#> 2    0.4848485 0.61287378 1.2950694 2.681690
#> 3    0.9696970 1.06335243 2.0596881 3.807120
#> 4    1.4545455 1.34145958 2.4721932 4.156158
#> 5    1.9393939 1.52633117 2.6785207 4.214375
#> 6    2.4242424 1.63855509 2.7131673 4.143784
#> 7    2.9090909 1.66459412 2.6913088 4.020719
#> 8    3.3939394 1.65893083 2.6532065 3.918682
#> 9    3.8787879 1.68463374 2.5697531 3.695939
#> 10   4.3636364 1.63890834 2.4628442 3.539686
#> 11   4.8484848 1.56210603 2.3537186 3.351635
#> 12   5.3333333 1.48639170 2.2379770 3.130616
#> 13   5.8181818 1.43680746 2.1471246 2.964871
#> 14   6.3030303 1.35038800 2.0487255 2.846226
#> 15   6.7878788 1.30557742 1.9487286 2.737214
#> 16   7.2727273 1.23696965 1.8595259 2.590530
#> 17   7.7575758 1.16721471 1.7527729 2.485097
#> 18   8.2424242 1.11907741 1.6680360 2.354505
#> 19   8.7272727 1.02516211 1.5727379 2.283408
#> 20   9.2121212 0.94418826 1.5067718 2.212541
#> 21   9.6969697 0.87501609 1.4431145 2.125432
#> 22  10.1818182 0.78107257 1.3689520 2.038636
#> 23  10.6666667 0.72006084 1.3005559 1.958339
#> 24  11.1515152 0.68018469 1.2296885 1.879659
#> 25  11.6363636 0.63769677 1.1623735 1.803555
#> 26  12.1212121 1.00583161 1.5512429 2.311774
#> 27  12.6060606 1.65242994 2.6407424 4.136607
#> 28  13.0909091 2.00698189 3.2049203 4.997380
#> 29  13.5757576 2.22049596 3.5139761 5.185768
#> 30  14.0606061 2.35009115 3.6287908 5.289124
#> 31  14.5454545 2.41593430 3.6032082 5.110471
#> 32  15.0303030 2.40621082 3.5488256 4.961195
#> 33  15.5151515 2.37835950 3.4304309 4.727998
#> 34  16.0000000 2.32693380 3.3312241 4.531735
#> 35  16.4848485 2.21820446 3.1845348 4.404591
#> 36  16.9696970 2.16778067 3.0033833 4.172279
#> 37  17.4545455 1.99101263 2.8494413 4.034315
#> 38  17.9393939 1.84687533 2.7091558 3.903653
#> 39  18.4242424 1.73372288 2.5901129 3.778154
#> 40  18.9090909 1.58732196 2.4919725 3.699220
#> 41  19.3939394 1.47949493 2.3808935 3.527075
#> 42  19.8787879 1.39982839 2.2599025 3.358133
#> 43  20.3636364 1.27308877 2.1414985 3.268586
#> 44  20.8484848 1.19209782 2.0255403 3.191136
#> 45  21.3333333 1.08738913 1.9256392 3.082738
#> 46  21.8181818 0.99309274 1.8492899 2.991384
#> 47  22.3030303 0.91765117 1.7748566 2.865558
#> 48  22.7878788 0.82558180 1.7022880 2.745063
#> 49  23.2727273 0.75274919 1.6257277 2.631562
#> 50  23.7575758 0.69446563 1.5491900 2.554906
#> 51  24.2424242 1.41714786 2.2788319 3.449755
#> 52  24.7272727 2.14704638 3.2014574 4.905005
#> 53  25.2121212 2.43919035 3.6784524 5.420484
#> 54  25.6969697 2.61433502 3.8759459 5.597296
#> 55  26.1818182 2.72227996 3.8826052 5.538608
#> 56  26.6666667 2.73248929 3.8899266 5.434045
#> 57  27.1515152 2.68801282 3.7767077 5.243226
#> 58  27.6363636 2.61023511 3.6243264 5.106453
#> 59  28.1212121 2.51099893 3.4739938 4.920749
#> 60  28.6060606 2.36062994 3.3109896 4.842832
#> 61  29.0909091 2.20878012 3.1805763 4.768037
#> 62  29.5757576 2.03662028 3.0712762 4.576127
#> 63  30.0606061 1.87022993 2.9332584 4.418973
#> 64  30.5454545 1.75414151 2.7747732 4.250964
#> 65  31.0303030 1.64184537 2.6534912 4.119540
#> 66  31.5151515 1.55596704 2.5133357 3.998692
#> 67  32.0000000 1.41613409 2.3857256 3.830870
#> 68  32.4848485 1.29006827 2.2783908 3.668455
#> 69  32.9696970 1.17681040 2.1901931 3.512002
#> 70  33.4545455 1.07523443 2.0773938 3.398574
#> 71  33.9393939 0.99531449 1.9916592 3.300023
#> 72  34.4242424 0.89606636 1.9009686 3.204159
#> 73  34.9090909 0.81427285 1.8076990 3.110965
#> 74  35.3939394 0.74996574 1.7179633 3.020407
#> 75  35.8787879 0.69148221 1.6412690 2.932435
#> 76  36.3636364 0.62136133 1.5629787 2.838290
#> 77  36.8484848 0.56231834 1.4930990 2.735951
#> 78  37.3333333 0.51224046 1.4178008 2.674838
#> 79  37.8181818 0.46662635 1.3450074 2.609630
#> 80  38.3030303 0.42507798 1.2720592 2.535970
#> 81  38.7878788 0.38723274 1.1969219 2.464398
#> 82  39.2727273 0.35276031 1.1334109 2.394858
#> 83  39.7575758 0.32150672 1.0763063 2.325758
#> 84  40.2424242 0.29308224 1.0239452 2.258015
#> 85  40.7272727 0.26717069 0.9741366 2.192250
#> 86  41.2121212 0.24354995 0.9264632 2.128404
#> 87  41.6969697 0.22201751 0.8797844 2.066421
#> 88  42.1818182 0.20238875 0.8308315 2.006248
#> 89  42.6666667 0.18413387 0.7871145 1.942832
#> 90  43.1515152 0.16616094 0.7460284 1.874545
#> 91  43.6363636 0.14991893 0.7070855 1.811815
#> 92  44.1212121 0.13524571 0.6701744 1.782216
#> 93  44.6060606 0.12199343 0.6351894 1.734374
#> 94  45.0909091 0.11002748 0.6020302 1.685607
#> 95  45.5757576 0.09922540 0.5723383 1.638225
#> 96  46.0606061 0.08947592 0.5444956 1.592189
#> 97  46.5454545 0.08067803 0.5157363 1.550444
#> 98  47.0303030 0.07296001 0.4872690 1.517186
#> 99  47.5151515 0.06642905 0.4620138 1.484644
#> 100 48.0000000 0.06048285 0.4394552 1.452803
# }
```
