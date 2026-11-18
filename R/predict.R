#' Posterior predictions
#'
#' Without `regimen`, returns individual predictions at the observed times of
#' the fitted subjects. With `regimen`, simulates concentrations for that
#' regimen: `type = "population"` draws new subjects from the estimated
#' between-subject distribution, `type = "typical"` uses the typical subject.
#' Predictions are computed in R from posterior draws with the closed-form
#' solutions; no refit is needed.
#'
#' @param object A `bpk_fit`.
#' @param regimen Optional dosing regimen from [dose_regimen()].
#' @param times Times for `regimen` predictions (default: 100 points over the
#'   regimen plus one dosing interval). Without `regimen`, giving `times`
#'   returns each subject's prediction at these times instead of at the
#'   observed times (`DV` is then `NA`).
#' @param type `"population"` or `"typical"` (used with `regimen`).
#' @param covariates Named list of covariate values for `regimen` predictions;
#'   unspecified covariates are set to the reference value of each term
#'   (categorical terms to their non-reference state, i.e. indicator 0).
#' @param ndraws Number of posterior draws used.
#' @param probs Quantiles to report.
#' @param residual Logical; add residual error (prediction intervals for
#'   observations rather than for the concentration).
#' @param seed Random seed.
#' @param ... Unused.
#' @return A data frame of predictions with quantiles.
#' @examples
#' \donttest{
#' mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
#' fit <- bpk_fit(mod, bpk_example, chains = 2, iter = 1000, seed = 1)
#' predict(fit, regimen = dose_regimen(100, ii = 12, n = 3), ndraws = 200)
#' }
#' @export
predict.bpk_fit <- function(object, regimen = NULL, times = NULL,
                            type = c("population", "typical"), covariates = list(),
                            ndraws = 1000, probs = c(0.05, 0.5, 0.95),
                            residual = FALSE, seed = 1, ...) {
  type <- match.arg(type)
  set.seed(seed)
  m <- object$model
  ex <- rstan::extract(object$stanfit, pars = c("log_par", "log_theta", "sigma",
                                                if (object$stan_data$n_beta) "beta",
                                                if (length(m$iiv)) "omega",
                                                if (m$correlated) "L_corr"))
  total <- dim(ex$log_theta)[1]
  draws <- if (ndraws >= total) seq_len(total) else sort(sample.int(total, ndraws))
  qtab <- function(mat) {
    q <- t(apply(mat, 2, stats::quantile, probs = probs, names = FALSE))
    colnames(q) <- paste0("q", probs * 100)
    q
  }
  add_res <- function(conc, sigma) {
    if (!residual) return(conc)
    s <- sigma[draws, , drop = FALSE]
    n <- length(conc)
    switch(m$error,
           additive = conc + stats::rnorm(n, 0, s[, 1]),
           proportional = conc * (1 + stats::rnorm(n, 0, s[, 1])),
           combined = conc + stats::rnorm(n, 0, sqrt(s[, 1]^2 + (s[, 2] * conc)^2)),
           log = conc * exp(stats::rnorm(n, 0, s[, 1])))
  }
  pars <- m$parameters

  if (is.null(regimen)) {
    obs <- object$prep$obs
    # Individual predictions at the observed times, or on `times` for every subject.
    grid <- if (is.null(times)) {
      data.frame(sid = obs$sid, time = obs$time, dv = obs$dv)
    } else {
      expand <- lapply(seq_len(object$prep$N), function(i) data.frame(sid = i, time = times, dv = NA_real_))
      do.call(rbind, expand)
    }
    out <- matrix(NA_real_, length(draws), nrow(grid))
    for (i in seq_len(object$prep$N)) {
      par <- lapply(seq_along(pars), function(k) exp(ex$log_par[draws, i, k]))
      names(par) <- pars
      d <- object$prep$dose[object$prep$dose$sid == i, ]
      for (n in which(grid$sid == i)) {
        conc <- 0
        for (j in seq_len(nrow(d))) {
          conc <- conc + dose_conc_r(grid$time[n] - d$time[j], d$amt[j], d$rate[j], par,
                                     m$structure, m$route)
        }
        out[, n] <- add_res(conc, ex$sigma)
      }
    }
    res <- data.frame(ID = object$prep$ids[grid$sid], TIME = grid$time, DV = grid$dv, qtab(out))
    return(new_prediction(res, "individual", probs))
  }

  if (is.null(regimen$rate)) regimen$rate <- 0
  if (is.null(times)) {
    span <- max(regimen$time) + max(c(diff(regimen$time), 24))
    times <- seq(0, span, length.out = 100)
  }
  # Log-scale parameters of one new subject per draw.
  lp <- ex$log_theta[draws, , drop = FALSE]
  terms <- m$covariates
  if (nrow(terms)) {
    vals <- lapply(seq_len(nrow(terms)), function(j) {
      v <- covariates[[terms$var[j]]]
      if (is.null(v)) return(0)
      switch(terms$type[j], power = log(v / terms$ref[j]), linear = v - terms$ref[j],
             cat = as.numeric(as.character(v) == terms$level[j]))
    })
    bi <- 0
    for (j in seq_len(nrow(terms))) {
      k <- match(terms$param[j], pars)
      if (is.na(terms$name[j])) {
        lp[, k] <- lp[, k] + terms$value[j] * vals[[j]]
      } else {
        bi <- bi + 1
        lp[, k] <- lp[, k] + ex$beta[draws, bi] * vals[[j]]
      }
    }
  }
  if (type == "population" && length(m$iiv)) {
    ne <- length(m$iiv)
    for (s in seq_along(draws)) {
      L <- if (m$correlated) ex$L_corr[draws[s], , ] else diag(ne)
      eta <- as.vector(diag(ex$omega[draws[s], ], ne) %*% L %*% stats::rnorm(ne))
      idx <- match(m$iiv, pars)
      lp[s, idx] <- lp[s, idx] + eta
    }
  }
  par <- lapply(seq_along(pars), function(k) exp(lp[, k]))
  names(par) <- pars
  out <- matrix(NA_real_, length(draws), length(times))
  for (n in seq_along(times)) {
    conc <- 0
    for (j in seq_len(nrow(regimen))) {
      conc <- conc + dose_conc_r(times[n] - regimen$time[j], regimen$amt[j], regimen$rate[j],
                                 par, m$structure, m$route)
    }
    out[, n] <- add_res(conc, ex$sigma)
  }
  new_prediction(data.frame(TIME = times, qtab(out)), "regimen", probs, regimen)
}

new_prediction <- function(x, kind, probs, regimen = NULL) {
  structure(x, class = c("bpk_prediction", "data.frame"), kind = kind, probs = probs,
            regimen = regimen)
}
