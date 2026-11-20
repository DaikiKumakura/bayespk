test_that("covariate formulas are parsed", {
  m <- pk_model("2cmt", "oral", iiv = c("CL", "V1"),
                covariates = list(CL ~ (WT / 70)^0.75 * (CRCL / 100)^b_crcl,
                                  V1 ~ (WT / 70),
                                  KA ~ exp(b_age * (AGE - 40)),
                                  CL ~ (SEX == 1)^b_sex))
  tm <- m$covariates
  expect_equal(nrow(tm), 5)
  expect_equal(tm$type, c("power", "power", "power", "linear", "cat"))
  expect_equal(tm$value[1:3], c(0.75, NA, 1))
  expect_equal(tm$name[!is.na(tm$name)], c("b_crcl", "b_age", "b_sex"))
})

test_that("bad model specifications are refused", {
  expect_error(pk_model("1cmt", iiv = "V1"), "Unknown parameter")
  expect_error(pk_model("1cmt", covariates = list(V1 ~ (WT / 70))), "Unknown parameter")
  expect_error(pk_model("1cmt", covariates = list(CL ~ log(WT))), "Cannot read")
  expect_error(pk_model("1cmt", covariates = list(CL ~ (SEX == 1)^0.5)), "must be estimated")
})

nm <- data.frame(
  ID = c(1, 1, 1, 1, 2, 2, 2),
  TIME = c(0, 0, 1, 4, 0, 2, 6),
  AMT = c(".", "100", ".", ".", "100", ".", "."),
  DV = c("0.5", ".", "3.1", "1.9", ".", "2.2", "1.1"),
  EVID = c(0, 1, 0, 0, 1, 0, 0),
  WT = c(70, 70, 70, 70, 80, 80, 80)
)

test_that("NONMEM-style data are read", {
  m <- pk_model("1cmt", "iv", covariates = list(CL ~ (WT / 70)^0.75))
  p <- bayespk:::prepare_data(m, nm)
  expect_equal(p$N, 2)
  expect_equal(nrow(p$obs), 4)          # pre-dose record dropped
  expect_equal(p$n_early, 1)
  expect_equal(p$dose$amt, c(100, 100))
  expect_equal(p$cov$WT, c(70, 80))
})

test_that("ADDL is expanded", {
  d <- data.frame(ID = 1, TIME = c(0, 30), AMT = c(10, 0), DV = c(NA, 1),
                  EVID = c(1, 0), ADDL = c(2, 0), II = c(12, 0))
  p <- bayespk:::prepare_data(pk_model("1cmt"), d)
  expect_equal(p$dose$time, c(0, 12, 24))
})

test_that("unsupported data are refused", {
  m <- pk_model("1cmt")
  bad <- nm
  bad$WT[3] <- 75
  expect_error(bayespk:::prepare_data(pk_model("1cmt", covariates = list(CL ~ (WT / 70)^0.75)), bad),
               "changes within subject")
  ss <- nm
  ss$SS <- 0
  ss$SS[2] <- 2
  expect_error(bayespk:::prepare_data(m, ss), "Only SS = 1")
  ss$SS[2] <- 1
  expect_error(bayespk:::prepare_data(m, ss), "positive II")
  inf <- nm
  inf$RATE <- 0
  inf$RATE[2] <- 50
  expect_error(bayespk:::prepare_data(pk_model("1cmt", "oral"), inf), "Infusions")
})

test_that("priors are resolved with defaults and user values", {
  m <- pk_model("1cmt", "oral", iiv = c("CL", "V"), covariates = list(CL ~ (WT / 70)^b_wt))
  scale <- list(CL = 5, V = 50, KA = 1, dv_sd = 2)
  r <- bayespk:::resolve_priors(m, pk_priors(CL = lognormal(log(4), 0.3), b_wt = normal(0.75, 0.1)), scale)
  expect_equal(r$theta_mu, c(log(4), log(50), log(1)))
  expect_equal(r$theta_sd, c(0.3, 2, 2))
  expect_equal(r$beta_mu, 0.75)
  expect_equal(r$table$source[1:2], c("user", "default"))
  expect_error(bayespk:::resolve_priors(m, pk_priors(V2 = lognormal(0, 1)), scale), "not in the model")
  expect_error(bayespk:::resolve_priors(m, pk_priors(CL = normal(0, 1)), scale), "lognormal")
})
