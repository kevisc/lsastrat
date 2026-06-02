# ggplot2 autoplot methods (ggplot2 is in Suggests; methods are registered on
# ggplot2's generic and guarded by requireNamespace).

utils::globalVariables(c("estimate", "term", "ci_lo", "ci_hi", "group",
                         "mean", "strength", "spec", "x", "y"))

.need_ggplot <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is required for autoplot(); install it or use plot().",
         call. = FALSE)
  }
}

#' ggplot2 autoplot methods
#'
#' `autoplot()` methods returning \pkg{ggplot2} objects for lsastrat results:
#' a coefficient interval plot for any estimate, the gradient scatter, the
#' by-group forest plot, the quality-equity scatter, and the specification
#' curve. Requires \pkg{ggplot2}.
#'
#' @param object An lsastrat result object.
#' @param term For `lsastrat_by`, which term to plot (default: first).
#' @param ... Unused.
#' @return A `ggplot` object.
#' @name autoplot.lsastrat
NULL

#' @rdname autoplot.lsastrat
#' @exportS3Method ggplot2::autoplot
autoplot.lsastrat_estimate <- function(object, ...) {
  .need_ggplot()
  co <- object$coefficients
  co$term <- factor(rownames(co), levels = rev(rownames(co)))
  ggplot2::ggplot(co, ggplot2::aes(x = estimate, y = term)) +
    ggplot2::geom_vline(xintercept = 0, linetype = 3, colour = "grey60") +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = ci_lo, xmax = ci_hi),
                            height = 0.2) +
    ggplot2::geom_point(size = 2.2) +
    ggplot2::labs(x = "Estimate", y = NULL, title = object$estimator)
}

#' @rdname autoplot.lsastrat
#' @exportS3Method ggplot2::autoplot
autoplot.social_gradient <- function(object, ...) {
  .need_ggplot()
  pd <- object$plot_data
  d <- data.frame(x = pd$x, y = pd$y)
  ggplot2::ggplot(d, ggplot2::aes(x = x, y = y)) +
    ggplot2::geom_point() +
    ggplot2::geom_abline(intercept = pd$intercept, slope = pd$slope,
                         colour = "steelblue", linewidth = 1) +
    ggplot2::labs(x = object$escs, y = "Achievement",
                  title = "Socio-economic achievement gradient")
}

#' @rdname autoplot.lsastrat
#' @exportS3Method ggplot2::autoplot
autoplot.lsastrat_by <- function(object, term = NULL, ...) {
  .need_ggplot()
  df <- object$results
  if (is.null(term)) term <- df$term[1]
  d <- df[df$term == term, , drop = FALSE]
  d$group <- stats::reorder(factor(d$group), d$estimate)
  ggplot2::ggplot(d, ggplot2::aes(x = estimate, y = group)) +
    ggplot2::geom_vline(xintercept = 0, linetype = 3, colour = "grey60") +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = ci_lo, xmax = ci_hi),
                            height = 0.2) +
    ggplot2::geom_point(size = 2.2) +
    ggplot2::labs(x = term, y = object$by,
                  title = sprintf("%s by %s", object$estimator, object$by))
}

#' @rdname autoplot.lsastrat
#' @exportS3Method ggplot2::autoplot
autoplot.equity_scatter <- function(object, ...) {
  .need_ggplot()
  d <- object$data
  ggplot2::ggplot(d, ggplot2::aes(x = strength, y = mean, label = group)) +
    ggplot2::geom_hline(yintercept = base::mean(d$mean), linetype = 3,
                        colour = "grey70") +
    ggplot2::geom_vline(xintercept = base::mean(d$strength), linetype = 3,
                        colour = "grey70") +
    ggplot2::geom_point() +
    ggplot2::geom_text(vjust = -0.6, size = 3) +
    ggplot2::labs(x = "Gradient strength (% variance explained)",
                  y = "Mean achievement",
                  title = sprintf("Quality vs equity by %s", object$by))
}

#' @rdname autoplot.lsastrat
#' @exportS3Method ggplot2::autoplot
autoplot.lsa_multiverse <- function(object, ...) {
  .need_ggplot()
  s <- object$specs[order(object$specs$estimate), , drop = FALSE]
  s$spec <- seq_len(nrow(s))
  ggplot2::ggplot(s, ggplot2::aes(x = spec, y = estimate)) +
    ggplot2::geom_hline(yintercept = 0, linetype = 3, colour = "firebrick") +
    ggplot2::geom_linerange(ggplot2::aes(ymin = ci_lo, ymax = ci_hi),
                            colour = "grey60") +
    ggplot2::geom_point(size = 1.4) +
    ggplot2::labs(x = "Specification (sorted)", y = object$term,
                  title = sprintf("Specification curve: %s (%s)",
                                  object$estimator, object$term))
}
