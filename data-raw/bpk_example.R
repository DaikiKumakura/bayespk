# Simulated example data set shipped as `bpk_example`.
# Run from the package root: Rscript data-raw/bpk_example.R
devtools::load_all(quiet = TRUE)
set.seed(20261118)
n <- 30
truth <- c(CL = 3, V = 30, KA = 1.2)
omega <- c(CL = 0.3, V = 0.2, KA = 0.4)
sigma <- 0.15
rich <- c(0.25, 0.5, 1, 2, 3, 4, 6, 8, 12, 24)
sparse <- c(1, 4, 12, 24)
rows <- vector("list", n)
for (i in seq_len(n)) {
  wt <- round(stats::rlnorm(1, log(70), 0.2), 1)
  sex <- stats::rbinom(1, 1, 0.5)
  amt <- if (i <= n / 2) 100 else 200
  eta <- stats::rnorm(3, 0, omega)
  par <- c(CL = truth[["CL"]] * (wt / 70)^0.75 * exp(eta[1]),
           V = truth[["V"]] * (wt / 70) * exp(eta[2]),
           KA = truth[["KA"]] * exp(eta[3]))
  times <- if (i %% 3 == 0) rich else sparse
  conc <- pk_conc(times, dose_regimen(amt), par, "1cmt", "oral")
  dv <- signif(conc * (1 + sigma * stats::rnorm(length(conc))), 3)
  rows[[i]] <- rbind(
    data.frame(ID = i, TIME = 0, AMT = amt, DV = NA, EVID = 1, WT = wt, SEX = sex),
    data.frame(ID = i, TIME = times, AMT = 0, DV = dv, EVID = 0, WT = wt, SEX = sex)
  )
}
bpk_example <- do.call(rbind, rows)
rownames(bpk_example) <- NULL
stopifnot(nrow(bpk_example) == n + sum(ifelse(seq_len(n) %% 3 == 0, length(rich), length(sparse))))
usethis::use_data(bpk_example, overwrite = TRUE)
