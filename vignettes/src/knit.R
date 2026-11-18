# Regenerate the precomputed vignettes (runs the fits; several minutes).
# Run from the package root: Rscript vignettes/src/knit.R
old <- setwd("vignettes")
on.exit(setwd(old))
for (f in c("bayespk", "covariates-priors", "two-compartment")) {
  knitr::knit(file.path("src", paste0(f, ".Rmd.orig")), paste0(f, ".Rmd"))
}
