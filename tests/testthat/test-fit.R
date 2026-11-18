# Short fits that exercise every code path; not tests of accuracy (see
# inst/validation for those).

sim_data <- function(structure, route, rate = 0, n = 8, seed = 1) {
  set.seed(seed)
  par0 <- if (structure == "1cmt") c(CL = 3, V = 30, KA = 1.2) else c(CL = 3, V1 = 20, Q = 5, V2 = 50, KA = 1.2)
  times <- c(0.5, 1, 2, 4, 8, 12, 24)
  rows <- lapply(seq_len(n), function(i) {
    par <- par0
    par[["CL"]] <- par0[["CL"]] * exp(rnorm(1, 0, 0.3))
    conc <- pk_conc(times, dose_regimen(100, rate = rate), par, structure, route)
    rbind(data.frame(ID = i, TIME = 0, AMT = 100, RATE = rate, DV = NA, EVID = 1, WT = 60 + 2 * i),
          data.frame(ID = i, TIME = times, AMT = 0, RATE = 0, DV = conc * exp(rnorm(7, 0, 0.1)),
                     EVID = 0, WT = 60 + 2 * i))
  })
  do.call(rbind, rows)
}

quick_fit <- function(model, data, ...) {
  suppressWarnings(bpk_fit(model, data, chains = 1, iter = 300, seed = 1, refresh = 0, ...))
}

test_that("fits run for each structure, route and error model", {
  skip_on_cran()
  specs <- list(
    list(pk_model("1cmt", "oral", iiv = c("CL", "V"), error = "proportional"), sim_data("1cmt", "oral")),
    list(pk_model("1cmt", "iv", error = "additive"), sim_data("1cmt", "iv", rate = 50)),
    list(pk_model("2cmt", "iv", iiv = c("CL", "V1"), error = "combined", correlated = TRUE),
         sim_data("2cmt", "iv", rate = 50)),
    list(pk_model("2cmt", "oral", iiv = "CL", error = "log",
                  covariates = list(CL ~ (WT / 70)^b_wt)), sim_data("2cmt", "oral"))
  )
  for (s in specs) {
    fit <- quick_fit(s[[1]], s[[2]])
    expect_s3_class(fit, "bpk_fit")
    sm <- summary(fit)
    expect_true(all(s[[1]]$parameters %in% sm$variable))
    expect_true(all(is.finite(sm$q50)))
    pr <- predict(fit, ndraws = 50)
    expect_equal(nrow(pr), nrow(fit$prep$obs))
    expect_true(all(pr$q95 >= pr$q5))
  }
})

test_that("correlations, prior-only sampling and new-regimen predictions work", {
  skip_on_cran()
  d <- sim_data("1cmt", "oral")
  fit <- quick_fit(pk_model("1cmt", "oral", iiv = c("CL", "V"), correlated = TRUE), d)
  expect_true("cor_CL_V" %in% summary(fit)$variable)
  pp <- predict(fit, regimen = dose_regimen(100, ii = 12, n = 2), ndraws = 100)
  expect_equal(ncol(pp), 4)
  expect_true(any(pp$q95 > pp$q5))
  pri <- quick_fit(pk_model("1cmt", "oral"), d,
                   priors = pk_priors(CL = lognormal(log(3), 0.1)), prior_only = TRUE)
  cl <- suppressWarnings(summary(pri))
  expect_lt(abs(log(cl$q50[cl$variable == "CL"]) - log(3)), 0.1)
})

test_that("prior sensitivity runs", {
  skip_on_cran()
  skip_if_not_installed("priorsense")
  fit <- quick_fit(pk_model("1cmt", "oral", iiv = "CL"), sim_data("1cmt", "oral"))
  ps <- prior_sensitivity(fit)
  expect_true(nrow(ps) > 0)
})

test_that("ka_faster keeps typical KA above the disposition rate", {
  skip_on_cran()
  expect_error(pk_model("1cmt", "iv", ka_faster = TRUE), "oral")
  fit <- quick_fit(pk_model("2cmt", "oral", iiv = "CL", ka_faster = TRUE), sim_data("2cmt", "oral"))
  dr <- posterior::as_draws_matrix(bpk_draws(fit))
  k10 <- dr[, "CL"] / dr[, "V1"]; k12 <- dr[, "Q"] / dr[, "V1"]; k21 <- dr[, "Q"] / dr[, "V2"]
  s <- k10 + k12 + k21
  alpha <- (s + sqrt(s^2 - 4 * k10 * k21)) / 2
  expect_true(all(dr[, "KA"] > alpha))
})

test_that("plots draw without error and predictions keep their class", {
  skip_on_cran()
  fit <- quick_fit(pk_model("1cmt", "oral", iiv = c("CL", "V")), bpk_example)
  pdf(NULL)
  on.exit(grDevices::dev.off())
  expect_invisible(plot(fit))
  expect_invisible(plot(fit, type = "obs_pred"))
  expect_invisible(plot(fit, type = "trace"))
  pp <- predict(fit, regimen = dose_regimen(100, ii = 12, n = 3), ndraws = 50)
  expect_s3_class(pp, "bpk_prediction")
  expect_s3_class(pp, "data.frame")
  expect_invisible(plot(pp, log = TRUE))
  expect_equal(nrow(bpk_example[bpk_example$EVID == 1, ]), 30)
})

test_that("individual predictions on a time grid cover every subject", {
  skip_on_cran()
  fit <- quick_fit(pk_model("1cmt", "oral", iiv = "CL"), bpk_example)
  g <- predict(fit, times = c(1, 2, 3), ndraws = 20)
  expect_equal(nrow(g), 3 * length(unique(bpk_example$ID)))
  expect_true(all(is.na(g$DV)))
})
