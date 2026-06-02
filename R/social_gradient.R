#' Socio-economic achievement gradient
#'
#' Computes the socio-economic gradient of achievement from large-scale
#' assessment data, following the OECD PISA definition: the **slope** is the
#' score-point change in achievement per one-unit change in the socio-economic
#' index (e.g. ESCS), and the **strength** is the percentage of achievement
#' variance explained by socio-economic status (\eqn{R^2 \times 100}).
#' Optionally the quadratic **curvature** term is also reported.
#'
#' Achievement is supplied as a set of plausible values (PVs); estimates are
#' pooled across PVs with Rubin's rules, and the sampling variance is obtained
#' from replicate weights when supplied (see [pool_pv()] and [rep_factor()]).
#' Inference uses a \eqn{t} reference (see [pool_pv()] for the degrees of
#' freedom).
#'
#' @param data A data frame of student-level records.
#' @param achievement Character vector of column names holding the achievement
#'   plausible values (e.g. `paste0("PV", 1:10, "MATH")`). A single column is
#'   allowed but then no imputation variance is estimated.
#' @param escs Name of the socio-economic index column (default `"ESCS"`).
#' @param weight Name of the final student weight column. If `NULL`, all cases
#'   are weighted equally (with a message).
#' @param repweights Optional character vector of replicate-weight column
#'   names. When supplied, standard errors are design-based; when `NULL`, a
#'   model-based (independence) standard error is returned with a warning.
#' @param rep_method Replication design: `"BRR"` (PISA default), `"JK2"`
#'   (TIMSS/PIRLS) or `"JK1"`. Used only when `repweights` is supplied.
#' @param fay Fay adjustment for BRR (PISA uses 0.5); see [rep_factor()].
#' @param curvature Logical; if `TRUE` (default) also fit a quadratic model and
#'   report the curvature (ESCS-squared) coefficient.
#' @param level Confidence level for the stored interval (default `0.95`).
#'
#' @return An object of class `"social_gradient"` / `"lsastrat_estimate"` (see
#'   [lsastrat_estimate] for methods): a list with a `coefficients` data frame
#'   (rows `slope`, `strength`, and optionally `curvature`) plus metadata.
#'
#' @references
#' OECD (2023). *PISA 2022 Results (Volume I)*, Annex A3 (socio-economic
#' gradient: slope and strength = \eqn{R^2 \times 100}).
#'
#' @examples
#' data(pisa_mini)
#' social_gradient(
#'   pisa_mini,
#'   achievement = paste0("PV", 1:10, "MATH"),
#'   escs = "ESCS",
#'   weight = "W_FSTUWT",
#'   repweights = paste0("W_FSTURWT", 1:64)
#' )
#' @export
social_gradient <- function(data,
                            achievement,
                            escs = "ESCS",
                            weight = NULL,
                            repweights = NULL,
                            rep_method = c("BRR", "JK2", "JK1"),
                            fay = 0.5,
                            curvature = TRUE,
                            level = 0.95) {
  rep_method <- match.arg(rep_method)
  .assert_data_frame(data)
  .assert_character(achievement, "achievement")
  .assert_columns(data, c(achievement, escs, weight, repweights))

  wfull <- .resolve_weight(data, weight)
  design_based <- !is.null(repweights)
  if (!design_based) {
    warning("No `repweights` supplied: standard errors are model-based and ",
            "ignore the complex sample design. Supply replicate weights for ",
            "design-correct inference.", call. = FALSE)
  } else {
    cfac <- rep_factor(rep_method, n_rep = length(repweights), fay = fay)
  }

  x <- data[[escs]]

  # Analysis-sample mask computed ONCE, so every replicate and every PV uses
  # the same row set (a zero replicate weight still drops a case via weighting,
  # without changing the row set).
  mask <- is.finite(x) & is.finite(wfull) & wfull > 0 &
    stats::complete.cases(data[achievement])
  n_analytic <- sum(mask)
  if (n_analytic < 3L) {
    stop("Too few complete cases (", n_analytic, ") to fit a gradient.",
         call. = FALSE)
  }
  if (n_analytic < length(mask)) {
    message(sprintf("Using %d of %d rows (dropped %d with missing ESCS / ",
                    n_analytic, length(mask), length(mask) - n_analytic),
            "achievement / non-positive weight).")
  }
  x <- x[mask]
  if (stats::var(x) == 0) {
    stop("The SES index `", escs, "` is constant; gradient is undefined.",
         call. = FALSE)
  }
  wfull <- wfull[mask]
  ys <- lapply(achievement, function(a) data[[a]][mask])
  rws <- if (design_based) lapply(repweights, function(r) data[[r]][mask]) else NULL

  params <- if (curvature) c("slope", "strength", "curvature")
            else c("slope", "strength")
  est_mat <- matrix(NA_real_, length(params), length(achievement),
                    dimnames = list(params, NULL))
  var_mat <- matrix(0, length(params), length(achievement),
                    dimnames = list(params, NULL))

  for (j in seq_along(ys)) {
    point <- .gradient_fit(ys[[j]], x, wfull, curvature)
    est_mat[, j] <- point[params]
    if (design_based) {
      reps <- vapply(rws, function(w) .gradient_fit(ys[[j]], x, w, curvature)[params],
                     numeric(length(params)))
      var_mat[, j] <- cfac * rowSums((reps - point[params])^2)
    }
  }

  if (anyNA(est_mat["strength", ])) {
    warning("Achievement appears constant; strength (R^2) is undefined.",
            call. = FALSE)
  }

  coefs <- pool_rows(est_mat, var_mat, params, level = level)

  header <- c(
    "Socio-economic achievement gradient",
    sprintf("  SES index: %s   |   %d plausible value(s)   |   n = %d",
            escs, length(achievement), n_analytic),
    if (design_based)
      sprintf("  Variance:  %s, %d replicate weights (+ PV imputation); t reference",
              rep_method, length(repweights))
    else "  Variance:  model-based (no replicate weights)"
  )

  new_lsastrat_estimate(
    coefs,
    meta = list(
      header = header,
      footnote = paste0("slope = score points per 1 unit of ", escs,
                        "; strength = % variance explained (R^2 x 100)"),
      estimator = "social_gradient",
      escs = escs, achievement = achievement, n_pv = length(achievement),
      n_obs = nrow(data), n_analytic = n_analytic, curvature = curvature,
      design_based = design_based,
      rep_method = if (design_based) rep_method else NA_character_,
      n_rep = if (design_based) length(repweights) else 0L,
      fay = if (design_based) fay else NA_real_,
      plot_data = .gradient_plot_data(ys, x, wfull, curvature),
      call = match.call(), version = utils::packageVersion("lsastrat")
    ),
    subclass = "social_gradient"
  )
}

# Single weighted fit on an already-masked sample: slope and strength
# (R^2 * 100) from the LINEAR model (OECD definition), plus the curvature
# coefficient from the QUADRATIC model when requested.
.gradient_fit <- function(y, x, w, curvature) {
  fit <- stats::lm(y ~ x, weights = w)
  slope <- unname(stats::coef(fit)[["x"]])

  mu <- stats::weighted.mean(y, w)
  ss_tot <- sum(w * (y - mu)^2)
  ss_res <- sum(w * stats::residuals(fit)^2)
  r2 <- if (ss_tot > 0) 1 - ss_res / ss_tot else NA_real_

  out <- c(slope = slope, strength = r2 * 100)
  if (curvature) {
    fit2 <- stats::lm(y ~ x + I(x^2), weights = w)
    out[["curvature"]] <- unname(stats::coef(fit2)[["I(x^2)"]])
  }
  out
}

# Light, data-free plot summary: weighted achievement (PV-averaged) binned by
# SES decile, plus the fitted line coefficients, stored on the object so
# plot.social_gradient() needs no retained full data.
.gradient_plot_data <- function(ys, x, w, curvature) {
  ybar <- Reduce(`+`, ys) / length(ys)
  brks <- stats::quantile(x, probs = seq(0, 1, 0.1), na.rm = TRUE)
  brks[1] <- -Inf; brks[length(brks)] <- Inf
  bin <- cut(x, breaks = unique(brks), include.lowest = TRUE)
  bx <- tapply(seq_along(x), bin, function(i) stats::weighted.mean(x[i], w[i]))
  by <- tapply(seq_along(x), bin, function(i) stats::weighted.mean(ybar[i], w[i]))
  lin <- stats::coef(stats::lm(ybar ~ x, weights = w))
  quad <- if (curvature) stats::coef(stats::lm(ybar ~ x + I(x^2), weights = w)) else NULL
  list(x = as.numeric(bx), y = as.numeric(by),
       intercept = unname(lin[1]), slope = unname(lin[2]),
       quad = quad, xr = range(x))
}

#' Plot a socio-economic achievement gradient
#'
#' Draws the weighted, SES-binned achievement means with the fitted gradient
#' line overlaid (and the quadratic curve when curvature was estimated). Uses
#' base graphics only.
#'
#' @param x A `"social_gradient"` object.
#' @param ... Passed to [graphics::plot()].
#' @return `x`, invisibly.
#' @export
plot.social_gradient <- function(x, ...) {
  pd <- x$plot_data
  graphics::plot(pd$x, pd$y, xlab = x$escs, ylab = "Achievement",
                 main = "Socio-economic achievement gradient",
                 pch = 19, ...)
  graphics::abline(a = pd$intercept, b = pd$slope, col = "steelblue", lwd = 2)
  if (!is.null(pd$quad)) {
    xs <- seq(pd$xr[1], pd$xr[2], length.out = 100)
    graphics::lines(xs, pd$quad[1] + pd$quad[2] * xs + pd$quad[3] * xs^2,
                    col = "firebrick", lwd = 2, lty = 2)
    graphics::legend("topleft", c("linear", "quadratic"), bty = "n",
                     col = c("steelblue", "firebrick"), lwd = 2, lty = c(1, 2))
  }
  invisible(x)
}
