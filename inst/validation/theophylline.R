# Validation: theophylline (nlmixr2data::theo_sd), 1-compartment oral model.
# Compares bayespk posterior medians with nlmixr2 FOCEI estimates and records
# run time. Run from the package root: Rscript inst/validation/theophylline.R
library(bayespk)
library(nlmixr2)

SEED <- 20261116
out_dir <- file.path("inst", "validation", "results")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

d <- nlmixr2data::theo_sd
cat("rows:", nrow(d), " subjects:", length(unique(d$ID)), "\n")

# Largest relative error of the closed form against rxode2 on this data's design.
m_ode <- rxode2::rxode2("d/dt(depot) = -KA * depot
d/dt(centr) = KA * depot - CL / V * centr
cp = centr / V")
tt <- c(0.25, 0.5, 1, 2, 4, 6, 8, 12, 24)
ev <- rxode2::et(amt = 320, cmt = "depot")
ev <- rxode2::et(ev, tt)
ode <- rxode2::rxSolve(m_ode, params = c(CL = 2.8, V = 32, KA = 1.5), events = ev,
                       atol = 1e-12, rtol = 1e-12, returnType = "data.frame")
cf <- pk_conc(tt, dose_regimen(320), c(CL = 2.8, V = 32, KA = 1.5), "1cmt", "oral")
cat("max relative error closed form vs rxode2:", signif(max(abs(cf - ode$cp[match(tt, ode$time)]) / ode$cp[match(tt, ode$time)]), 3), "\n")

# bayespk
mod <- pk_model("1cmt", route = "oral", iiv = c("CL", "V", "KA"), error = "proportional")
fit <- bpk_fit(mod, d, chains = 4, cores = 4, iter = 2000, seed = SEED)
print(fit)
print(fit$priors)
diag <- bpk_diagnostics(fit)
str(diag)
sm <- summary(fit)

# nlmixr2 FOCEI with the same structure
one_cmt <- function() {
  ini({
    tka <- log(1.5); tcl <- log(2.8); tv <- log(32)
    eta.ka ~ 0.5; eta.cl ~ 0.1; eta.v ~ 0.05
    prop.sd <- 0.2
  })
  model({
    ka <- exp(tka + eta.ka); cl <- exp(tcl + eta.cl); v <- exp(tv + eta.v)
    linCmt() ~ prop(prop.sd)
  })
}
t1 <- Sys.time()
nf <- nlmixr2(one_cmt, d, est = "focei", control = foceiControl(print = 0))
nl_sec <- as.numeric(difftime(Sys.time(), t1, units = "secs"))
fe <- nf$parFixedDf
om <- sqrt(diag(nf$omega))
cmp <- data.frame(
  quantity = c("CL", "V", "KA", "omega_CL", "omega_V", "omega_KA", "sigma_prop"),
  bayespk_median = sm$q50[match(c("CL", "V", "KA", "omega_CL", "omega_V", "omega_KA", "sigma_prop"), sm$variable)],
  bayespk_q5 = sm$q5[match(c("CL", "V", "KA", "omega_CL", "omega_V", "omega_KA", "sigma_prop"), sm$variable)],
  bayespk_q95 = sm$q95[match(c("CL", "V", "KA", "omega_CL", "omega_V", "omega_KA", "sigma_prop"), sm$variable)],
  nlmixr2_focei = c(exp(fe["tcl", "Estimate"]), exp(fe["tv", "Estimate"]), exp(fe["tka", "Estimate"]),
                    om[["eta.cl"]], om[["eta.v"]], om[["eta.ka"]], fe["prop.sd", "Estimate"])
)
cmp$ratio <- cmp$bayespk_median / cmp$nlmixr2_focei
print(cmp, digits = 3)

res <- list(seed = SEED, bayespk_seconds = fit$seconds, nlmixr2_seconds = nl_sec,
            diagnostics = diag, comparison = cmp, priors = fit$priors,
            hardware = Sys.info()[c("sysname", "release", "machine")],
            versions = c(bayespk = as.character(packageVersion("bayespk")),
                         rstan = as.character(packageVersion("rstan")),
                         nlmixr2 = as.character(packageVersion("nlmixr2"))))
saveRDS(res, file.path(out_dir, "theophylline.rds"))
write.csv(cmp, file.path(out_dir, "theophylline-comparison.csv"), row.names = FALSE)
cat(sprintf("bayespk %.1f s (4 chains x 2000, 4 cores); nlmixr2 FOCEI %.1f s\n", fit$seconds, nl_sec))

# Posterior predictive for a new regimen
pp <- predict(fit, regimen = dose_regimen(320, ii = 12, n = 3), ndraws = 500)
print(head(pp[pp$TIME > 24, ], 5))
