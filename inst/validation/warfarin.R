suppressPackageStartupMessages(library(bayespk))
suppressPackageStartupMessages(library(nlmixr2))
args <- commandArgs(TRUE)
if (length(args) != 2L) stop("Usage: warfarin.R <warfarin.csv> <output-directory>")
d <- read.csv(args[[1]])
names(d) <- toupper(names(d))
d <- d[d$EVID == 1 | (d$DVID == "cp" & d$TIME > 0), ]
d <- d[c("ID", "TIME", "EVID", "AMT", "DV")]
d$AMT[d$EVID == 0] <- 0
d$DV[d$EVID == 1] <- NA_real_
d <- d[order(d$ID, d$TIME, -d$EVID), ]
stopifnot(all(is.finite(d$DV[d$EVID == 0])))
model <- pk_model("1cmt", "oral", iiv = c("CL", "V", "KA"), error = "combined")
priors <- pk_priors(CL = lognormal(log(0.13), 1), V = lognormal(log(10), 1),
                    KA = lognormal(log(1), 1))
fit <- bpk_fit(model, d, priors = priors, chains = 4, cores = 4, iter = 3000,
               seed = 20261117, adapt_delta = 0.95, refresh = 0)
focei_model <- function() {
  ini({
    tcl <- log(0.13)
    tv <- log(10)
    tka <- log(1)
    eta.cl ~ 0.15
    eta.v ~ 0.1
    eta.ka ~ 0.2
    add.sd <- 0.3
    prop.sd <- 0.15
  })
  model({
    cl <- exp(tcl + eta.cl)
    v <- exp(tv + eta.v)
    ka <- exp(tka + eta.ka)
    linCmt() ~ add(add.sd) + prop(prop.sd)
  })
}
started <- Sys.time()
focei <- nlmixr2(focei_model, d, est = "focei", control = foceiControl(print = 0, addProp = "combined2"))
focei_seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))
sm <- summary(fit)
quantities <- c("CL", "V", "KA", "omega_CL", "omega_V", "omega_KA", "sigma_add", "sigma_prop")
ix <- match(quantities, sm$variable)
stopifnot(!anyNA(ix))
fe <- focei$parFixedDf
omega <- sqrt(diag(focei$omega))
cmp <- data.frame(quantity = quantities, bayespk_median = sm$q50[ix],
                  bayespk_q5 = sm$q5[ix], bayespk_q95 = sm$q95[ix], rhat = sm$rhat[ix],
                  nlmixr2_focei = c(exp(fe[c("tcl", "tv", "tka"), "Estimate"]),
                                   omega[c("eta.cl", "eta.v", "eta.ka")],
                                   fe[c("add.sd", "prop.sd"), "Estimate"]))
dir.create(args[[2]], recursive = TRUE, showWarnings = FALSE)
write.csv(cmp, file.path(args[[2]], "warfarin-comparison.csv"), row.names = FALSE)
saveRDS(list(diagnostics = bpk_diagnostics(fit), bayespk_seconds = fit$seconds,
             focei_seconds = focei_seconds, focei_run_info = focei$runInfo,
             subjects = length(unique(d$ID)), observations = sum(d$EVID == 0),
             session = sessionInfo()), file.path(args[[2]], "warfarin-validation.rds"))
print(cmp, digits = 3)
print(bpk_diagnostics(fit))
cat("bayespk seconds:", fit$seconds, "FOCEI seconds:", focei_seconds, "\n")
