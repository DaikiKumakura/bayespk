# Dosing regimen

Dosing regimen

## Usage

``` r
dose_regimen(amt, ii = 0, n = 1, rate = 0, start = 0)
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

## Value

Data frame with `time`, `amt` and `rate`.

## Examples

``` r
dose_regimen(100, ii = 12, n = 3)
#>   time amt rate
#> 1    0 100    0
#> 2   12 100    0
#> 3   24 100    0
```
