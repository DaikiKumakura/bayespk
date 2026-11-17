#' Concentrations from closed-form solutions
#'
#' Central-compartment concentrations of a linear 1- or 2-compartment model,
#' summed over doses. These are the same solutions used in the Stan model.
#'
#' @param times Observation times.
#' @param doses Data frame with `time`, `amt` and optionally `rate`
#'   (0 for bolus or oral doses), as returned by [dose_regimen()].
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
  out <- numeric(length(times))
  for (d in seq_len(nrow(doses))) {
    out <- out + dose_conc_r(times - doses$time[d], doses$amt[d], doses$rate[d],
                             par, structure, route)
  }
  out
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
#' @return Data frame with `time`, `amt` and `rate`.
#' @examples
#' dose_regimen(100, ii = 12, n = 3)
#' @export
dose_regimen <- function(amt, ii = 0, n = 1, rate = 0, start = 0) {
  if (n > 1 && ii <= 0) stop("`ii` must be positive when n > 1.", call. = FALSE)
  data.frame(time = start + ii * (seq_len(n) - 1), amt = amt, rate = rate)
}
