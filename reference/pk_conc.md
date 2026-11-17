# Concentrations from closed-form solutions

Central-compartment concentrations of a linear 1- or 2-compartment
model, summed over doses. These are the same solutions used in the Stan
model.

## Usage

``` r
pk_conc(
  times,
  doses,
  par,
  structure = c("1cmt", "2cmt"),
  route = c("iv", "oral")
)
```

## Arguments

- times:

  Observation times.

- doses:

  Data frame with `time`, `amt` and optionally `rate` (0 for bolus or
  oral doses), as returned by
  [`dose_regimen()`](https://daikikumakura.github.io/bayespk/reference/dose_regimen.md).

- par:

  Named numeric vector of parameters (`CL`, `V` or `CL`, `V1`, `Q`,
  `V2`, and `KA` for oral).

- structure:

  `"1cmt"` or `"2cmt"`.

- route:

  `"iv"` or `"oral"`.

## Value

Numeric vector of concentrations at `times`.

## Examples

``` r
pk_conc(0:24, dose_regimen(100), c(CL = 5, V = 50, KA = 1), "1cmt", "oral")
#>  [1] 0.0000000 1.1932399 1.5186566 1.5356248 1.4488987 1.3328727 1.2140731
#>  [8] 1.1014965 0.9977633 0.9032139 0.8174090 0.7396764 0.6693068 0.6056212
#> [15] 0.5479914 0.4958441 0.4486587 0.4059633 0.3673308 0.3323747 0.3007451
#> [22] 0.2721254 0.2462292 0.2227974 0.2015955
```
