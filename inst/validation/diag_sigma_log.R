# Where do the sigma_log ranks deviate from uniform? Deciles of the pooled ranks
# and a split by whether the replicate had divergences or R-hat > 1.01.
files <- file.path("inst", "validation", "results",
                   c("sbc-1cmt_oral_log_blq.csv", "sbc-1cmt_oral_log_blq-from201.csv"))
x <- do.call(rbind, lapply(files, read.csv))
x <- x[!is.na(x$rank), ]
d <- x[x$variable == "sigma_log", ]
cat("rank deciles (expected 40 per bin):\n")
print(table(cut(d$rank, breaks = seq(-0.5, 100.5, length.out = 11))))
cat("\nmean rank fraction by sigma_log truth tercile:\n")
d$tercile <- cut(d$truth, quantile(d$truth, 0:3 / 3), include.lowest = TRUE, labels = c("low", "mid", "high"))
print(tapply(d$rank / 100, d$tercile, mean))
cat("\nmean rank fraction by R-hat > 1.01:\n")
print(tapply(d$rank / 100, d$rhat_max > 1.01, mean))
cat("\nbinomial check of the mean rank: se =", round(sqrt(1 / 12 / nrow(d)), 4), "\n")
