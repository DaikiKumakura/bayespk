#' Fit a Bayesian population pharmacokinetic model
#'
#' Samples the posterior with Stan (NUTS) using a precompiled closed-form
#' model. The data are a NONMEM-style data frame used as is.
#'
#' Data columns (case-insensitive): `ID`, `TIME`, `DV`, `AMT` (required);
#' `EVID`, `MDV`, `RATE`, `ADDL`, `II` (optional) and any covariates used in
#' the model. `"."` is read as missing. Doses are records with `EVID == 1`
#' (or `AMT > 0` when `EVID` is absent); observations are records with
#' `EVID == 0`, `MDV != 1` and a non-missing `DV`. Observations at or before
#' the first dose of a subject are dropped with a message. Not supported in
#' this version: steady-state records, reset events, modelled rates,
#' time-varying covariates and below-quantification records.
#'
#' @param model A model from [pk_model()].
#' @param data NONMEM-style data frame.
#' @param priors Priors from [pk_priors()]; unspecified ones get defaults.
#' @param chains,iter,warmup,cores,seed Passed to [rstan::sampling()].
#' @param adapt_delta Target acceptance rate of NUTS.
#' @param prior_only Logical; sample from the prior only (ignores `DV`).
#' @param ... Further arguments to [rstan::sampling()].
#' @return An object of class `bpk_fit`.
#' @examples
#' \donttest{
#' mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
#' fit <- bpk_fit(mod, bpk_example, chains = 2, iter = 1000, seed = 1)
#' summary(fit)
#' }
#' @export
bpk_fit <- function(model, data, priors = NULL, chains = 4, iter = 2000,
                    warmup = floor(iter / 2), cores = getOption("mc.cores", 1L),
                    seed = sample.int(.Machine$integer.max, 1), adapt_delta = 0.9,
                    prior_only = FALSE, ...) {
  if (!inherits(model, "bpk_model")) stop("`model` must come from pk_model().", call. = FALSE)
  prep <- prepare_data(model, data)
  if (prep$n_early > 0) {
    message(prep$n_early, " observation(s) at or before the first dose were dropped.")
  }
  if (length(prep$dropped)) {
    message(length(prep$dropped), " subject(s) without observations after a dose were dropped.")
  }
  scale <- data_scale(model, prep)
  pri <- resolve_priors(model, priors, scale)
  sdata <- stan_data(model, prep, pri, prior_only)
  init <- make_init(sdata, chains, seed)
  t0 <- Sys.time()
  sf <- rstan::sampling(stanmodels$popk, data = sdata, chains = chains, iter = iter,
                        warmup = warmup, cores = cores, seed = seed, init = init,
                        pars = c("mu_raw", "theta_raw", "zbar", "u"), include = FALSE,
                        control = list(adapt_delta = adapt_delta), ...)
  elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  out <- structure(list(stanfit = sf, model = model, prep = prep, priors = pri$table,
                        stan_data = sdata, seconds = elapsed, prior_only = prior_only,
                        call = match.call()),
                   class = "bpk_fit")
  warn_diagnostics(out)
  out
}

stan_data <- function(model, prep, pri, prior_only) {
  pars <- model$parameters
  terms <- model$covariates
  cols <- covariate_columns(terms, prep$cov)
  est <- !is.na(terms$name)
  offset <- matrix(0, prep$N, length(pars))
  for (j in which(!est)) {
    k <- match(terms$param[j], pars)
    offset[, k] <- offset[, k] + terms$value[j] * cols[, j]
  }
  list(
    N = prep$N, ncmt = if (model$structure == "1cmt") 1L else 2L,
    oral = as.integer(model$route == "oral"), K = length(pars),
    n_obs = nrow(prep$obs), obs_id = as.integer(prep$obs$sid),
    obs_time = prep$obs$time, dv = prep$obs$dv, cens = array(as.integer(prep$obs$cens), nrow(prep$obs)),
    n_dose = nrow(prep$dose), dose_time = prep$dose$time,
    dose_amt = prep$dose$amt, dose_rate = prep$dose$rate, dose_ii = prep$dose$ss_ii,
    dose_start = as.integer(prep$dose_start), dose_end = as.integer(prep$dose_end),
    n_eta = length(model$iiv), eta_par = array(match(model$iiv, pars), length(model$iiv)),
    corr = as.integer(model$correlated),
    n_beta = sum(est), beta_par = array(match(terms$param[est], pars), sum(est)),
    xbeta = cols[, est, drop = FALSE], cov_offset = offset,
    err = match(model$error, c("additive", "proportional", "combined", "log")),
    prior_theta_mu = pri$theta_mu, prior_theta_sd = pri$theta_sd,
    prior_beta_mu = array(pri$beta_mu, sum(est)), prior_beta_sd = array(pri$beta_sd, sum(est)),
    prior_omega_sd = array(pri$omega_sd, length(model$iiv)), prior_lkj = pri$lkj,
    prior_sigma_sd = pri$sigma_sd, prior_only = as.integer(prior_only),
    ka_fast = as.integer(isTRUE(model$ka_faster)),
    # Mean/deviation split for parameters with IIV except KA, whose individual
    # values are rarely well identified (benchmark-decouple.csv).
    decouple = array(as.integer(rep_len(getOption("bayespk.decouple", model$iiv != "KA"),
                                        length(model$iiv))), length(model$iiv))
  )
}

# Start near the prior location with small between-chain jitter.
# Initial log typical values near the prior medians; with ka_fast the KA entry
# is log(KA - rate), kept positive.
init_theta <- function(sdata) {
  lt <- sdata$prior_theta_mu + stats::rnorm(sdata$K, 0, 0.1)
  if (sdata$ka_fast == 1) {
    th <- exp(lt)
    K <- sdata$K
    rate <- if (sdata$ncmt == 1) th[1] / th[2] else {
      k10 <- th[1] / th[2]; k12 <- th[3] / th[2]; k21 <- th[3] / th[4]
      s <- k10 + k12 + k21
      (s + sqrt(s^2 - 4 * k10 * k21)) / 2
    }
    lt[K] <- log(max(th[K] - rate, 0.5 * th[K]))
  }
  lt
}

make_init <- function(sdata, chains, seed) {
  set.seed(seed)
  lapply(seq_len(chains), function(ch) {
    init <- list(
      mu_raw = init_theta(sdata),
      zbar = array(0, sdata$n_eta),
      beta = array(stats::rnorm(sdata$n_beta, 0, 0.05), sdata$n_beta),
      omega = array(stats::runif(sdata$n_eta, 0.2, 0.4), sdata$n_eta),
      u = matrix(0, sdata$n_eta, sdata$N - 1),
      sigma = array(if (sdata$err == 1) 0.5 * stats::sd(sdata$dv) else 0.2,
                    if (sdata$err == 3) 2 else 1)
    )
    if (sdata$err == 3) init$sigma <- c(0.1 * stats::sd(sdata$dv), 0.2)
    if (sdata$corr == 1) init$L_corr <- diag(sdata$n_eta)
    init
  })
}

# Population-level draws with readable names.
#' Posterior draws of population parameters
#'
#' @param x A `bpk_fit`.
#' @return A `draws_df` (posterior package) with typical values on the natural
#'   scale, estimated covariate effects, standard deviations of between-subject
#'   variability (log scale), correlations and residual error.
#' @examples
#' \donttest{
#' mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
#' fit <- bpk_fit(mod, bpk_example, chains = 2, iter = 1000, seed = 1)
#' head(posterior::as_draws_df(bpk_draws(fit)))
#' }
#' @export
bpk_draws <- function(x) {
  sf <- x$stanfit
  m <- x$model
  arr <- function(p) rstan::extract(sf, pars = p, permuted = FALSE)
  pieces <- list()
  lt <- arr("log_theta")
  dimnames(lt)[[3]] <- m$parameters
  pieces$theta <- exp(lt)
  est <- m$covariates$name[!is.na(m$covariates$name)]
  if (length(est)) {
    b <- arr("beta")
    dimnames(b)[[3]] <- est
    pieces$beta <- b
  }
  if (length(m$iiv)) {
    o <- arr("omega")
    dimnames(o)[[3]] <- paste0("omega_", m$iiv)
    pieces$omega <- o
  }
  if (m$correlated) {
    L <- rstan::extract(sf, pars = "L_corr", permuted = FALSE)
    ne <- length(m$iiv)
    pairs <- utils::combn(ne, 2)
    cr <- array(NA_real_, c(dim(L)[1:2], ncol(pairs)),
                dimnames = list(NULL, NULL, paste0("cor_", m$iiv[pairs[1, ]], "_", m$iiv[pairs[2, ]])))
    for (it in seq_len(dim(L)[1])) for (ch in seq_len(dim(L)[2])) {
      Lm <- matrix(L[it, ch, ], ne, ne)
      R <- Lm %*% t(Lm)
      cr[it, ch, ] <- R[t(pairs)]
    }
    pieces$cor <- cr
  }
  s <- arr("sigma")
  dimnames(s)[[3]] <- switch(m$error, additive = "sigma_add", proportional = "sigma_prop",
                             combined = c("sigma_add", "sigma_prop"), log = "sigma_log")
  pieces$sigma <- s
  all <- do.call(abind3, unname(pieces))
  posterior::as_draws_df(posterior::as_draws_array(all))
}

abind3 <- function(...) {
  xs <- list(...)
  d <- dim(xs[[1]])
  n3 <- vapply(xs, function(a) dim(a)[3], integer(1))
  out <- array(NA_real_, c(d[1], d[2], sum(n3)),
               dimnames = list(NULL, NULL, unlist(lapply(xs, function(a) dimnames(a)[[3]]))))
  pos <- 0
  for (a in xs) {
    out[, , pos + seq_len(dim(a)[3])] <- a
    pos <- pos + dim(a)[3]
  }
  out
}

#' Sampler diagnostics
#'
#' @param x A `bpk_fit`.
#' @return A list with the number of divergent transitions, iterations at the
#'   maximum tree depth, E-BFMI per chain, maximum R-hat and minimum bulk and
#'   tail effective sample sizes of the population parameters.
#' @examples
#' \donttest{
#' mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
#' fit <- bpk_fit(mod, bpk_example, chains = 2, iter = 1000, seed = 1)
#' bpk_diagnostics(fit)
#' }
#' @export
bpk_diagnostics <- function(x) {
  sp <- rstan::get_sampler_params(x$stanfit, inc_warmup = FALSE)
  div <- sum(vapply(sp, function(s) sum(s[, "divergent__"]), numeric(1)))
  maxdepth <- x$stanfit@stan_args[[1]]$control$max_treedepth
  if (is.null(maxdepth)) maxdepth <- 10
  td <- sum(vapply(sp, function(s) sum(s[, "treedepth__"] >= maxdepth), numeric(1)))
  ebfmi <- vapply(sp, function(s) {
    e <- s[, "energy__"]
    sum(diff(e)^2) / sum((e - mean(e))^2)
  }, numeric(1))
  sm <- posterior::summarise_draws(bpk_draws(x), "rhat", "ess_bulk", "ess_tail")
  list(divergent = div, max_treedepth = td, ebfmi = ebfmi,
       rhat_max = max(sm$rhat, na.rm = TRUE),
       rhat_high = sm$variable[!is.na(sm$rhat) & sm$rhat > 1.01],
       chains_apart = chains_apart(x),
       ess_bulk_min = min(sm$ess_bulk, na.rm = TRUE),
       ess_tail_min = min(sm$ess_tail, na.rm = TRUE))
}

# Parameters whose chain medians differ by more than twice the average
# within-chain standard deviation: chains stuck in different modes. Returns a
# named character vector of chain medians (empty when chains agree).
chains_apart <- function(x) chains_apart_draws(posterior::as_draws_array(bpk_draws(x)))

chains_apart_draws <- function(a) {
  if (posterior::nchains(a) < 2) return(character())
  out <- character()
  for (v in posterior::variables(a)) {
    m <- matrix(as.numeric(a[, , v]), ncol = posterior::nchains(a))
    med <- apply(m, 2, stats::median)
    within <- mean(apply(m, 2, stats::sd))
    if (is.finite(within) && within > 0 && diff(range(med)) > 2 * within) {
      out[v] <- paste(signif(med, 3), collapse = ", ")
    }
  }
  out
}

warn_diagnostics <- function(x) {
  d <- bpk_diagnostics(x)
  msg <- character()
  if (d$divergent > 0) msg <- c(msg, paste0(d$divergent, " divergent transition(s); consider a higher adapt_delta or more informative priors."))
  if (d$max_treedepth > 0) msg <- c(msg, paste0(d$max_treedepth, " iteration(s) reached the maximum tree depth."))
  if (any(d$ebfmi < 0.3)) msg <- c(msg, "E-BFMI below 0.3 in at least one chain.")
  if (d$rhat_max > 1.01) {
    msg <- c(msg, sprintf("R-hat > 1.01 (maximum %.3f) for %s; chains have not mixed. Run longer (iter) before using the results.",
                          d$rhat_max, paste(d$rhat_high, collapse = ", ")))
  }
  if (length(d$chains_apart)) {
    msg <- c(msg, paste0(
      "Chains settled in different regions for ", paste(names(d$chains_apart), collapse = ", "),
      " (chain medians: ", paste(sprintf("%s %s", names(d$chains_apart), d$chains_apart), collapse = "; "),
      "). The posterior probably has more than one mode, which longer runs do not fix. ",
      "In oral models this is usually flip-flop: KA close to a disposition rate, so the two can swap. ",
      "Predicted concentrations are similar in each mode, but parameter summaries are not valid; ",
      "use informative priors on the parameters listed."))
  }
  if (d$ess_bulk_min < 400 || d$ess_tail_min < 400) {
    msg <- c(msg, sprintf("Smallest effective sample size %.0f (bulk) / %.0f (tail) < 400.", d$ess_bulk_min, d$ess_tail_min))
  }
  for (m in msg) warning(m, call. = FALSE)
  invisible(d)
}

#' @export
print.bpk_fit <- function(x, digits = 3, ...) {
  print(x$model)
  cat(sprintf("  data: %d subjects, %d observations, %d doses\n",
              x$prep$N, nrow(x$prep$obs), nrow(x$prep$dose)))
  cat(sprintf("  sampling: %d chains, %.1f s\n", length(x$stanfit@stan_args), x$seconds))
  if (x$prior_only) cat("  (prior only)\n")
  print(summary(x), digits = digits)
  invisible(x)
}

#' Summarise a fit
#'
#' @param object A `bpk_fit`.
#' @param probs Quantiles to report.
#' @param ... Unused.
#' @return A data frame of posterior summaries and convergence diagnostics.
#' @method summary bpk_fit
#' @examples
#' \donttest{
#' mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
#' fit <- bpk_fit(mod, bpk_example, chains = 2, iter = 1000, seed = 1)
#' summary(fit, probs = c(0.025, 0.5, 0.975))
#' }
#' @export
summary.bpk_fit <- function(object, probs = c(0.05, 0.5, 0.95), ...) {
  dr <- bpk_draws(object)
  qf <- function(x) stats::quantile(x, probs = probs, names = FALSE)
  sm <- posterior::summarise_draws(dr, mean = mean, sd = stats::sd, q = qf,
                                   "rhat", "ess_bulk", "ess_tail")
  qcols <- grep("^q(\\.)?[0-9]+$", names(sm))
  if (length(qcols) == length(probs)) names(sm)[qcols] <- paste0("q", probs * 100)
  sm <- as.data.frame(sm)
  class(sm) <- c("bpk_summary", "data.frame")
  sm
}

#' @export
print.bpk_summary <- function(x, digits = 3, ...) {
  y <- x
  class(y) <- "data.frame"
  num <- vapply(y, is.numeric, logical(1))
  y[num] <- lapply(y[num], signif, digits = digits)
  print(y, row.names = FALSE)
  invisible(x)
}

#' Prior sensitivity by power-scaling
#'
#' Calls [priorsense::powerscale_sensitivity()] on the population parameters.
#'
#' @param x A `bpk_fit`.
#' @param ... Passed to [priorsense::powerscale_sensitivity()].
#' @return The result of [priorsense::powerscale_sensitivity()].
#' @examples
#' \donttest{
#' mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"))
#' fit <- bpk_fit(mod, bpk_example, chains = 2, iter = 1000, seed = 1)
#' if (requireNamespace("priorsense", quietly = TRUE)) prior_sensitivity(fit)
#' }
#' @export
prior_sensitivity <- function(x, ...) {
  if (!requireNamespace("priorsense", quietly = TRUE)) {
    stop("Install the 'priorsense' package to use prior_sensitivity().", call. = FALSE)
  }
  pop <- posterior::as_draws_df(bpk_draws(x))
  extra <- posterior::subset_draws(posterior::as_draws_df(x$stanfit),
                                   variable = c("lprior", "log_lik"))
  d <- posterior::bind_draws(pop, extra)
  priorsense::powerscale_sensitivity(d, variable = posterior::variables(pop), ...)
}
