# Recovery checks for the residual-error models and censored data. Moderate
# data sets so that the posterior is informative; not exhaustive (see
# inst/validation).

sim_obs <- function(n = 20, seed = 1, sigma = 0.15, error = c("log", "proportional")) {
  error <- match.arg(error)
  set.seed(seed)
  times <- c(0.5, 1, 2, 4, 6, 8, 12, 24, 36)
  do.call(rbind, lapply(seq_len(n), function(i) {
    par <- c(CL = 3 * exp(rnorm(1, 0, 0.2)), V = 30, KA = 1.2)
    conc <- pk_conc(times, dose_regimen(100), par, "1cmt", "oral")
    e <- rnorm(length(times), 0, sigma)
    dv <- if (error == "log") conc * exp(e) else conc * (1 + e)
    rbind(data.frame(ID = i, TIME = 0, AMT = 100, DV = NA, EVID = 1),
          data.frame(ID = i, TIME = times, AMT = 0, DV = dv, EVID = 0))
  }))
}

fit_q <- function(model, data, ...) {
  suppressMessages(suppressWarnings(bpk_fit(model, data, chains = 2, iter = 800, seed = 2,
                                            refresh = 0, ...)))
}

test_that("log-scale error recovers the simulated values", {
  skip_on_cran()
  d <- sim_obs(error = "log")
  fit <- fit_q(pk_model("1cmt", "oral", iiv = "CL", error = "log"), d)
  sm <- summary(fit)
  get <- function(v) sm$q50[sm$variable == v]
  expect_lt(abs(log(get("CL") / 3)), 0.15)
  expect_lt(abs(log(get("V") / 30)), 0.1)
  expect_lt(abs(get("sigma_log") - 0.15), 0.03)
})

test_that("M3 censoring uses the normal CDF at the quantification limit", {
  skip_on_cran()
  d <- sim_obs(n = 20, seed = 4, error = "proportional")
  lloq <- 0.8
  below <- d$EVID == 0 & d$DV < lloq
  expect_gt(sum(below), 20)
  d$CENS <- 0
  d$CENS[below] <- 1
  d$DV[below] <- lloq
  mod <- pk_model("1cmt", "oral", iiv = "CL")
  expect_message(bayespk:::prepare_data(mod, d), "M3")
  fit <- fit_q(mod, d)
  ex <- rstan::extract(fit$stanfit, c("log_lik", "log_par", "sigma"))
  obs <- fit$prep$obs
  dose <- fit$prep$dose
  for (n in c(which(obs$cens == 1)[1:3], which(obs$cens == 0)[1:3])) {
    i <- obs$sid[n]
    s <- 5
    par <- setNames(as.list(exp(ex$log_par[s, i, ])), mod$parameters)
    c <- sum(vapply(which(dose$sid == i), function(j)
      bayespk:::dose_conc_r(obs$time[n] - dose$time[j], dose$amt[j], dose$rate[j], par, "1cmt", "oral"),
      numeric(1)))
    sd_y <- ex$sigma[s, 1] * c
    expected <- if (obs$cens[n] == 1) pnorm(lloq, c, sd_y, log.p = TRUE) else dnorm(obs$dv[n], c, sd_y, log = TRUE)
    expect_equal(ex$log_lik[s, n], expected, tolerance = 1e-6)
  }
  sm <- summary(fit)
  expect_lt(abs(log(sm$q50[sm$variable == "CL"] / 3)), 0.15)
})
