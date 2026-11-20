# Validation: simulation-based calibration (SBC; Talts et al. 2018).
# For each replicate: draw parameters from the prior, simulate a data set,
# fit with the same prior, and record the rank of each true value among
# thinned posterior draws. If the sampler and model code are correct, ranks
# are uniform.
# Run from the package root: Rscript inst/validation/sbc.R <scenario> <n_reps> <workers> [offset]
#   scenario: 1cmt_oral, 2cmt_iv, 1cmt_oral_cov (estimated weight exponent on V)
#   or 1cmt_oral_log_blq (log-scale error, values below 0.5 censored by M3)
args <- commandArgs(TRUE)
SCENARIO <- if (length(args) >= 1) args[1] else "1cmt_oral"
N_REPS <- if (length(args) >= 2) as.integer(args[2]) else 200
WORKERS <- if (length(args) >= 3) as.integer(args[3]) else 8
OFFSET <- if (length(args) >= 4) as.integer(args[4]) else 0   # replicate numbers start at OFFSET + 1
SEED <- 20261116
THIN_TO <- 100           # posterior draws kept for ranks
CHAINS <- 2
ITER <- 1000             # per chain, half warmup
out_dir <- file.path("inst", "validation", "results")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

scenarios <- list(
  "1cmt_oral" = list(
    structure = "1cmt", route = "oral", n_subj = 12, amt = 320, rate = 0,
    times = c(0.25, 0.5, 1, 2, 3.5, 5, 7, 9, 12, 24),
    prior = list(CL = c(log(2.8), 0.3), V = c(log(32), 0.3), KA = c(log(1.5), 0.3)),
    iiv = c("CL", "V", "KA"), omega_scale = 0.4, sigma_scale = 0.2
  ),
  "2cmt_iv" = list(
    structure = "2cmt", route = "iv", n_subj = 20, amt = 500, rate = 250,
    times = c(0.5, 1, 2, 3, 4, 6, 8, 12, 24, 36, 48),
    prior = list(CL = c(log(4), 0.3), V1 = c(log(20), 0.3), Q = c(log(6), 0.3), V2 = c(log(60), 0.3)),
    iiv = c("CL", "V1"), omega_scale = 0.4, sigma_scale = 0.2
  ),
  "1cmt_oral_cov" = list(
    structure = "1cmt", route = "oral", n_subj = 20, amt = 320, rate = 0,
    times = c(0.25, 0.5, 1, 2, 3.5, 5, 7, 9, 12, 24),
    prior = list(CL = c(log(2.8), 0.3), V = c(log(32), 0.3), KA = c(log(1.5), 0.3)),
    iiv = c("CL", "V", "KA"), omega_scale = 0.4, sigma_scale = 0.2,
    cov = list(param = "V", name = "b_wt", mean = 1, sd = 0.5)
  ),
  "1cmt_oral_log_blq" = list(
    structure = "1cmt", route = "oral", n_subj = 16, amt = 320, rate = 0,
    times = c(0.25, 0.5, 1, 2, 3.5, 5, 7, 9, 12, 24, 36),
    prior = list(CL = c(log(2.8), 0.3), V = c(log(32), 0.3), KA = c(log(1.5), 0.3)),
    iiv = c("CL", "V", "KA"), omega_scale = 0.4, sigma_scale = 0.2,
    error = "log", lloq = 0.5
  )
)
sc <- scenarios[[SCENARIO]]
if (is.null(sc)) stop("unknown scenario")

one_rep <- function(r, sc, seed, thin_to, chains, iter) {
  library(bayespk)
  set.seed(seed + r)
  theta <- vapply(sc$prior, function(p) exp(stats::rnorm(1, p[1], p[2])), numeric(1))
  omega <- abs(stats::rnorm(length(sc$iiv), 0, sc$omega_scale))
  names(omega) <- sc$iiv
  sigma <- abs(stats::rnorm(1, 0, sc$sigma_scale))
  b <- if (!is.null(sc$cov)) stats::rnorm(1, sc$cov$mean, sc$cov$sd) else NULL
  wt <- round(stats::rlnorm(sc$n_subj, log(70), 0.2), 1)
  dose <- dose_regimen(sc$amt, rate = sc$rate)
  rows <- list()
  for (i in seq_len(sc$n_subj)) {
    par <- theta
    if (!is.null(b)) par[[sc$cov$param]] <- par[[sc$cov$param]] * (wt[i] / 70)^b
    for (p in sc$iiv) par[[p]] <- par[[p]] * exp(stats::rnorm(1, 0, omega[[p]]))
    conc <- pk_conc(sc$times, dose, par, sc$structure, sc$route)
    err <- if (is.null(sc$error)) "proportional" else sc$error
    dv <- if (err == "log") conc * exp(stats::rnorm(length(conc), 0, sigma)) else conc * (1 + stats::rnorm(length(conc), 0, sigma))
    cens <- if (!is.null(sc$lloq)) as.numeric(dv < sc$lloq) else rep(0, length(dv))
    if (!is.null(sc$lloq)) dv[cens == 1] <- sc$lloq
    rows[[i]] <- rbind(
      data.frame(ID = i, TIME = 0, AMT = sc$amt, RATE = sc$rate, DV = NA, EVID = 1, WT = wt[i], CENS = 0),
      data.frame(ID = i, TIME = sc$times, AMT = 0, RATE = 0, DV = dv, EVID = 0, WT = wt[i], CENS = cens)
    )
  }
  d <- do.call(rbind, rows)
  pri <- do.call(pk_priors, c(
    lapply(sc$prior, function(p) lognormal(p[1], p[2])),
    stats::setNames(list(half_normal(sc$omega_scale), half_normal(sc$sigma_scale)),
                    c("omega", if (identical(sc$error, "log")) "sigma_log" else "sigma_prop")),
    if (!is.null(b)) stats::setNames(list(normal(sc$cov$mean, sc$cov$sd)), sc$cov$name)
  ))
  covs <- if (!is.null(b)) list(stats::as.formula(paste(sc$cov$param, "~ (WT / 70)^", sc$cov$name))) else list()
  mod <- pk_model(sc$structure, route = sc$route, iiv = sc$iiv,
                  error = if (is.null(sc$error)) "proportional" else sc$error, covariates = covs)
  t0 <- Sys.time()
  fit <- suppressWarnings(suppressMessages(
    bpk_fit(mod, d, priors = pri, chains = chains, iter = iter, cores = 1,
            seed = seed + r, refresh = 0)
  ))
  dr <- posterior::as_draws_matrix(bpk_draws(fit))
  keep <- round(seq(1, nrow(dr), length.out = thin_to))
  truth <- c(theta, setNames(omega, paste0("omega_", names(omega))),
             setNames(sigma, if (identical(sc$error, "log")) "sigma_log" else "sigma_prop"))
  if (!is.null(b)) truth[[sc$cov$name]] <- b
  ranks <- vapply(names(truth), function(v) sum(dr[keep, v] < truth[[v]]), numeric(1))
  dg <- bpk_diagnostics(fit)
  data.frame(rep = r, variable = names(truth), truth = unname(truth), rank = unname(ranks),
             divergent = dg$divergent, rhat_max = dg$rhat_max, ess_bulk_min = dg$ess_bulk_min,
             seconds = as.numeric(difftime(Sys.time(), t0, units = "secs")))
}

cl <- parallel::makeCluster(WORKERS)
parallel::clusterExport(cl, c("one_rep", "sc", "SEED", "THIN_TO", "CHAINS", "ITER"))
t_all <- Sys.time()
res <- parallel::parLapplyLB(cl, OFFSET + seq_len(N_REPS), function(r) {
  tryCatch(one_rep(r, sc, SEED, THIN_TO, CHAINS, ITER),
           error = function(e) data.frame(rep = r, variable = NA, truth = NA, rank = NA,
                                          divergent = NA, rhat_max = NA, ess_bulk_min = NA,
                                          seconds = NA, error = conditionMessage(e)))
})
parallel::stopCluster(cl)
res <- do.call(rbind, lapply(res, function(x) { if (is.null(x$error)) x$error <- NA_character_; x }))
write.csv(res, file.path(out_dir, paste0("sbc-", SCENARIO, if (OFFSET > 0) paste0("-from", OFFSET + 1), ".csv")), row.names = FALSE)

ok <- res[!is.na(res$rank), ]
cat("scenario", SCENARIO, ": replicates", N_REPS, " failed", length(unique(res$rep[is.na(res$rank)])),
    " minutes", round(as.numeric(difftime(Sys.time(), t_all, units = "mins")), 1), "\n")
cat("replicates with divergences:", length(unique(ok$rep[ok$divergent > 0])),
    " with R-hat > 1.01:", length(unique(ok$rep[ok$rhat_max > 1.01])), "\n")
# Uniformity of ranks (0..THIN_TO) in 10 bins: chi-square test per variable.
tab <- do.call(rbind, lapply(split(ok, ok$variable), function(x) {
  bins <- cut(x$rank, breaks = seq(-0.5, THIN_TO + 0.5, length.out = 11))
  counts <- table(bins)
  data.frame(variable = x$variable[1], n = nrow(x),
             chisq_p = stats::chisq.test(counts)$p.value,
             mean_rank_fraction = mean(x$rank) / THIN_TO,
             min_bin = min(counts), max_bin = max(counts))
}))
print(tab, digits = 3)
write.csv(tab, file.path(out_dir, paste0("sbc-", SCENARIO, if (OFFSET > 0) paste0("-from", OFFSET + 1), "-summary.csv")), row.names = FALSE)
