# Closed-form solutions against rxode2 ODE solutions (tight tolerances).

ode_conc <- function(structure, route, par, doses, times) {
  code <- if (structure == "1cmt") {
    "d/dt(depot) = -KA * depot
     d/dt(centr) = KA * depot - CL / V * centr
     cp = centr / V"
  } else {
    "d/dt(depot) = -KA * depot
     d/dt(centr) = KA * depot - CL / V1 * centr - Q / V1 * centr + Q / V2 * periph
     d/dt(periph) = Q / V1 * centr - Q / V2 * periph
     cp = centr / V1"
  }
  m <- rxode2::rxode2(code)
  if (is.null(par[["KA"]])) par[["KA"]] <- 1
  ev <- rxode2::et()
  cmt <- if (route == "oral") "depot" else "centr"
  for (j in seq_len(nrow(doses))) {
    if (doses$rate[j] > 0) {
      ev <- rxode2::et(ev, time = doses$time[j], amt = doses$amt[j], rate = doses$rate[j], cmt = cmt)
    } else {
      ev <- rxode2::et(ev, time = doses$time[j], amt = doses$amt[j], cmt = cmt)
    }
  }
  ev <- rxode2::et(ev, times)
  s <- rxode2::rxSolve(m, params = unlist(par), events = ev, atol = 1e-12, rtol = 1e-12,
                       returnType = "data.frame")
  s$cp[match(times, s$time)]
}

cases <- list(
  list("1cmt", "iv", c(CL = 3, V = 40), dose_regimen(100, ii = 12, n = 3)),
  list("1cmt", "iv", c(CL = 3, V = 40), dose_regimen(100, ii = 12, n = 3, rate = 50)),
  list("1cmt", "oral", c(CL = 3, V = 40, KA = 1.3), dose_regimen(100, ii = 12, n = 3)),
  list("2cmt", "iv", c(CL = 3, V1 = 20, Q = 5, V2 = 60), dose_regimen(100, ii = 12, n = 3)),
  list("2cmt", "iv", c(CL = 3, V1 = 20, Q = 5, V2 = 60), dose_regimen(100, ii = 24, n = 2, rate = 25)),
  list("2cmt", "oral", c(CL = 3, V1 = 20, Q = 5, V2 = 60, KA = 0.8), dose_regimen(100, ii = 12, n = 3))
)

test_that("closed-form concentrations agree with rxode2 ODE solutions", {
  skip_if_not_installed("rxode2")
  times <- c(0.1, 0.5, 1, 2, 3.5, 4, 6, 11.9, 12.3, 18, 24.7, 30, 47, 60)
  for (cs in cases) {
    for (scale in c(0.5, 1, 2)) {
      par <- cs[[3]]
      par["CL"] <- par["CL"] * scale
      rates <- if (cs[[2]] != "oral") NA_real_ else if (cs[[1]] == "1cmt") {
        c(par[["KA"]], par[["CL"]] / par[["V"]])
      } else {
        k10 <- par[["CL"]] / par[["V1"]]
        k12 <- par[["Q"]] / par[["V1"]]
        k21 <- par[["Q"]] / par[["V2"]]
        total <- k10 + k12 + k21
        spread <- sqrt(total^2 - 4 * k10 * k21)
        c(par[["KA"]], (total + spread) / 2, (total - spread) / 2)
      }
      for (ka in rates) {
        if (is.finite(ka)) par["KA"] <- ka
        for (dose_scale in c(0.5, 2)) {
          doses <- cs[[4]]
          doses$amt <- doses$amt * dose_scale
          cf <- pk_conc(times, doses, par, cs[[1]], cs[[2]])
          ode <- ode_conc(cs[[1]], cs[[2]], as.list(par), doses, times)
          expect_lt(max(abs(cf - ode) / pmax(ode, 1e-8)), 1e-8,
                    label = paste(cs[[1]], cs[[2]], scale, ka, dose_scale))
        }
      }
    }
  }
})

test_that("vectors of parameters give one concentration per parameter set", {
  cl <- c(2, 3, 4)
  for (cs in cases) {
    par <- as.list(cs[[3]])
    par$CL <- cl
    d <- cs[[4]]
    for (tau in c(0.5, 1, 30)) {
      vec <- bayespk:::dose_conc_r(tau, d$amt[1], d$rate[1], par, cs[[1]], cs[[2]])
      one <- vapply(cl, function(x) {
        p <- par
        p$CL <- x
        bayespk:::dose_conc_r(tau, d$amt[1], d$rate[1], p, cs[[1]], cs[[2]])
      }, numeric(1))
      expect_equal(vec, one)
    }
  }
})

test_that("concentration is zero before the first dose", {
  expect_equal(pk_conc(c(-1, 0), dose_regimen(100), c(CL = 1, V = 10), "1cmt", "iv"), c(0, 10))
})

test_that("missing parameters are refused", {
  expect_error(pk_conc(1, dose_regimen(1), c(CL = 1), "1cmt", "iv"), "must contain")
})
