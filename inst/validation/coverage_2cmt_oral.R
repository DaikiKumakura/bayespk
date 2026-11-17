# Validation: repeated-replicate recovery for the 2-compartment oral model,
# comparing two sampling designs with the same true values.
#   design "original": half the subjects rich (first sample 0.25 h), half sparse (first sample 1 h)
#   design "absorption": every subject also sampled at 0.25, 0.5, 1 and 2 h
# Reports coverage of 90% intervals and the median relative error of the
# posterior median across replicates.
# Run from the package root: Rscript inst/validation/coverage_2cmt_oral.R <n_reps> <workers> [ka_faster|none] [iter]
# With the third argument "ka_faster", fits use pk_model(ka_faster = TRUE), only
# the original design is run, and files get the suffix "-ka-faster".
args <- commandArgs(TRUE)
N_REPS <- if (length(args) >= 1) as.integer(args[1]) else 20
WORKERS <- if (length(args) >= 2) as.integer(args[2]) else 8
KA_FASTER <- length(args) >= 3 && args[3] == "ka_faster"
ITER <- if (length(args) >= 4) as.integer(args[4]) else 1500
SUFFIX <- paste0(if (KA_FASTER) "-ka-faster" else "", if (ITER != 1500) paste0("-iter", ITER) else "")
SEED <- 20261116
N_SUBJ <- 40
TRUTH <- c(CL = 4, V1 = 20, Q = 6, V2 = 60, KA = 1)
OMEGA <- c(CL = 0.3, V1 = 0.25, KA = 0.4)
SIGMA <- 0.15
out_dir <- file.path("inst", "validation", "results")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

one_rep <- function(job, seed) {
  library(bayespk)
  r <- job$rep
  design <- job$design
  set.seed(seed + r)                     # same subjects and noise for both designs
  wt <- round(stats::rlnorm(N_SUBJ, log(70), 0.2), 1)
  rich <- c(0.25, 0.5, 1, 2, 3, 4, 6, 8, 12, 24, 36, 48)
  sparse <- c(1, 4, 12, 24, 48)
  rows <- list()
  for (i in seq_len(N_SUBJ)) {
    eta <- stats::rnorm(length(OMEGA), 0, OMEGA)
    names(eta) <- names(OMEGA)
    noise <- stats::rnorm(20)
    par <- TRUTH
    par[["CL"]] <- TRUTH[["CL"]] * (wt[i] / 70)^0.75 * exp(eta[["CL"]])
    par[["V1"]] <- TRUTH[["V1"]] * (wt[i] / 70) * exp(eta[["V1"]])
    par[["KA"]] <- TRUTH[["KA"]] * exp(eta[["KA"]])
    times <- if (i %% 2 == 0) rich else sparse
    if (design == "absorption") times <- sort(unique(c(0.25, 0.5, 1, 2, times)))
    conc <- pk_conc(times, dose_regimen(500), par, "2cmt", "oral")
    dv <- conc * (1 + SIGMA * noise[seq_along(conc)])
    rows[[i]] <- rbind(
      data.frame(ID = i, TIME = 0, AMT = 500, DV = NA, EVID = 1, WT = wt[i]),
      data.frame(ID = i, TIME = times, AMT = 0, DV = dv, EVID = 0, WT = wt[i])
    )
  }
  d <- do.call(rbind, rows)
  mod <- pk_model("2cmt", route = "oral", iiv = names(OMEGA), error = "proportional",
                  covariates = list(CL ~ (WT / 70)^0.75, V1 ~ (WT / 70)^b_wt),
                  ka_faster = KA_FASTER)
  t0 <- Sys.time()
  fit <- suppressWarnings(suppressMessages(
    bpk_fit(mod, d, chains = 4, iter = ITER, cores = 1, seed = seed + r,
            adapt_delta = 0.95, refresh = 0)
  ))
  sm <- summary(fit)
  truth <- c(TRUTH, b_wt = 1, setNames(OMEGA, paste0("omega_", names(OMEGA))), sigma_prop = SIGMA)
  i <- match(names(truth), sm$variable)
  dg <- bpk_diagnostics(fit)
  data.frame(design = design, rep = r, variable = names(truth), truth = unname(truth),
             q5 = sm$q5[i], q50 = sm$q50[i], q95 = sm$q95[i],
             rhat = sm$rhat[i], ess_bulk = sm$ess_bulk[i], ess_tail = sm$ess_tail[i],
             divergent = dg$divergent, rhat_max = dg$rhat_max,
             seconds = as.numeric(difftime(Sys.time(), t0, units = "secs")))
}

jobs <- c(lapply(seq_len(N_REPS), function(r) list(rep = r, design = "original")),
          if (!KA_FASTER) lapply(seq_len(N_REPS), function(r) list(rep = r, design = "absorption")))
cl <- parallel::makeCluster(WORKERS)
parallel::clusterExport(cl, c("one_rep", "SEED", "N_SUBJ", "TRUTH", "OMEGA", "SIGMA", "KA_FASTER", "ITER"))
t_all <- Sys.time()
res <- parallel::parLapplyLB(cl, jobs, function(job) {
  tryCatch(one_rep(job, SEED), error = function(e) {
    data.frame(design = job$design, rep = job$rep, variable = NA, truth = NA, q5 = NA, q50 = NA,
               q95 = NA, rhat = NA, ess_bulk = NA, ess_tail = NA,
               divergent = NA, rhat_max = NA, seconds = NA)
  })
})
parallel::stopCluster(cl)
res <- do.call(rbind, res)
write.csv(res, file.path(out_dir, paste0("coverage-2cmt-oral", SUFFIX, ".csv")), row.names = FALSE)
cat("minutes", round(as.numeric(difftime(Sys.time(), t_all, units = "mins")), 1), "\n")

ok <- res[!is.na(res$q50), ]
tab <- do.call(rbind, lapply(split(ok, list(ok$design, ok$variable), drop = TRUE), function(x) {
  data.frame(design = x$design[1], variable = x$variable[1], n = nrow(x),
             coverage_90 = mean(x$truth >= x$q5 & x$truth <= x$q95),
             median_rel_error = stats::median(x$q50 / x$truth - 1),
             reps_with_divergences = sum(x$divergent > 0),
             reps_rhat_over_1.01 = sum(x$rhat_max > 1.01),
             parameter_rhat_over_1.01 = sum(x$rhat > 1.01, na.rm = TRUE),
             parameter_rhat_missing = sum(!is.finite(x$rhat)))
}))
tab <- tab[order(tab$variable, tab$design), ]
print(tab, digits = 3, row.names = FALSE)
write.csv(tab, file.path(out_dir, paste0("coverage-2cmt-oral", SUFFIX, "-summary.csv")), row.names = FALSE)
