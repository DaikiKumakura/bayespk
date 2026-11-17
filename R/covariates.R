# Covariate terms are stored as rows of a data frame, all acting on the log
# scale of a parameter:
#   power:  log(X / ref) * exponent        (exponent fixed or estimated)
#   linear: (X - ref) * b                  (b estimated; from exp(b * (X - ref)))
#   cat:    (X == level) * b               (b estimated)
parse_covariates <- function(covariates, pars) {
  out <- data.frame(param = character(), var = character(), type = character(),
                    ref = numeric(), level = character(), value = numeric(),
                    name = character(), label = character(), stringsAsFactors = FALSE)
  for (f in covariates) {
    if (!inherits(f, "formula") || length(f) != 3)
      stop("Each covariate must be a two-sided formula such as `CL ~ (WT / 70)^0.75`.", call. = FALSE)
    param <- deparse(f[[2]])
    if (!param %in% pars)
      stop("Unknown parameter `", param, "` in a covariate formula.", call. = FALSE)
    for (term in split_product(f[[3]])) {
      row <- parse_term(term)
      row$param <- param
      row$label <- paste(param, "~", deparse(term))
      out <- rbind(out, as.data.frame(row[names(out)], stringsAsFactors = FALSE))
    }
  }
  est <- out$name[!is.na(out$name)]
  if (anyDuplicated(est))
    stop("Each estimated covariate effect needs its own name; duplicated: ",
         paste(unique(est[duplicated(est)]), collapse = ", "), call. = FALSE)
  out
}

split_product <- function(e) {
  if (is.call(e) && identical(e[[1]], as.name("*"))) c(split_product(e[[2]]), split_product(e[[3]]))
  else list(e)
}

strip_paren <- function(e) {
  while (is.call(e) && identical(e[[1]], as.name("("))) e <- e[[2]]
  e
}

term_error <- function(e) {
  stop("Cannot read the covariate term `", deparse(e), "`. Use (X / ref)^p, ",
       "exp(b * (X - ref)) or (X == level)^b.", call. = FALSE)
}

parse_term <- function(e) {
  e <- strip_paren(e)
  row <- list(var = NA_character_, type = NA_character_, ref = NA_real_,
              level = NA_character_, value = NA_real_, name = NA_character_)
  if (is.call(e) && identical(e[[1]], as.name("^"))) {
    base <- strip_paren(e[[2]])
    expo <- e[[3]]
    if (is.numeric(expo)) row$value <- expo
    else if (is.name(expo)) row$name <- as.character(expo)
    else term_error(e)
    if (is.call(base) && identical(base[[1]], as.name("/")) && is.name(base[[2]]) && is.numeric(base[[3]])) {
      row$var <- as.character(base[[2]]); row$type <- "power"; row$ref <- base[[3]]
    } else if (is.call(base) && identical(base[[1]], as.name("==")) && is.name(base[[2]])) {
      if (is.na(row$name)) stop("A categorical effect must be estimated: write (", deparse(base), ")^b_name.", call. = FALSE)
      row$var <- as.character(base[[2]]); row$type <- "cat"; row$level <- as.character(eval(base[[3]]))
    } else term_error(e)
    return(row)
  }
  if (is.call(e) && identical(e[[1]], as.name("/")) && is.name(e[[2]]) && is.numeric(e[[3]])) {
    row$var <- as.character(e[[2]]); row$type <- "power"; row$ref <- e[[3]]; row$value <- 1
    return(row)
  }
  if (is.call(e) && identical(e[[1]], as.name("exp"))) {
    inner <- strip_paren(e[[2]])
    if (is.call(inner) && identical(inner[[1]], as.name("*")) && is.name(inner[[2]])) {
      d <- strip_paren(inner[[3]])
      if (is.call(d) && identical(d[[1]], as.name("-")) && is.name(d[[2]]) && is.numeric(d[[3]])) {
        row$var <- as.character(d[[2]]); row$type <- "linear"; row$ref <- d[[3]]
        row$name <- as.character(inner[[2]])
        return(row)
      }
    }
  }
  term_error(e)
}

# Value of each term on the log scale, one column per term (subjects in rows).
covariate_columns <- function(terms, cov) {
  if (!nrow(terms)) return(matrix(0, nrow(cov), 0))
  m <- vapply(seq_len(nrow(terms)), function(j) {
    x <- cov[[terms$var[j]]]
    switch(terms$type[j],
           power = {
             if (any(x <= 0)) stop("Covariate ", terms$var[j], " must be positive for a power effect.", call. = FALSE)
             log(as.numeric(x) / terms$ref[j])
           },
           linear = as.numeric(x) - terms$ref[j],
           cat = as.numeric(as.character(x) == terms$level[j]))
  }, numeric(nrow(cov)))
  matrix(m, nrow(cov))
}
