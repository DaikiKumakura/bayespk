test_that("chains in different modes are detected, mixed chains are not", {
  set.seed(1)
  arr <- function(...) {
    v <- list(...)
    a <- array(unlist(v), c(100, 4, length(v)), dimnames = list(NULL, NULL, names(v)))
    posterior::as_draws_array(a)
  }
  mixed <- arr(KA = rnorm(400))
  expect_length(bayespk:::chains_apart_draws(mixed), 0)
  stuck <- matrix(rnorm(400, sd = 0.1), 100, 4)
  stuck[, 3:4] <- stuck[, 3:4] + 1
  out <- bayespk:::chains_apart_draws(arr(KA = stuck, CL = rnorm(400)))
  expect_named(out, "KA")
})

test_that("random effects follow N(0, omega) under the prior (Helmert parameterisation)", {
  skip_on_cran()
  mod <- pk_model("1cmt", "oral", iiv = c("CL", "V"), correlated = FALSE)
  fit <- suppressWarnings(bpk_fit(mod, bpk_example, prior_only = TRUE, chains = 2, iter = 2000,
                                  seed = 3, refresh = 0,
                                  priors = pk_priors(omega = half_normal(0.5))))
  ex <- rstan::extract(fit$stanfit, c("log_par", "log_theta", "omega"))
  for (k in 1:2) {
    z <- sweep(ex$log_par[, , k], 1, ex$log_theta[, k]) / ex$omega[, k]
    expect_lt(abs(mean(z)), 0.05)
    expect_lt(abs(stats::sd(as.vector(z)) - 1), 0.05)
    # each subject's standardised effect is N(0, 1), not shrunk toward the mean
    expect_lt(abs(stats::sd(z[, 1]) - 1), 0.1)
  }
})
