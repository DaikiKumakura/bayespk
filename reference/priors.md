# Prior distributions

`lognormal()` is used for typical values of structural parameters (its
`meanlog` and `sdlog` are on the log scale), `normal()` for estimated
covariate effects, and `half_normal()` for standard deviations.

## Usage

``` r
lognormal(meanlog, sdlog)

normal(mean, sd)

half_normal(scale)
```

## Arguments

- meanlog, sdlog:

  Mean and standard deviation on the log scale.

- mean, sd:

  Mean and standard deviation.

- scale:

  Scale of a half-normal distribution.

## Value

An object of class `bpk_prior`.

## Examples

``` r
lognormal(log(5), 0.5)
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
half_normal(0.5)
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
```
