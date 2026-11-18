# Okabe-Ito colours used in every plot.
okabe <- c(blue = "#0072B2", orange = "#E69F00", vermillion = "#D55E00",
           sky = "#56B4E9", green = "#009E73", grey = "#999999")

band_cols <- function(x) {
  q <- grep("^q[0-9.]+$", names(x), value = TRUE)
  p <- as.numeric(sub("^q", "", q))
  list(lo = q[which.min(p)], mid = q[which.min(abs(p - 50))], hi = q[which.max(p)],
       label = sprintf("%g%% interval", max(p) - min(p)))
}

draw_band <- function(t, lo, hi, mid, col = okabe[["blue"]]) {
  o <- order(t)
  graphics::polygon(c(t[o], rev(t[o])), c(lo[o], rev(hi[o])),
                    col = grDevices::adjustcolor(col, 0.25), border = NA)
  graphics::lines(t[o], mid[o], col = col, lwd = 2)
}

#' Plot predictions
#'
#' For a new regimen (`predict(fit, regimen = ...)`), draws the median
#' concentration and the prediction interval over time. For individual
#' predictions (`predict(fit)`), draws observed concentrations with each
#' subject's median and interval, one panel per subject.
#'
#' @param x Output of [predict.bpk_fit()].
#' @param ids Subjects to show for individual predictions (default: the first 12).
#' @param compare A second regimen prediction drawn in the same plot (orange).
#' @param labels Legend labels for `x` and `compare`.
#' @param log Logical; logarithmic concentration axis.
#' @param xlab,ylab,main Axis labels and title.
#' @param ... Passed to [graphics::plot()].
#' @return `x`, invisibly.
#' @examples
#' \donttest{
#' fit <- bpk_fit(pk_model("1cmt", "oral", iiv = c("CL", "V")), bpk_example,
#'                chains = 2, iter = 1000, seed = 1)
#' a <- predict(fit, regimen = dose_regimen(100, ii = 12, n = 4), times = 0:60)
#' b <- predict(fit, regimen = dose_regimen(200, ii = 24, n = 2), times = 0:60)
#' plot(a, compare = b, labels = c("100 mg q12h", "200 mg q24h"))
#' }
#' @export
plot.bpk_prediction <- function(x, ids = NULL, log = FALSE, xlab = "Time",
                                ylab = "Concentration", main = NULL, compare = NULL,
                                labels = NULL, ...) {
  b <- band_cols(x)
  lg <- if (log) "y" else ""
  if (identical(attr(x, "kind"), "regimen")) {
    preds <- c(list(x), if (!is.null(compare)) list(compare))
    if (log) preds <- lapply(preds, function(p) p[p[[b$mid]] > 0, ])
    cols <- unname(okabe[c("blue", "orange")])[seq_along(preds)]
    if (is.null(labels)) labels <- if (length(preds) == 1) "median" else c("first", "second")
    yl <- range(unlist(lapply(preds, function(p) c(p[[b$lo]], p[[b$hi]]))), na.rm = TRUE)
    if (log) yl[1] <- max(yl[1], yl[2] * 1e-3)
    # headroom for the legend
    yl[2] <- if (log) yl[2] * (yl[2] / yl[1])^0.25 else yl[2] + 0.3 * diff(yl)
    graphics::plot(preds[[1]]$TIME, preds[[1]][[b$mid]], type = "n", ylim = yl, log = lg,
                   xlim = range(unlist(lapply(preds, `[[`, "TIME"))), xlab = xlab, ylab = ylab,
                   main = if (is.null(main)) "Predicted concentrations, new subjects" else main, ...)
    for (k in seq_along(preds)) {
      p <- preds[[k]]
      draw_band(p$TIME, pmax(p[[b$lo]], if (log) yl[1] else -Inf), p[[b$hi]], p[[b$mid]], cols[k])
    }
    reg <- attr(x, "regimen")
    if (!is.null(reg)) graphics::rug(reg$time, col = okabe[["grey"]])
    if (length(preds) == 1) labels <- c(labels[1], b$label)
    lcol <- if (length(preds) == 1) c(cols, NA) else cols
    lfill <- if (length(preds) == 1) c(NA, grDevices::adjustcolor(cols, 0.25)) else grDevices::adjustcolor(cols, 0.25)
    graphics::legend("topright", legend = if (length(preds) == 1) labels else
                       paste0(labels, " (median, ", b$label, ")"),
                     col = lcol, lwd = ifelse(is.na(lcol), NA, 2), fill = lfill, border = NA,
                     bg = grDevices::adjustcolor("white", 0.85), box.col = NA, cex = 0.85)
    return(invisible(x))
  }
  plot_individual(x, x, ids = ids, log = log, xlab = xlab, ylab = ylab, ...)
  invisible(x)
}

#' Plot a fit
#'
#' `type = "individual"`: observed concentrations with individual predictions
#' (median and interval), one panel per subject. `type = "obs_pred"`:
#' observed against predicted concentrations (individual medians) with the line
#' of identity. `type = "trace"`: trace plots of the population parameters, one
#' colour per chain; chains that do not overlap have not mixed.
#'
#' @param x A `bpk_fit`.
#' @param type One of `"individual"`, `"obs_pred"`, `"trace"`.
#' @param ... Passed to [plot.bpk_prediction()] for `"individual"`.
#' @return `x`, invisibly.
#' @examples
#' \donttest{
#' fit <- bpk_fit(pk_model("1cmt", "oral", iiv = c("CL", "V")), bpk_example,
#'                chains = 2, iter = 1000, seed = 1)
#' plot(fit)
#' plot(fit, type = "obs_pred")
#' plot(fit, type = "trace")
#' }
#' @export
plot.bpk_fit <- function(x, type = c("individual", "obs_pred", "trace"), ...) {
  dots <- list(...)
  type <- match.arg(type)
  if (type == "individual") {
    obs <- stats::predict(x, ndraws = 400)
    grid <- seq(0, max(x$prep$obs$time), length.out = 120)
    curve <- stats::predict(x, times = grid, ndraws = 400)
    plot_individual(curve, obs, ...)
  } else if (type == "obs_pred") {
    p <- stats::predict(x, ndraws = 400)
    b <- band_cols(p)
    lim <- range(c(p$DV, p[[b$mid]]), na.rm = TRUE)
    graphics::plot(p[[b$mid]], p$DV, pch = 19, col = grDevices::adjustcolor(okabe[["blue"]], 0.6),
                   xlim = lim, ylim = lim, xlab = if (is.null(dots$xlab)) "Predicted concentration (individual median)" else dots$xlab,
                   ylab = if (is.null(dots$ylab)) "Observed concentration" else dots$ylab, main = sprintf("Observed vs predicted (n = %d)", nrow(p)))
    graphics::abline(0, 1, col = okabe[["vermillion"]], lwd = 2)
  } else {
    a <- posterior::as_draws_array(bpk_draws(x))
    vars <- posterior::variables(a)
    nch <- posterior::nchains(a)
    cols <- rep(unname(okabe[c("blue", "orange", "green", "vermillion", "sky", "grey")]), length.out = nch)
    nc <- ceiling(sqrt(length(vars))); nr <- ceiling(length(vars) / nc)
    op <- graphics::par(mfrow = c(nr, nc), mar = c(3, 3, 2, 0.5), mgp = c(1.8, 0.6, 0))
    on.exit(graphics::par(op))
    for (v in vars) {
      m <- matrix(as.numeric(a[, , v]), ncol = nch)
      graphics::matplot(m, type = "l", lty = 1, col = grDevices::adjustcolor(cols, 0.7),
                        xlab = "Iteration (after warmup)", ylab = v, main = v)
    }
  }
  invisible(x)
}

#' @export
print.bpk_prediction <- function(x, ...) {
  print(structure(x, class = "data.frame", kind = NULL, probs = NULL, regimen = NULL), ...)
  invisible(x)
}

# Panels per subject: band and median from `curve`, observed points from `obs`.
plot_individual <- function(curve, obs, ids = NULL, log = FALSE, xlab = "Time",
                            ylab = "Concentration", ...) {
  b <- band_cols(curve)
  lg <- if (log) "y" else ""
  all_ids <- unique(curve$ID)
  if (is.null(ids)) ids <- utils::head(all_ids, 12)
  n <- length(ids)
  nc <- ceiling(sqrt(n)); nr <- ceiling(n / nc)
  op <- graphics::par(mfrow = c(nr, nc), mar = c(3, 3, 2, 0.5), mgp = c(1.8, 0.6, 0))
  on.exit(graphics::par(op))
  for (id in ids) {
    s <- curve[curve$ID == id, ]
    o <- obs[obs$ID == id & !is.na(obs$DV), ]
    if (log) {
      s <- s[s[[b$mid]] > 0, ]
      o <- o[o$DV > 0, ]
    }
    yl <- range(c(o$DV, s[[b$lo]], s[[b$hi]]), na.rm = TRUE)
    if (log) yl[1] <- max(min(c(o$DV, s[[b$mid]]), na.rm = TRUE) / 2, 1e-12)
    graphics::plot(s$TIME, s[[b$mid]], type = "n", ylim = yl, log = lg, xlab = xlab,
                   ylab = ylab, main = paste("ID", id), ...)
    draw_band(s$TIME, pmax(s[[b$lo]], yl[1]), s[[b$hi]], s[[b$mid]])
    graphics::points(o$TIME, o$DV, pch = 19, col = okabe[["vermillion"]], cex = 0.8)
  }
  invisible(curve)
}
