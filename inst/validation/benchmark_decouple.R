# Benchmark: sampling efficiency with and without the mean/deviation split of
# the random effects ("decouple"), per parameter with IIV.
# Reports wall time, minimum bulk ESS over population parameters, and
# min ESS per second, for theophylline (nlmixr2data) and bpk_example.
# Run from the package root: Rscript inst/validation/benchmark_decouple.R
library(bayespk)
out_dir <- file.path("inst", "validation", "results")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

cases <- list(
  theophylline = list(data = nlmixr2data::theo_sd,
                      model = pk_model("1cmt", "oral", iiv = c("CL", "V", "KA"))),
  bpk_example = list(data = bpk_example,
                     model = pk_model("1cmt", "oral", iiv = c("CL", "V", "KA"),
                                      covariates = list(CL ~ (WT / 70)^0.75, V ~ (WT / 70)^b_wt)))
)
settings <- list(all = c(TRUE, TRUE, TRUE), none = c(FALSE, FALSE, FALSE),
                 CL_only = c(TRUE, FALSE, FALSE), CL_V = c(TRUE, TRUE, FALSE))
seeds <- 1:3
rows <- list()
for (cn in names(cases)) for (sn in names(settings)) for (s in seeds) {
  options(bayespk.decouple = settings[[sn]])
  fit <- suppressWarnings(bpk_fit(cases[[cn]]$model, cases[[cn]]$data, chains = 4, cores = 4,
                                  seed = s, refresh = 0))
  sm <- posterior::summarise_draws(bpk_draws(fit), "ess_bulk", "rhat")
  sp <- rstan::get_sampler_params(fit$stanfit, inc_warmup = FALSE)
  rows[[length(rows) + 1]] <- data.frame(
    case = cn, setting = sn, seed = s, seconds = fit$seconds,
    ess_min = min(sm$ess_bulk), ess_min_param = sm$variable[which.min(sm$ess_bulk)],
    ess_CL = sm$ess_bulk[sm$variable == "CL"], rhat_max = max(sm$rhat),
    treedepth = mean(unlist(lapply(sp, function(x) x[, "treedepth__"]))),
    divergent = sum(unlist(lapply(sp, function(x) x[, "divergent__"]))))
  cat(cn, sn, s, round(fit$seconds, 1), "\n")
}
options(bayespk.decouple = NULL)
res <- do.call(rbind, rows)
res$ess_min_per_s <- res$ess_min / res$seconds
write.csv(res, file.path(out_dir, "benchmark-decouple.csv"), row.names = FALSE)
agg <- aggregate(cbind(seconds, ess_min, ess_CL, ess_min_per_s, treedepth, rhat_max) ~ case + setting,
                 res, median)
print(agg, digits = 3)
write.csv(agg, file.path(out_dir, "benchmark-decouple-summary.csv"), row.names = FALSE)
