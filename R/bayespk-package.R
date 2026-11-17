#' bayespk: Bayesian population pharmacokinetics without writing Stan
#'
#' Fits 1- and 2-compartment linear population pharmacokinetic models to
#' NONMEM-style data with precompiled Stan programs based on closed-form
#' solutions.
#'
#' @name bayespk-package
#' @aliases bayespk
#' @useDynLib bayespk, .registration = TRUE
#' @import methods
#' @import Rcpp
#' @importFrom rstan sampling
#' @importFrom rstantools rstan_config
#' @importFrom RcppParallel RcppParallelLibs
#' @importFrom stats predict
#' @importFrom utils head tail
#' @references
#' Stan Development Team. RStan: the R interface to Stan. https://mc-stan.org
"_PACKAGE"
