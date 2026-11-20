cases <- list(
  list(s = "1cmt", r = "iv", par = c(CL = 3, V = 30), rate = 0),
  list(s = "1cmt", r = "iv", par = c(CL = 3, V = 30), rate = 50),
  list(s = "1cmt", r = "oral", par = c(CL = 3, V = 30, KA = 1.2), rate = 0),
  list(s = "1cmt", r = "oral", par = c(CL = 3, V = 30, KA = 0.1), rate = 0),   # KA = k
  list(s = "2cmt", r = "iv", par = c(CL = 4, V1 = 20, Q = 6, V2 = 60), rate = 0),
  list(s = "2cmt", r = "iv", par = c(CL = 4, V1 = 20, Q = 6, V2 = 60), rate = 100),
  list(s = "2cmt", r = "oral", par = c(CL = 4, V1 = 20, Q = 6, V2 = 60, KA = 1), rate = 0)
)

test_that("steady state equals the sum of many earlier doses", {
  ii <- 12
  t <- c(-11, -6, -0.5, 0.5, 1, 3, 6, 11.9, 20, 30)
  for (cs in cases) {
    ss <- pk_conc(t, dose_regimen(100, ii = ii, ss = TRUE, rate = cs$rate), cs$par, cs$s, cs$r)
    many <- pk_conc(t, dose_regimen(100, ii = ii, n = 400, start = -399 * ii, rate = cs$rate),
                    cs$par, cs$s, cs$r)
    expect_equal(ss, many, tolerance = 1e-8, info = paste(cs$s, cs$r, cs$rate, cs$par[length(cs$par)]))
  }
})

test_that("steady state agrees with rxode2", {
  skip_if_not_installed("rxode2")
  m1 <- rxode2::rxode2("d/dt(depot) = -KA * depot
d/dt(centr) = KA * depot - CL / V * centr
cp = centr / V")
  ev <- rxode2::et(amt = 100, ii = 12, ss = 1, cmt = "depot")
  ev <- rxode2::et(ev, c(0.5, 2, 6, 11))
  par <- c(CL = 3, V = 30, KA = 1.2)
  ode <- rxode2::rxSolve(m1, params = par, events = ev, atol = 1e-12, rtol = 1e-12,
                         returnType = "data.frame")
  cf <- pk_conc(c(0.5, 2, 6, 11), dose_regimen(100, ii = 12, ss = TRUE), par, "1cmt", "oral")
  expect_equal(cf, ode$cp[match(c(0.5, 2, 6, 11), ode$time)], tolerance = 1e-6)
})

test_that("SS = 1 records are read, reset earlier doses and match Stan", {
  skip_on_cran()
  set.seed(5)
  times <- c(-0.25, 1, 2, 4, 8, 11.5)
  d <- do.call(rbind, lapply(1:12, function(i) {
    par <- c(CL = 3 * exp(rnorm(1, 0, 0.2)), V = 30, KA = 1.2)
    conc <- pk_conc(times, dose_regimen(100, ii = 12, ss = TRUE), par, "1cmt", "oral")
    rbind(data.frame(ID = i, TIME = -48, AMT = 50, II = 0, SS = 0, DV = NA, EVID = 1),
          data.frame(ID = i, TIME = 0, AMT = 100, II = 12, SS = 1, DV = NA, EVID = 1),
          data.frame(ID = i, TIME = times, AMT = 0, II = 0, SS = 0,
                     DV = conc * (1 + rnorm(length(times), 0, 0.1)), EVID = 0))
  }))
  mod <- pk_model("1cmt", "oral", iiv = "CL")
  expect_message(prep <- bayespk:::prepare_data(mod, d), "steady-state")
  expect_equal(nrow(prep$obs), 12 * length(times))       # pre-dose trough kept
  expect_true(all(prep$dose$ss_ii == 12))
  fit <- suppressMessages(suppressWarnings(bpk_fit(mod, d, chains = 2, iter = 600, seed = 1, refresh = 0)))
  ex <- rstan::extract(fit$stanfit, c("log_lik", "log_par", "sigma"))
  obs <- fit$prep$obs
  for (n in 1:6) {
    par <- setNames(as.list(exp(ex$log_par[3, obs$sid[n], ])), mod$parameters)
    c <- bayespk:::dose_contrib_r(obs$time[n], 100, 0, 12, par, "1cmt", "oral")
    expect_equal(ex$log_lik[3, n], dnorm(obs$dv[n], c, ex$sigma[3, 1] * c, log = TRUE), tolerance = 1e-6)
  }
  sm <- summary(fit)
  expect_lt(abs(log(sm$q50[sm$variable == "CL"] / 3)), 0.15)
})
