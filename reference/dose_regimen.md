# Dosing regimen

Dosing regimen

## Usage

``` r
dose_regimen(amt, ii = 0, n = 1, rate = 0, start = 0, ss = FALSE)
```

## Arguments

- amt:

  Dose amount.

- ii:

  Interval between doses.

- n:

  Number of doses.

- rate:

  Infusion rate (0 for bolus or oral).

- start:

  Time of the first dose.

- ss:

  Logical; the first dose is at steady state (the regimen has been given
  every `ii` long before `start`), as NONMEM `SS = 1`.

## Value

Data frame with `time`, `amt`, `rate` and `ss_ii`.

## Examples

``` r
dose_regimen(100, ii = 12, n = 3)
#>   time amt rate ss_ii
#> 1    0 100    0     0
#> 2   12 100    0     0
#> 3   24 100    0     0
dose_regimen(100, ii = 12, n = 2, ss = TRUE)   # at steady state
#>   time amt rate ss_ii
#> 1    0 100    0    12
#> 2   12 100    0     0
```
