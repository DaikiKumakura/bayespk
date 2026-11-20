#' Concentrations from closed-form solutions
#'
#' Central-compartment concentrations of a linear 1- or 2-compartment model,
#' summed over doses. These are the same solutions used in the Stan model.
#'
#' @param times Observation times.
#' @param doses Data frame with `time`, `amt` and optionally `rate`
#'   (0 for bolus or oral doses) and `ss_ii` (> 0 for a steady-state dose
#'   given every `ss_ii`), as returned by [dose_regimen()].
#' @param par Named numeric vector of parameters (`CL`, `V` or `CL`, `V1`,
#'   `Q`, `V2`, and `KA` for oral).
#' @param structure `"1cmt"` or `"2cmt"`.
#' @param route `"iv"` or `"oral"`.
#' @return Numeric vector of concentrations at `times`.
#' @examples
#' pk_conc(0:24, dose_regimen(100), c(CL = 5, V = 50, KA = 1), "1cmt", "oral")
#' @export
pk_conc <- function(times, doses, par, structure = c("1cmt", "2cmt"),
                    route = c("iv", "oral")) {
  structure <- match.arg(structure)
  route <- match.arg(route)
  need <- structural_parameters(structure, route)
  if (!all(need %in% names(par))) {
    stop("`par` must contain ", paste(need, collapse = ", "), call. = FALSE)
  }
  if (is.null(doses$rate)) doses$rate <- 0
  if (route == "oral" && any(doses$rate > 0)) {
    stop("Infusions are not allowed with oral absorption.", call. = FALSE)
  }
  if (is.null(doses$ss_ii)) doses$ss_ii <- 0
  out <- numeric(length(times))
  for (d in seq_len(nrow(doses))) {
    out <- out + dose_contrib_r(times - doses$time[d], doses$amt[d], doses$rate[d],
                                doses$ss_ii[d], par, structure, route)
  }
  out
}

# Disposition after a unit bolus: list(l = rates, a = coefficients), each a
# list of vectors over parameter sets.
disposition_r <- function(par, structure) {
  if (structure == "1cmt") {
    return(list(l = list(par[["CL"]] / par[["V"]]), a = list(1 / par[["V"]])))
  }
  v1 <- par[["V1"]]
  k10 <- par[["CL"]] / v1
  k12 <- par[["Q"]] / v1
  k21 <- par[["Q"]] / par[["V2"]]
  s <- k10 + k12 + k21
  disc <- sqrt(s^2 - 4 * k10 * k21)
  alpha <- (s + disc) / 2
  beta <- (s - disc) / 2
  list(l = list(alpha, beta),
       a = list((alpha - k21) / (alpha - beta) / v1, (k21 - beta) / (alpha - beta) / v1))
}

geo_r <- function(l, t, ii) exp(-l * t) / (-expm1(-l * ii))
geo_dl_r <- function(l, t, ii) {
  q <- -expm1(-l * ii)
  (-t * exp(-l * t) * q - exp(-l * t) * ii * exp(-l * ii)) / q^2
}

# Steady-state concentration at t >= 0 after a dose given every ii (SS = 1).
ss_conc_r <- function(t, amt, rate, ii, par, structure, route) {
  d <- disposition_r(par, structure)
  out <- 0
  for (j in seq_along(d$l)) {
    l <- d$l[[j]]
    a <- d$a[[j]]
    if (route == "oral") {
      ka <- par[["KA"]]
      near <- abs(ka - l) < 1e-6 * l
      term <- amt * ka * a * pick(near, -geo_dl_r(l, t, ii),
                                  (geo_r(l, t, ii) - geo_r(ka, t, ii)) / (ka - l))
    } else if (rate > 0) {
      dur <- amt / rate
      term <- rate * a / l * pick(t < dur,
                                  -expm1(-l * t) + (-expm1(-l * dur)) * geo_r(l, t + ii - dur, ii),
                                  (-expm1(-l * dur)) * geo_r(l, t - dur, ii))
    } else {
      term <- amt * a * geo_r(l, t, ii)
    }
    out <- out + term
  }
  out
}

# Contribution of one dose record at time tau after it; ii > 0 marks a
# steady-state dose, which also applies for -ii < tau < 0.
dose_contrib_r <- function(tau, amt, rate, ii, par, structure, route) {
  if (!(ii > 0)) return(dose_conc_r(tau, amt, rate, par, structure, route))
  if (rate > 0 && amt / rate > ii) stop("A steady-state infusion must be shorter than II.", call. = FALSE)
  shifted <- ifelse(tau >= 0, tau, tau + ii)
  inside <- tau > -ii
  ss_conc_r(pmax(shifted, 0), amt, rate, ii, par, structure, route) * as.numeric(inside)
}

# Integral of exp(-ka * s) * exp(-k * (tau - s)) over s in [0, tau].
# Expand around equal rates to avoid cancellation and the removable 0/0.
absorption_kernel <- function(tau, k, ka) {
  x <- (ka - k) * tau
  near <- abs(x) < 1e-5
  denominator <- pick(near, 1, abs(x))
  pick(near,
       tau * exp(-(k + ka) * tau / 2) * (1 + x^2 / 24),
       tau * exp(-pmin(k, ka) * tau) * (-expm1(-abs(x)) / denominator))
}

# Concentration after one dose; vectorised over tau, and over parameters when
# `par` is a list of equal-length vectors.
dose_conc_r <- function(tau, amt, rate, par, structure, route) {
  pos <- tau >= 0
  tau <- pmax(tau, 0)
  if (structure == "1cmt") {
    cl <- par[["CL"]]
    v <- par[["V"]]
    k <- cl / v
    if (route == "oral") {
      ka <- par[["KA"]]
      conc <- amt * ka / v * absorption_kernel(tau, k, ka)
    } else if (rate > 0) {
      dur <- amt / rate
      conc <- pick(tau <= dur,
                   rate / cl * (1 - exp(-k * tau)),
                   rate / cl * (1 - exp(-k * dur)) * exp(-k * (tau - dur)))
    } else {
      conc <- amt / v * exp(-k * tau)
    }
  } else {
    v1 <- par[["V1"]]
    k10 <- par[["CL"]] / v1
    k12 <- par[["Q"]] / v1
    k21 <- par[["Q"]] / par[["V2"]]
    s <- k10 + k12 + k21
    disc <- sqrt(s^2 - 4 * k10 * k21)
    alpha <- (s + disc) / 2
    beta <- (s - disc) / 2
    a <- (alpha - k21) / (alpha - beta)
    b <- (k21 - beta) / (alpha - beta)
    if (route == "oral") {
      ka <- par[["KA"]]
      conc <- amt * ka / v1 * (a * absorption_kernel(tau, alpha, ka) +
                                b * absorption_kernel(tau, beta, ka))
    } else if (rate > 0) {
      dur <- amt / rate
      conc <- pick(
        tau <= dur,
        rate / v1 * (a / alpha * (1 - exp(-alpha * tau)) + b / beta * (1 - exp(-beta * tau))),
        rate / v1 * (a / alpha * (1 - exp(-alpha * dur)) * exp(-alpha * (tau - dur)) +
                       b / beta * (1 - exp(-beta * dur)) * exp(-beta * (tau - dur)))
      )
    } else {
      conc <- amt / v1 * (a * exp(-alpha * tau) + b * exp(-beta * tau))
    }
  }
  conc * as.numeric(pos)
}

# Element-wise choice that recycles all arguments to the longest one (unlike
# ifelse(), whose result has the length of the condition).
pick <- function(cond, yes, no) {
  n <- max(length(cond), length(yes), length(no))
  cond <- rep_len(cond, n)
  out <- rep_len(no, n)
  out[cond] <- rep_len(yes, n)[cond]
  out
}

#' Dosing regimen
#'
#' @param amt Dose amount.
#' @param ii Interval between doses.
#' @param n Number of doses.
#' @param rate Infusion rate (0 for bolus or oral).
#' @param start Time of the first dose.
#' @param ss Logical; the first dose is at steady state (the regimen has been
#'   given every `ii` long before `start`), as NONMEM `SS = 1`.
#' @return Data frame with `time`, `amt`, `rate` and `ss_ii`.
#' @examples
#' dose_regimen(100, ii = 12, n = 3)
#' dose_regimen(100, ii = 12, n = 2, ss = TRUE)   # at steady state
#' @export
dose_regimen <- function(amt, ii = 0, n = 1, rate = 0, start = 0, ss = FALSE) {
  if ((n > 1 || ss) && ii <= 0) stop("`ii` must be positive when n > 1 or ss = TRUE.", call. = FALSE)
  out <- data.frame(time = start + ii * (seq_len(n) - 1), amt = amt, rate = rate, ss_ii = 0)
  if (ss) out$ss_ii[1] <- ii
  out
}
