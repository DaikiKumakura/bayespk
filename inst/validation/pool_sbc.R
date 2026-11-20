# Pool SBC result files of one scenario and test rank uniformity.
# Run from the package root: Rscript inst/validation/pool_sbc.R <out_name> <file1> <file2> ...
# Files are in inst/validation/results; ranks are out of 100.
args <- commandArgs(TRUE)
out <- args[1]
files <- file.path("inst", "validation", "results", args[-1])
x <- do.call(rbind, lapply(files, read.csv))
x <- x[!is.na(x$rank), ]
tab <- do.call(rbind, lapply(split(x, x$variable), function(d) {
  counts <- table(cut(d$rank, breaks = seq(-0.5, 100.5, length.out = 11)))
  data.frame(variable = d$variable[1], n = nrow(d),
             chisq_p = stats::chisq.test(counts)$p.value,
             mean_rank_fraction = mean(d$rank) / 100,
             min_bin = min(counts), max_bin = max(counts))
}))
print(tab, digits = 3, row.names = FALSE)
write.csv(tab, file.path("inst", "validation", "results", out), row.names = FALSE)
