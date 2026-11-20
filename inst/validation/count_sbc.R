# Count SBC uniformity tests and p-values below 0.05 across the scenario summaries.
# Run from the package root: Rscript inst/validation/count_sbc.R
f <- file.path("inst", "validation", "results",
               c("sbc-1cmt_oral-summary.csv", "sbc-1cmt_oral_cov-summary.csv",
                 "sbc-2cmt_iv-summary.csv", "sbc-1cmt_oral_log_blq-400-summary.csv"))
for (x in f) {
  d <- read.csv(x)
  cat(basename(x), nrow(d), "tests; p < 0.05:", sum(d$chisq_p < 0.05),
      "; min p", round(min(d$chisq_p), 3), "max", round(max(d$chisq_p), 3), "\n")
}
a <- do.call(rbind, lapply(f, read.csv))
cat("total", nrow(a), "; p < 0.05:", sum(a$chisq_p < 0.05), "; expected by chance", round(0.05 * nrow(a), 2), "\n")
print(a[a$chisq_p < 0.05, c("variable", "n", "chisq_p")], row.names = FALSE)
