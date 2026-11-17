# Validation: parameter recovery for 2-compartment models on simulated data
# with known true values (one replicate per scenario; not a coverage study).
# Run from the package root: Rscript inst/validation/recovery_2cmt.R
library(bayespk)

SEED <- 20261116
N_SUBJ <- 40
out_dir <- file.path("inst", "validation", "results")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

simulate <- function(route, truth, omega, sigma_prop, seed) {
  set.seed(seed)
  wt <- round(stats::rlnorm(N_SUBJ, log(70), 0.2), 1)
  rich <- c(0.25, 0.5, 1, 2, 3, 4, 6, 8, 12, 24, 36, 48)
  sparse <- c(1, 4, 12, 24, 48)
  rows <- list()
  for (i in seq_len(N_SUBJ)) {
    eta <- stats::rnorm(length(omega), 0, omega)
    names(eta) <- names(omega)
    par <- truth
    par[["CL"]] <- truth[["CL"]] * (wt[i] / 70)^0.75 * exp(eta[["CL"]])
    par[["V1"]] <- truth[["V1"]] * (wt[i] / 70)^1 * exp(eta[["V1"]])
    if ("KA" %in% names(omega)) par[["KA"]] <- truth[["KA"]] * exp(eta[["KA"]])
    times <- if (i %% 2 == 0) rich else sparse
    dose <- if (route == "iv") dose_regimen(500, rate = 250) else dose_regimen(500)
    conc <- pk_conc(times, dose, par, "2cmt", route)
    dv <- conc * (1 + stats::rnorm(length(conc), 0, sigma_prop))
    rows[[i]] <- rbind(
      data.frame(ID = i, TIME = 0, AMT = 500, RATE = dose$rate, DV = NA, EVID = 1, WT = wt[i]),
      data.frame(ID = i, TIME = times, AMT = 0, RATE = 0, DV = dv, EVID = 0, WT = wt[i])
    )
  }
  do.call(rbind, rows)
}

run <- function(route, truth, omega, sigma_prop, adapt_delta = 0.9) {
  d <- simulate(route, truth, omega, sigma_prop, SEED)
  mod <- pk_model("2cmt", route = route, iiv = names(omega), error = "proportional",
                  covariates = list(CL ~ (WT / 70)^0.75, V1 ~ (WT / 70)^b_wt))
  fit <- bpk_fit(mod, d, chains = 4, cores = 4, iter = 2000, seed = SEED, adapt_delta = adapt_delta)
  sm <- summary(fit)
  true <- c(truth, b_wt = 1, setNames(omega, paste0("omega_", names(omega))), sigma_prop = sigma_prop)
  tab <- data.frame(route = route, adapt_delta = adapt_delta, quantity = names(true), truth = unname(true))
  i <- match(tab$quantity, sm$variable)
  tab$q5 <- sm$q5[i]
  tab$q50 <- sm$q50[i]
  tab$q95 <- sm$q95[i]
  tab$in_90 <- tab$truth >= tab$q5 & tab$truth <= tab$q95
  dg <- bpk_diagnostics(fit)
  tab$divergent <- dg$divergent
  tab$rhat_max <- round(dg$rhat_max, 3)
  tab$seconds <- round(fit$seconds, 1)
  tab
}

res <- rbind(
  run("iv", c(CL = 4, V1 = 20, Q = 6, V2 = 60), c(CL = 0.3, V1 = 0.25), 0.15),
  run("oral", c(CL = 4, V1 = 20, Q = 6, V2 = 60, KA = 1), c(CL = 0.3, V1 = 0.25, KA = 0.4), 0.15),
  run("oral", c(CL = 4, V1 = 20, Q = 6, V2 = 60, KA = 1), c(CL = 0.3, V1 = 0.25, KA = 0.4), 0.15, adapt_delta = 0.99)
)
print(res, digits = 3)
cat("true values inside 90% intervals:", sum(res$in_90), "of", nrow(res), "\n")
write.csv(res, file.path(out_dir, "recovery-2cmt.csv"), row.names = FALSE)
