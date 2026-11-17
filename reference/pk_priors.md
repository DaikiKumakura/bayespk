# Specify priors

Named arguments set priors: structural parameters
(`CL = lognormal(...)`), estimated covariate effects by their names
(`b_wt = normal(...)`), the standard deviation of between-subject
variability per parameter (`omega_CL = half_normal(...)`) or for all
(`omega = half_normal(...)`), residual error (`sigma_add`, `sigma_prop`,
or `sigma_log` for log-scale error) and the LKJ shape for correlations
(`lkj = 2`). Anything not given gets a default, shown by
[`bpk_fit()`](https://daikikumakura.github.io/bayespk/reference/bpk_fit.md)
and stored in the fit.

## Usage

``` r
pk_priors(...)
```

## Arguments

- ...:

  Named priors.

## Value

An object of class `bpk_priors`.

## Details

Default priors for typical values are centred on rough data-based values
(non-compartmental estimates from the first dose) with a log-scale
standard deviation of 2, that is, a factor of about 7 per standard
deviation. They are weakly informative only; give informative priors
when prior knowledge exists.

## Examples

``` r
pk_priors(CL = lognormal(log(5), 0.5), omega = half_normal(0.5))
#> $CL
#> $dist
#> [1] "lognormal"
#> 
#> $mu
#> [1] 1.609438
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
