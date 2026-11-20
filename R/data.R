# Convert a NONMEM-style data set into the lists used by the Stan model.

read_numeric <- function(x, name) {
  if (is.numeric(x)) return(as.numeric(x))
  x <- trimws(as.character(x))
  x[x %in% c(".", "")] <- NA
  out <- suppressWarnings(as.numeric(x))
  bad <- !is.na(x) & is.na(out)
  if (any(bad)) {
    stop("Column ", name, " has non-numeric values such as '", x[bad][1], "'.", call. = FALSE)
  }
  out
}

prepare_data <- function(model, data) {
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  names(data) <- toupper(names(data))
  for (col in c("ID", "TIME", "DV", "AMT")) {
    if (!col %in% names(data)) stop("`data` needs a column ", col, ".", call. = FALSE)
  }
  num <- function(col, default) {
    if (col %in% names(data)) read_numeric(data[[col]], col) else rep(default, nrow(data))
  }
  id_raw <- data$ID
  time <- num("TIME", NA)
  dv <- num("DV", NA)
  amt <- num("AMT", 0)
  amt[is.na(amt)] <- 0
  evid <- if ("EVID" %in% names(data)) num("EVID", 0) else ifelse(amt > 0, 1, 0)
  cens <- num("CENS", 0)
  cens[is.na(cens)] <- 0
  if (any(!cens %in% c(0, 1))) stop("CENS must be 0 or 1 (1: DV is the quantification limit).", call. = FALSE)
  mdv <- num("MDV", 0)
  mdv[is.na(mdv)] <- 0
  rate <- num("RATE", 0)
  rate[is.na(rate)] <- 0
  ss <- num("SS", 0)
  addl <- num("ADDL", 0)
  ii <- num("II", 0)
  if (anyNA(time)) stop("TIME has missing values.", call. = FALSE)
  if (any(evid %in% c(3, 4))) stop("Reset events (EVID 3 or 4) are not supported in this version.", call. = FALSE)
  ss[is.na(ss)] <- 0
  if (any(!ss %in% c(0, 1))) stop("Only SS = 1 (steady state, earlier doses reset) is supported.", call. = FALSE)
  if (any(rate < 0)) stop("Modelled rate or duration (RATE -1 or -2) is not supported.", call. = FALSE)
  # Doses: NONMEM EVID 1, or rxode2-style bolus codes (101, 201, ...).
  # rxode2 codes of 10000 and above encode infusions or other events.
  if (any(evid >= 10000)) {
    stop("rxode2 event codes of 10000 and above are not supported; use EVID 1 with RATE.", call. = FALSE)
  }
  is_dose <- (evid == 1 | evid >= 100) & amt > 0
  if (model$route == "oral" && any(rate[is_dose] > 0)) {
    stop("Infusions (RATE > 0) cannot be combined with an oral model.", call. = FALSE)
  }

  ids <- unique(id_raw)
  sid <- match(id_raw, ids)

  # Doses, with ADDL expanded.
  dose <- data.frame(sid = sid[is_dose], time = time[is_dose], amt = amt[is_dose],
                     rate = rate[is_dose], addl = addl[is_dose], ii = ii[is_dose],
                     ss = ss[is_dose])
  if (any(dose$ss == 1 & !(dose$ii > 0))) stop("SS = 1 needs a positive II.", call. = FALSE)
  if (any(dose$ss == 1 & dose$rate > 0 & dose$amt / pmax(dose$rate, 1e-300) > dose$ii)) {
    stop("A steady-state infusion must be shorter than II.", call. = FALSE)
  }
  # SS = 1 resets: doses before the last steady-state dose of a subject are dropped.
  last_ss <- tapply(ifelse(dose$ss == 1, dose$time, -Inf), dose$sid, max)
  reset <- dose$time < last_ss[as.character(dose$sid)]
  if (any(reset)) {
    message(sum(reset), " dose record(s) before a steady-state dose (SS = 1) are ignored.")
    dose <- dose[!reset, ]
  }
  dose$ss_ii <- ifelse(dose$ss == 1, dose$ii, 0)
  if (any(dose$addl > 0)) {
    if (any(dose$addl > 0 & !(dose$ii > 0))) stop("ADDL needs a positive II.", call. = FALSE)
    rep_n <- dose$addl + 1
    dose <- dose[rep(seq_len(nrow(dose)), rep_n), ]
    k <- sequence(rep_n, from = 0)
    dose$time <- dose$time + dose$ii * k
    dose$ss_ii[k > 0] <- 0
  }
  dose <- dose[order(dose$sid, dose$time), c("sid", "time", "amt", "rate", "ss_ii")]

  is_obs <- evid == 0 & mdv != 1 & !is.na(dv)
  obs <- data.frame(sid = sid[is_obs], time = time[is_obs], dv = dv[is_obs], cens = cens[is_obs])
  # Observations at or before the first dose are dropped; before a first dose
  # at steady state, observations within one interval belong to the same train.
  first_dose <- tapply(dose$time, dose$sid, min)
  first_ii <- tapply(seq_len(nrow(dose)), dose$sid, function(j) dose$ss_ii[j][which.min(dose$time[j])])
  fd <- first_dose[as.character(obs$sid)] - first_ii[as.character(obs$sid)]
  early <- is.na(fd) | obs$time <= fd
  n_early <- sum(early)
  obs <- obs[!early, ]
  if (!nrow(obs)) stop("No observations after a dose.", call. = FALSE)

  # Keep subjects with observations; they must have doses.
  keep <- sort(unique(obs$sid))
  dropped <- setdiff(seq_along(ids), keep)
  new_index <- match(seq_along(ids), keep)
  obs$sid <- new_index[obs$sid]
  dose <- dose[dose$sid %in% keep, ]
  dose$sid <- new_index[dose$sid]
  obs <- obs[order(obs$sid, obs$time), ]
  if (model$error == "log" && any(obs$dv <= 0)) {
    stop("Log-scale error needs positive DV (and a positive quantification limit for CENS = 1).", call. = FALSE)
  }
  if (any(obs$cens == 1)) {
    message(sum(obs$cens == 1), " observation(s) below the quantification limit (CENS = 1) ",
            "are handled by Beal's M3 method.")
  }

  # Covariates must be constant within subject.
  vars <- unique(model$covariates$var)
  cov <- data.frame(row.names = seq_along(keep))
  for (v in vars) {
    if (!v %in% names(data)) stop("Covariate ", v, " is not in `data`.", call. = FALSE)
    x <- data[[v]]
    per <- split(x, sid)[as.character(keep)]
    nonconst <- vapply(per, function(z) length(unique(z[!is.na(z)])) > 1, logical(1))
    if (any(nonconst)) {
      stop("Covariate ", v, " changes within subject; time-varying covariates are not supported in this version.", call. = FALSE)
    }
    val <- vapply(per, function(z) { z <- z[!is.na(z)]; if (length(z)) as.character(z[1]) else NA_character_ }, character(1))
    if (anyNA(val)) stop("Covariate ", v, " is missing for some subjects.", call. = FALSE)
    cov[[v]] <- if (model$covariates$type[match(v, model$covariates$var)] == "cat") val else as.numeric(val)
  }

  N <- length(keep)
  starts <- ends <- integer(N)
  for (i in seq_len(N)) {
    idx <- which(dose$sid == i)
    if (length(idx)) {
      starts[i] <- min(idx)
      ends[i] <- max(idx)
    } else {
      starts[i] <- 1L
      ends[i] <- 0L
    }
  }
  if (any(ends == 0L)) stop("Some subjects with observations have no dose.", call. = FALSE)

  list(obs = obs, dose = dose, cov = cov, ids = ids[keep], N = N,
       dose_start = starts, dose_end = ends,
       n_early = n_early, dropped = ids[dropped])
}

# Rough data-based scale for default priors: median non-compartmental
# estimates after the first dose of each subject.
data_scale <- function(model, prep) {
  est <- lapply(seq_len(prep$N), function(i) {
    d <- prep$dose[prep$dose$sid == i, ]
    o <- prep$obs[prep$obs$sid == i & prep$obs$cens == 0, ]
    t0 <- d$time[1]
    t_end <- if (nrow(d) > 1) d$time[2] else Inf
    o <- o[o$time > t0 & o$time <= t_end, ]
    if (nrow(o) < 2 || all(o$dv <= 0)) return(NULL)
    t <- c(0, o$time - t0)
    c <- c(0, pmax(o$dv, 0))
    auc <- sum(diff(t) * (head(c, -1) + tail(c, -1)) / 2)
    n_tail <- min(3, nrow(o))
    tail_obs <- tail(o, n_tail)
    if (n_tail >= 2 && all(tail_obs$dv > 0)) {
      slope <- stats::coef(stats::lm(log(tail_obs$dv) ~ tail_obs$time))[2]
      if (is.finite(slope) && slope < 0) auc <- auc + tail(o$dv, 1) / (-slope)
    }
    cmax <- max(o$dv)
    tmax <- o$time[which.max(o$dv)] - t0
    c(cl = unname(d$amt[1] / auc), v = unname(d$amt[1] / cmax), ka = unname(3 / max(tmax, 1e-6)))
  })
  est <- do.call(rbind, est)
  pos_med <- function(x, fallback = 1) {
    x <- x[is.finite(x) & x > 0]
    if (length(x)) stats::median(x) else fallback
  }
  cl <- if (is.null(est)) 1 else pos_med(est[, "cl"])
  v <- if (is.null(est)) 1 else pos_med(est[, "v"])
  ka <- if (is.null(est)) 1 else pos_med(est[, "ka"])
  s <- list(CL = cl, V = v, V1 = v, Q = cl, V2 = v, KA = ka)
  dv_q <- prep$obs$dv[prep$obs$cens == 0]
  s$dv_sd <- if (length(dv_q) > 1 && stats::sd(dv_q) > 0) stats::sd(dv_q) else 1
  s
}
