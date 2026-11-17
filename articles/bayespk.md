# Getting started with bayespk

bayespk fits Bayesian population pharmacokinetic models without writing
Stan. The workflow has three steps: describe the model with
[`pk_model()`](https://daikikumakura.github.io/bayespk/reference/pk_model.md),
fit it with
[`bpk_fit()`](https://daikikumakura.github.io/bayespk/reference/bpk_fit.md),
and look at the results with
[`summary()`](https://rdrr.io/r/base/summary.html) and
[`predict()`](https://rdrr.io/r/stats/predict.html).

Model fitting takes tens of seconds to minutes, so the fitting chunks
below are not run when the vignette is built (set the environment
variable `BAYESPK_VIGNETTE_FITS=true` to run them).

## 1. Describe the model

``` r

library(bayespk)
mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"), error = "proportional")
mod
#> bayespk model: 1cmt oral 
#>   parameters: CL, V, KA 
#>   between-subject variability (log-normal): CL, V, KA  
#>   residual error: proportional
```

Structures are `"1cmt"` and `"2cmt"`; routes are `"iv"` (bolus or
infusion, from the `RATE` column) and `"oral"`. Covariates are formulas:

``` r

pk_model("2cmt", route = "oral", iiv = c("CL", "V1", "KA"),
         covariates = list(CL ~ (WT / 70)^0.75, V1 ~ (WT / 70)^b_wt))
#> bayespk model: 2cmt oral 
#>   parameters: CL, V1, Q, V2, KA 
#>   between-subject variability (log-normal): CL, V1, KA  
#>   residual error: proportional 
#>   covariates:
#>     CL ~ (WT/70)^0.75 
#>     V1 ~ (WT/70)^b_wt
```

`(WT / 70)^0.75` fixes the exponent; `(WT / 70)^b_wt` estimates it as a
parameter named `b_wt`.

## 2. Data

A NONMEM-style data frame: `ID`, `TIME`, `DV`, `AMT`, and optionally
`EVID`, `MDV`, `RATE`, `ADDL`, `II`. The theophylline data in
nlmixr2data can be used as it is.

``` r

d <- nlmixr2data::theo_sd
head(d)
#>   ID TIME    DV     AMT EVID CMT   WT
#> 1  1 0.00  0.00 319.992  101   1 79.6
#> 2  1 0.00  0.74   0.000    0   2 79.6
#> 3  1 0.25  2.84   0.000    0   2 79.6
#> 4  1 0.57  6.57   0.000    0   2 79.6
#> 5  1 1.12 10.50   0.000    0   2 79.6
#> 6  1 2.02  9.66   0.000    0   2 79.6
```

## 3. Priors

Typical values get weakly informative log-normal priors centred on a
rough non-compartmental estimate from the data; anything you give
replaces the default. The priors used are stored with the fit and
printed.

``` r

pri <- pk_priors(CL = lognormal(log(3), 0.5), omega = half_normal(0.5))
pri
#> $CL
#> $dist
#> [1] "lognormal"
#> 
#> $mu
#> [1] 1.098612
#> 
#> $sd
#> [1] 0.5
#> 
#> attr(,"class")
#> [1] "bpk_prior"
#> 
#> $omega
#> $dist
#> [1] "half_normal"
#> 
#> $mu
#> [1] 0
#> 
#> $sd
#> [1] 0.5
#> 
#> attr(,"class")
#> [1] "bpk_prior"
#> 
#> attr(,"class")
#> [1] "bpk_priors"
```

## 4. Fit

``` r

fit <- bpk_fit(mod, d, priors = pri, chains = 4, cores = 4, seed = 1)
fit
summary(fit)
bpk_diagnostics(fit)
```

[`bpk_fit()`](https://daikikumakura.github.io/bayespk/reference/bpk_fit.md)
warns about divergent transitions, R-hat above 1.01, low effective
sample size, and chains that settled in different modes. Do not use the
summaries when these warnings appear.

## 5. Predict

Individual predictions at the observed times, and posterior predictions
for a new regimen:

``` r

head(predict(fit))
predict(fit, regimen = dose_regimen(320, ii = 12, n = 3), times = seq(0, 48, 2))
```

The concentration function used in the model is exported, so you can
check a regimen without a fit:

``` r

pk_conc(c(1, 4, 12), dose_regimen(320), c(CL = 2.8, V = 32, KA = 1.5), "1cmt", "oral")
#> [1] 7.360234 7.457090 3.716153
```

## Two-compartment oral models and flip-flop

In a two-compartment oral model the absorption rate KA and the fast
disposition rate can swap, which gives two posterior modes. If
[`bpk_fit()`](https://daikikumakura.github.io/bayespk/reference/bpk_fit.md)
warns that chains settled in different regions, and absorption is known
to be faster than distribution, use `pk_model(..., ka_faster = TRUE)`.
Do not use it for drugs with absorption-limited (flip-flop) kinetics
such as many extended-release forms.
