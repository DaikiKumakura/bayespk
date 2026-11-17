# Define a population pharmacokinetic model

Describes the structural model, the parameters with between-subject
variability, the residual error and covariate effects. Nothing is
compiled: the structure selects one of the precompiled closed-form
models.

## Usage

``` r
pk_model(
  structure = c("1cmt", "2cmt"),
  route = c("iv", "oral"),
  iiv = NULL,
  error = c("proportional", "additive", "combined", "log"),
  covariates = list(),
  correlated = FALSE,
  ka_faster = FALSE
)
```

## Arguments

- structure:

  `"1cmt"` or `"2cmt"`.

- route:

  `"iv"` (bolus, or infusion when the data have `RATE > 0`) or `"oral"`
  (first-order absorption).

- iiv:

  Character vector of parameters with log-normal between-subject
  variability.

- error:

  Residual error: `"additive"`, `"proportional"`, `"combined"` or
  `"log"` (additive on the log scale; DV must be positive).

- covariates:

  A list of formulas, one or more per parameter, such as
  `CL ~ (WT / 70)^0.75` (fixed exponent), `CL ~ (WT / 70)^b_wt`
  (estimated exponent named `b_wt`), `CL ~ exp(b_age * (AGE - 40))`
  (estimated) or `CL ~ (SEX == 1)^b_sex` (estimated effect of a
  category). Terms can be multiplied:
  `CL ~ (WT / 70)^0.75 * (CRCL / 100)^b_crcl`.

- correlated:

  Logical; estimate correlations between the random effects.

- ka_faster:

  Logical, oral models only. If `TRUE`, the typical KA is constrained to
  be larger than the typical disposition rate (k = CL/V for 1-cmt, the
  fast rate alpha for 2-cmt) of a subject at the covariate reference
  values. This removes the flip-flop mode in which KA and the
  disposition rate swap. Use it only when absorption is known to be
  faster than distribution; it is wrong for flip-flop drugs such as many
  extended-release forms. The prior density on KA is kept and set to
  zero for KA \<= rate (not renormalised). Default `FALSE`.

## Value

An object of class `bpk_model`.

## Details

Parameters are `CL`, `V` (1-compartment) or `CL`, `V1`, `Q`, `V2`
(2-compartment), plus `KA` for oral absorption. For oral dosing,
bioavailability is not estimated, so `CL`, `V`, `Q` and `V2` are
apparent values (divided by F).

## Examples

``` r
pk_model("2cmt", route = "oral", iiv = c("CL", "V1", "KA"),
         covariates = list(CL ~ (WT / 70)^0.75))
#> bayespk model: 2cmt oral 
#>   parameters: CL, V1, Q, V2, KA 
#>   between-subject variability (log-normal): CL, V1, KA  
#>   residual error: proportional 
#>   covariates:
#>     CL ~ (WT/70)^0.75 
```
