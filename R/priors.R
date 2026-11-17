#' Prior distributions
#'
#' `lognormal()` is used for typical values of structural parameters (its
#' `meanlog` and `sdlog` are on the log scale), `normal()` for estimated
#' covariate effects, and `half_normal()` for standard deviations.
#'
#' @param meanlog,sdlog Mean and standard deviation on the log scale.
#' @param mean,sd Mean and standard deviation.
#' @param scale Scale of a half-normal distribution.
#' @return An object of class `bpk_prior`.
#' @name priors
NULL

#' @rdname priors
#' @examples
#' lognormal(log(5), 0.5)
#' half_normal(0.5)
#' @export
lognormal <- function(meanlog, sdlog) {
  check_prior_args(meanlog, sdlog)
  structure(list(dist = "lognormal", mu = meanlog, sd = sdlog), class = "bpk_prior")
}

#' @rdname priors
#' @export
normal <- function(mean, sd) {
  check_prior_args(mean, sd)
  structure(list(dist = "normal", mu = mean, sd = sd), class = "bpk_prior")
}

#' @rdname priors
#' @export
half_normal <- function(scale) {
  check_prior_args(0, scale)
  structure(list(dist = "half_normal", mu = 0, sd = scale), class = "bpk_prior")
}

check_prior_args <- function(mu, sd) {
  if (!is.numeric(mu) || length(mu) != 1 || !is.finite(mu)) {
    stop("The location must be one finite number.", call. = FALSE)
  }
  if (!is.numeric(sd) || length(sd) != 1 || !is.finite(sd) || sd <= 0) {
    stop("The scale must be one positive number.", call. = FALSE)
  }
}

#' Specify priors
#'
#' Named arguments set priors: structural parameters (`CL = lognormal(...)`),
#' estimated covariate effects by their names (`b_wt = normal(...)`), the
#' standard deviation of between-subject variability per parameter
#' (`omega_CL = half_normal(...)`) or for all (`omega = half_normal(...)`),
#' residual error (`sigma_add`, `sigma_prop`, or `sigma_log` for log-scale
#' error) and the LKJ shape for correlations (`lkj = 2`). Anything not given
#' gets a default, shown by [bpk_fit()] and stored in the fit.
#'
#' Default priors for typical values are centred on rough data-based values
#' (non-compartmental estimates from the first dose) with a log-scale
#' standard deviation of 2, that is, a factor of about 7 per standard
#' deviation. They are weakly informative only; give informative priors when
#' prior knowledge exists.
#'
#' @param ... Named priors.
#' @return An object of class `bpk_priors`.
#' @examples
#' pk_priors(CL = lognormal(log(5), 0.5), omega = half_normal(0.5))
#' @export
pk_priors <- function(...) {
  p <- list(...)
  if (length(p) && (is.null(names(p)) || any(names(p) == ""))) {
    stop("All priors must be named.", call. = FALSE)
  }
  for (n in names(p)) {
    if (n == "lkj") {
      if (!is.numeric(p[[n]]) || length(p[[n]]) != 1 || p[[n]] <= 0) {
        stop("`lkj` must be one positive number.", call. = FALSE)
      }
    } else if (!inherits(p[[n]], "bpk_prior")) {
      stop("Prior `", n, "` must be made with lognormal(), normal() or half_normal().", call. = FALSE)
    }
  }
  structure(p, class = "bpk_priors")
}

# Resolve user priors and defaults into vectors for Stan; also returns a table.
resolve_priors <- function(model, priors, data_scale) {
  if (is.null(priors)) priors <- pk_priors()
  pars <- model$parameters
  terms <- model$covariates
  est <- terms$name[!is.na(terms$name)]
  known <- c(pars, est, "omega", paste0("omega_", model$iiv),
             "sigma_add", "sigma_prop", "sigma_log", "lkj")
  bad <- setdiff(names(priors), known)
  if (length(bad)) {
    stop("Prior(s) for quantities not in the model: ", paste(bad, collapse = ", "), call. = FALSE)
  }
  rows <- list()
  record <- function(name, dist, mu, sd, source) {
    rows[[length(rows) + 1]] <<- data.frame(
      quantity = name, distribution = dist, location = mu, scale = sd,
      source = source, stringsAsFactors = FALSE
    )
  }
  take <- function(name, default_dist, default_mu, default_sd, required_dist) {
    p <- priors[[name]]
    if (is.null(p)) {
      return(list(mu = default_mu, sd = default_sd, source = "default"))
    }
    if (p$dist != required_dist) {
      stop("`", name, "` needs a ", required_dist, "() prior.", call. = FALSE)
    }
    list(mu = p$mu, sd = p$sd, source = "user")
  }

  theta_mu <- theta_sd <- numeric(length(pars))
  for (k in seq_along(pars)) {
    p <- take(pars[k], "lognormal", log(data_scale[[pars[k]]]), 2, "lognormal")
    theta_mu[k] <- p$mu
    theta_sd[k] <- p$sd
    record(pars[k], "lognormal", p$mu, p$sd, p$source)
  }

  beta_mu <- beta_sd <- numeric(length(est))
  for (j in seq_along(est)) {
    p <- take(est[j], "normal", 0, 1, "normal")
    beta_mu[j] <- p$mu
    beta_sd[j] <- p$sd
    record(est[j], "normal", p$mu, p$sd, p$source)
  }

  omega_sd <- numeric(length(model$iiv))
  for (e in seq_along(model$iiv)) {
    nm <- paste0("omega_", model$iiv[e])
    p <- if (!is.null(priors[[nm]])) take(nm, "half_normal", 0, 1, "half_normal")
         else take("omega", "half_normal", 0, 1, "half_normal")
    omega_sd[e] <- p$sd
    record(nm, "half_normal", 0, p$sd, p$source)
  }

  sigma_sd <- c(1, 0.5)
  err <- model$error
  if (err %in% c("additive", "combined")) {
    p <- take("sigma_add", "half_normal", 0, data_scale$dv_sd, "half_normal")
    sigma_sd[1] <- p$sd
    record("sigma_add", "half_normal", 0, p$sd, p$source)
  }
  if (err == "log") {
    p <- take("sigma_log", "half_normal", 0, 1, "half_normal")
    sigma_sd[1] <- p$sd
    record("sigma_log", "half_normal", 0, p$sd, p$source)
  }
  if (err %in% c("proportional", "combined")) {
    p <- take("sigma_prop", "half_normal", 0, 0.5, "half_normal")
    sigma_sd[2] <- p$sd
    record("sigma_prop", "half_normal", 0, p$sd, p$source)
  }
  lkj <- if (is.null(priors$lkj)) 2 else priors$lkj
  if (model$correlated) {
    record("correlation", "lkj", lkj, NA_real_, if (is.null(priors$lkj)) "default" else "user")
  }
  list(theta_mu = theta_mu, theta_sd = theta_sd, beta_mu = beta_mu, beta_sd = beta_sd,
       omega_sd = omega_sd, sigma_sd = sigma_sd, lkj = lkj,
       table = do.call(rbind, rows))
}
