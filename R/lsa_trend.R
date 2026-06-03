#' Trend across assessment cycles with linking error
#'
#' Compares a quantity (a gradient slope, a mean, a segregation index, ...)
#' across two or more assessment cycles and reports the change from the
#' baseline cycle, propagating the **linking (equating) error** into the
#' standard error of each change. Comparing scores across PISA/TIMSS cycles
#' carries an extra uncertainty from re-equating the scale; the variance of a
#' cross-cycle difference is
#' \deqn{\mathrm{Var}(\Delta) = SE_1^2 + SE_2^2 + \mathrm{linkerror}^2.}
#'
#' The link error applies only to quantities expressed on the **achievement
#' scale** (means, score-point gradient slopes). For scale-free quantities
#' (correlations, the gradient *strength* / \eqn{R^2}, segregation indices,
#' inequality-of-opportunity shares) set `link_error = 0`.
#'
#' @param cycles A **named** list of fitted estimate objects (class
#'   `"lsastrat_estimate"`), one per cycle, in chronological order; the names
#'   are the cycle labels (e.g. `"2012"`, `"2018"`, `"2022"`). The first cycle
#'   is the baseline.
#' @param term Which term (coefficient row) to track; defaults to the first.
#' @param link_error The linking error to add to each change's standard error:
#'   a single value applied to every cycle-vs-baseline comparison, or a vector
#'   of length `length(cycles) - 1`. Defaults to `0` (no link error).
#' @param level Confidence level for the change intervals (default `0.95`).
#'
#' @return An object of class `"lsa_trend"`: a list with a `coefficients` data
#'   frame (one row per cycle: `estimate`, `se`, and -- for non-baseline cycles
#'   -- `change`, `change_se`, `statistic`, `p`, `ci_lo`, `ci_hi` of the change
#'   from baseline) plus metadata. Cross-cycle change tests use a normal
#'   reference.
#'
#' @references
#' OECD (2023). *PISA 2022 Technical Report*, chapter on linking error and
#' trends.
#'
#' @examples
#' data(pisa_mini)
#' des <- lsa_design(weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
#' math <- paste0("PV", 1:10, "MATH")
#' # two illustrative "cycles" (here, two halves of the simulated data)
#' h <- nrow(pisa_mini) %/% 2
#' c1 <- social_gradient(pisa_mini[1:h, ], math, "ESCS", design = des)
#' c2 <- social_gradient(pisa_mini[-(1:h), ], math, "ESCS", design = des)
#' lsa_trend(list("2018" = c1, "2022" = c2), term = "slope", link_error = 3.5)
#' @export
lsa_trend <- function(cycles, term = NULL, link_error = 0, level = 0.95) {
  if (!is.list(cycles) || is.null(names(cycles)) || any(names(cycles) == "")) {
    stop("`cycles` must be a named list of estimate objects ",
         "(names = cycle labels).", call. = FALSE)
  }
  if (!all(vapply(cycles, inherits, logical(1), "lsastrat_estimate"))) {
    stop("Each element of `cycles` must be an lsastrat_estimate ",
         "(e.g. from social_gradient()).", call. = FALSE)
  }
  labels <- names(cycles)
  k <- length(labels)
  if (k < 2L) stop("`cycles` needs at least two cycles.", call. = FALSE)

  pick <- function(e) {
    co <- e$coefficients
    tm <- if (is.null(term)) rownames(co)[1] else term
    if (!tm %in% rownames(co)) {
      stop("Term '", tm, "' is not in the cycle estimates.", call. = FALSE)
    }
    c(estimate = co[tm, "estimate"], se = co[tm, "se"])
  }
  vals <- vapply(cycles, pick, numeric(2))
  est <- vals["estimate", ]
  se <- vals["se", ]

  le <- if (length(link_error) == 1L) rep(link_error, k - 1L) else link_error
  if (length(le) != k - 1L) {
    stop("`link_error` must have length 1 or ", k - 1L, ".", call. = FALSE)
  }
  if (any(le < 0)) stop("`link_error` must be non-negative.", call. = FALSE)

  change <- est - est[1]
  change_se <- c(NA_real_, sqrt(se[-1]^2 + se[1]^2 + le^2))
  z <- change / change_se
  p <- 2 * stats::pnorm(-abs(z))
  q <- stats::qnorm(1 - (1 - level) / 2)

  coefs <- data.frame(
    cycle = labels, estimate = est, se = se,
    change = change, change_se = change_se, statistic = z, p = p,
    ci_lo = change - q * change_se, ci_hi = change + q * change_se,
    row.names = NULL, stringsAsFactors = FALSE
  )
  term_used <- if (is.null(term)) rownames(cycles[[1]]$coefficients)[1] else term

  structure(
    list(coefficients = coefs, term = term_used,
         estimator = cycles[[1]]$estimator, baseline = labels[1],
         link_error = le, n_cycles = k),
    class = "lsa_trend"
  )
}

#' @export
print.lsa_trend <- function(x, digits = 3, ...) {
  cat(sprintf("Trend in `%s` (%s) across %d cycles; baseline = %s\n",
              x$term, x$estimator, x$n_cycles, x$baseline))
  if (any(x$link_error > 0)) {
    cat(sprintf("  linking error: %s (added to each change SE)\n",
                paste(signif(x$link_error, 3), collapse = ", ")))
  }
  cat("\n")
  co <- x$coefficients
  out <- data.frame(
    cycle = co$cycle,
    estimate = round(co$estimate, digits),
    se = round(co$se, digits),
    change = round(co$change, digits),
    change.se = round(co$change_se, digits),
    z = round(co$statistic, 2),
    p = signif(co$p, 2)
  )
  print(out, row.names = FALSE)
  cat("\nchange = estimate - baseline; SE includes the linking error\n")
  invisible(x)
}

#' Plot a cross-cycle trend
#'
#' Plots the estimate at each cycle with confidence bars (the baseline cycle's
#' own SE, and the link-error-inflated change SE for later cycles).
#'
#' @param x An `"lsa_trend"` object.
#' @param ... Passed to [graphics::plot()].
#' @return `x`, invisibly.
#' @export
plot.lsa_trend <- function(x, ...) {
  co <- x$coefficients
  xs <- seq_len(nrow(co))
  # bar half-width: baseline uses its own se; later cycles use change_se
  hw <- ifelse(is.na(co$change_se), co$se, co$change_se)
  yr <- range(c(co$estimate - hw, co$estimate + hw), na.rm = TRUE)
  graphics::plot(xs, co$estimate, pch = 19, xaxt = "n", xlim = c(0.5, nrow(co) + 0.5),
                 ylim = yr, xlab = "Cycle", ylab = x$term,
                 main = sprintf("Trend in %s", x$term), ...)
  graphics::axis(1, at = xs, labels = co$cycle)
  graphics::segments(xs, co$estimate - hw, xs, co$estimate + hw)
  graphics::lines(xs, co$estimate, col = "steelblue", lwd = 2)
  graphics::abline(h = co$estimate[1], col = "grey70", lty = 3)
  invisible(x)
}
