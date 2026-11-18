# Simulated oral pharmacokinetic data

A simulated study in NONMEM format used in the examples and vignettes:
30 subjects given a single oral dose of 100 mg (subjects 1-15) or 200 mg
(16-30); every third subject has rich sampling (10 samples over 24 h),
the others sparse sampling (4 samples).

## Usage

``` r
bpk_example
```

## Format

A data frame with one row per dose or observation:

- ID:

  Subject.

- TIME:

  Time after dose (h).

- AMT:

  Dose (mg) on dose records, 0 otherwise.

- DV:

  Plasma concentration (mg/L); `NA` on dose records.

- EVID:

  1 dose, 0 observation.

- WT:

  Body weight (kg).

- SEX:

  0 or 1.

## Details

Simulated from a 1-compartment model with first-order absorption: CL = 3
(WT/70)^0.75, V = 30 (WT/70), KA = 1.2 (typical values, L/h, L, 1/h),
log-normal between-subject SDs 0.3, 0.2 and 0.4, proportional residual
SD 0.15. `SEX` has no effect. The script is in `data-raw/bpk_example.R`
in the source repository.
