#' Quality-equity scatter across groups
#'
#' Computes, for each group (typically a country), mean achievement and the
#' socio-economic gradient, and draws the OECD-style "quality vs equity"
#' scatter: mean performance on one axis against the strength of the
#' socio-economic gradient (the percentage of variance ESCS explains) on the
#' other. Reference lines at the across-group averages split the plot into the
#' familiar quadrants (high quality / high equity, and so on).
#'
#' @param data A data frame of student-level records.
#' @param by Name of the grouping column (e.g. country).
#' @param achievement Character vector of achievement plausible-value columns.
#' @param escs Name of the socio-economic index column (default `"ESCS"`).
#' @param weight Name of the final student weight column.
#' @param repweights,rep_method,fay Replicate-weight specification passed to
#'   [social_gradient()].
#'
#' @return An object of class `"equity_scatter"`: a list with `data` (a data
#'   frame of `group`, `mean`, `slope`, `strength`) plus metadata. Plot it with
#'   [plot.equity_scatter()].
#'
#' @examples
#' data(pisa_mini)
#' es <- equity_scatter(pisa_mini, by = "IMMIG",
#'                      achievement = paste0("PV", 1:10, "MATH"),
#'                      escs = "ESCS", weight = "W_FSTUWT")
#' es
#' @export
equity_scatter <- function(data, by, achievement, escs = "ESCS",
                           weight = NULL, repweights = NULL,
                           rep_method = c("BRR", "JK2", "JK1"), fay = 0.5) {
  rep_method <- match.arg(rep_method)
  .assert_data_frame(data)
  .assert_columns(data, c(by, achievement, escs, weight, repweights))

  groups <- split(data, droplevels(as.factor(data[[by]])))
  rows <- lapply(names(groups), function(g) {
    gd <- groups[[g]]
    grad <- suppressWarnings(
      social_gradient(gd, achievement, escs, weight, repweights,
                      rep_method, fay, curvature = FALSE))
    w <- if (is.null(weight)) rep(1, nrow(gd)) else gd[[weight]]
    pv <- rowMeans(vapply(achievement, function(a) gd[[a]], numeric(nrow(gd))))
    ok <- is.finite(w) & w > 0 & is.finite(pv)
    data.frame(group = g,
               mean = stats::weighted.mean(pv[ok], w[ok]),
               slope = grad$coefficients["slope", "estimate"],
               strength = grad$coefficients["strength", "estimate"],
               stringsAsFactors = FALSE)
  })
  structure(
    list(data = do.call(rbind, rows), by = by, achievement = achievement),
    class = "equity_scatter"
  )
}

#' @export
print.equity_scatter <- function(x, digits = 2, ...) {
  cat(sprintf("Quality-equity summary by %s\n\n", x$by))
  d <- x$data
  d[-1] <- lapply(d[-1], round, digits)
  print(d, row.names = FALSE)
  invisible(x)
}

#' Plot a quality-equity scatter
#'
#' @param x An `"equity_scatter"` object.
#' @param x_axis Which gradient measure on the x-axis: `"strength"` (default,
#'   percentage of variance explained) or `"slope"`.
#' @param ... Passed to [graphics::plot()].
#' @return `x`, invisibly.
#' @export
plot.equity_scatter <- function(x, x_axis = c("strength", "slope"), ...) {
  x_axis <- match.arg(x_axis)
  d <- x$data
  xv <- d[[x_axis]]
  xlab <- if (x_axis == "strength") "Gradient strength (% variance explained)"
          else "Gradient slope (points per ESCS unit)"
  graphics::plot(xv, d$mean, pch = 19, xlab = xlab, ylab = "Mean achievement",
                 main = sprintf("Quality vs equity by %s", x$by),
                 xlim = grDevices::extendrange(xv),
                 ylim = grDevices::extendrange(d$mean), ...)
  graphics::abline(h = mean(d$mean), v = mean(xv), col = "grey70", lty = 3)
  graphics::text(xv, d$mean, labels = d$group, pos = 3, cex = 0.8)
  invisible(x)
}
