#' Define a population pharmacokinetic model
#'
#' Describes the structural model, the parameters with between-subject
#' variability, the residual error and covariate effects. Nothing is compiled:
#' the structure selects one of the precompiled closed-form models.
#'
#' Parameters are `CL`, `V` (1-compartment) or `CL`, `V1`, `Q`, `V2`
#' (2-compartment), plus `KA` for oral absorption. For oral dosing,
#' bioavailability is not estimated, so `CL`, `V`, `Q` and `V2` are apparent
#' values (divided by F).
#'
#' @param structure `"1cmt"` or `"2cmt"`.
#' @param route `"iv"` (bolus, or infusion when the data have `RATE > 0`) or
#'   `"oral"` (first-order absorption).
#' @param iiv Character vector of parameters with log-normal between-subject
#'   variability.
#' @param error Residual error: `"additive"`, `"proportional"`, `"combined"`
#'   or `"log"` (additive on the log scale; DV must be positive).
#' @param covariates A list of formulas, one or more per parameter, such as
#'   `CL ~ (WT / 70)^0.75` (fixed exponent), `CL ~ (WT / 70)^b_wt` (estimated
#'   exponent named `b_wt`), `CL ~ exp(b_age * (AGE - 40))` (estimated) or
#'   `CL ~ (SEX == 1)^b_sex` (estimated effect of a category). Terms can be
#'   multiplied: `CL ~ (WT / 70)^0.75 * (CRCL / 100)^b_crcl`.
#' @param correlated Logical; estimate correlations between the random effects.
#' @param ka_faster Logical, oral models only. If `TRUE`, the typical KA is
#'   constrained to be larger than the typical disposition rate (k = CL/V for
#'   1-cmt, the fast rate alpha for 2-cmt) of a subject at the covariate
#'   reference values. This removes the flip-flop mode in which KA and the
#'   disposition rate swap. Use it only when absorption is known to be faster
#'   than distribution; it is wrong for flip-flop drugs such as many
#'   extended-release forms. The prior density on KA is kept and set to zero for KA <= rate
#'   (not renormalised).
#'   Default `FALSE`.
#' @return An object of class `bpk_model`.
#' @examples
#' pk_model("2cmt", route = "oral", iiv = c("CL", "V1", "KA"),
#'          covariates = list(CL ~ (WT / 70)^0.75))
#' @export
pk_model <- function(structure = c("1cmt", "2cmt"), route = c("iv", "oral"),
                     iiv = NULL, error = c("proportional", "additive", "combined", "log"),
                     covariates = list(), correlated = FALSE,
                     ka_faster = FALSE) {
  structure <- match.arg(structure)
  route <- match.arg(route)
  error <- match.arg(error)
  pars <- structural_parameters(structure, route)
  if (is.null(iiv)) iiv <- setdiff(pars, c("Q", "V2"))
  bad <- setdiff(iiv, pars)
  if (length(bad)) stop("Unknown parameter(s) in `iiv`: ", paste(bad, collapse = ", "),
                        ". Parameters of this model: ", paste(pars, collapse = ", "), call. = FALSE)
  if (isTRUE(ka_faster) && route != "oral") stop("`ka_faster` applies only to oral models.", call. = FALSE)
  if (inherits(covariates, "formula")) covariates <- list(covariates)
  terms <- parse_covariates(covariates, pars)
  structure(list(structure = structure, route = route, parameters = pars,
                 iiv = unique(iiv), error = error, covariates = terms,
                 correlated = isTRUE(correlated) && length(unique(iiv)) > 1,
                 ka_faster = isTRUE(ka_faster)),
            class = "bpk_model")
}

structural_parameters <- function(structure, route) {
  p <- if (structure == "1cmt") c("CL", "V") else c("CL", "V1", "Q", "V2")
  if (route == "oral") p <- c(p, "KA")
  p
}

#' @export
print.bpk_model <- function(x, ...) {
  cat("bayespk model:", x$structure, x$route, "\n")
  cat("  parameters:", paste(x$parameters, collapse = ", "), "\n")
  cat("  between-subject variability (log-normal):",
      if (length(x$iiv)) paste(x$iiv, collapse = ", ") else "none",
      if (x$correlated) "(correlated)" else "", "\n")
  cat("  residual error:", x$error, "\n")
  if (nrow(x$covariates)) {
    cat("  covariates:\n")
    for (i in seq_len(nrow(x$covariates))) cat("   ", x$covariates$label[i], "\n")
  }
  invisible(x)
}
