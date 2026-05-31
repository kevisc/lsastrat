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
#' @param fay Fay adjustment for BRR (PISA uses 0.5).
#' @param curvature Logical; if `TRUE` (default) also fit a quadratic model and
#'   report the curvature (ESCS-squared) coefficient.
#'
#' @return An object of class `"social_gradient"`: a list with a `coefficients`
#'   data frame (rows `slope`, `strength`, and optionally `curvature`; columns
#'   `estimate`, `se`, `t`, `p`) plus metadata.
#'
#' @references
#' OECD (2023). *PISA 2022 Results (Volume I)*, Annex A3 (socio-economic
#' gradient: slope and strength = \eqn{R^2 \times 100}).
#'
#' @examples
#' set.seed(1)
#' n <- 2000
#' escs <- rnorm(n)
#' # true gradient: 40 score points per ESCS unit
#' pv <- replicate(5, 500 + 40 * escs + rnorm(n, sd = 80))
#' colnames(pv) <- paste0("PV", 1:5, "READ")
#' dat <- data.frame(escs, pv, W_FSTUWT = runif(n, 0.5, 2))
#' social_gradient(dat, achievement = colnames(pv), escs = "escs",
#'                 weight = "W_FSTUWT")
#' @export
social_gradient <- function(data,
                            achievement,
                            escs = "ESCS",
                            weight = NULL,
                            repweights = NULL,
                            rep_method = c("BRR", "JK2", "JK1"),
                            fay = 0.5,
                            curvature = TRUE) {
  rep_method <- match.arg(rep_method)
  stopifnot(is.data.frame(data))

  # --- validate columns ---------------------------------------------------
  miss <- setdiff(c(achievement, escs, weight, repweights), names(data))
  if (length(miss)) {
    stop("Columns not found in `data`: ", paste(miss, collapse = ", "),
         call. = FALSE)
  }

  if (is.null(weight)) {
    message("No `weight` supplied; using equal weights.")
    w <- rep(1, nrow(data))
  } else {
    w <- data[[weight]]
  }

  design_based <- !is.null(repweights)
  if (!design_based) {
    warning("No `repweights` supplied: standard errors are model-based and ",
            "ignore the complex sample design. Supply replicate weights for ",
            "design-correct inference.", call. = FALSE)
  } else {
    cfac <- rep_factor(rep_method, n_rep = length(repweights), fay = fay)
  }

  x <- data[[escs]]
  params <- if (curvature) c("slope", "strength", "curvature")
            else c("slope", "strength")

  # per-PV point estimates and sampling variances, one row per parameter
  est_mat <- matrix(NA_real_, nrow = length(params), ncol = length(achievement),
                    dimnames = list(params, NULL))
  var_mat <- matrix(0, nrow = length(params), ncol = length(achievement),
                    dimnames = list(params, NULL))

  for (j in seq_along(achievement)) {
    y <- data[[achievement[j]]]
    point <- .gradient_fit(y, x, w, curvature)
    est_mat[, j] <- point[params]

    if (design_based) {
      reps <- vapply(repweights, function(rw) {
        .gradient_fit(y, x, data[[rw]], curvature)[params]
      }, numeric(length(params)))
      # V = c * sum_r (theta_r - theta_0)^2, per parameter
      dev2 <- (reps - point[params])^2
      var_mat[, j] <- cfac * rowSums(dev2)
    }
  }

  # --- pool across PVs ----------------------------------------------------
  rows <- lapply(params, function(p) {
    pl <- pool_pv(est_mat[p, ], var_mat[p, ])
    data.frame(estimate = pl$estimate, se = pl$se, t = pl$t, p = pl$p)
  })
  coefs <- do.call(rbind, rows)
  rownames(coefs) <- params

  structure(
    list(
      coefficients = coefs,
      escs = escs,
      achievement = achievement,
      n_pv = length(achievement),
      n_obs = nrow(data),
      design_based = design_based,
      rep_method = if (design_based) rep_method else NA_character_,
      n_rep = if (design_based) length(repweights) else 0L,
      curvature = curvature
    ),
    class = "social_gradient"
  )
}

# Single weighted fit: returns slope, strength (R^2 * 100) from the LINEAR
# model, and (optionally) the curvature coefficient from the QUADRATIC model.
# Strength follows OECD and is taken from the linear model.
.gradient_fit <- function(y, x, w, curvature) {
  ok <- is.finite(y) & is.finite(x) & is.finite(w) & w > 0
  y <- y[ok]; x <- x[ok]; w <- w[ok]

  fit <- stats::lm(y ~ x, weights = w)
  slope <- unname(stats::coef(fit)[["x"]])

  # weighted R^2 of the linear model
  mu <- stats::weighted.mean(y, w)
  ss_tot <- sum(w * (y - mu)^2)
  ss_res <- sum(w * stats::residuals(fit)^2)
  r2 <- if (ss_tot > 0) 1 - ss_res / ss_tot else NA_real_
  strength <- r2 * 100

  out <- c(slope = slope, strength = strength)
  if (curvature) {
    fit2 <- stats::lm(y ~ x + I(x^2), weights = w)
    out[["curvature"]] <- unname(stats::coef(fit2)[["I(x^2)"]])
  }
  out
}

#' @export
print.social_gradient <- function(x, digits = 3, ...) {
  cat("Socio-economic achievement gradient\n")
  cat(sprintf("  SES index: %s   |   %d plausible value(s)   |   n = %d\n",
              x$escs, x$n_pv, x$n_obs))
  if (x$design_based) {
    cat(sprintf("  Variance:  %s, %d replicate weights (+ PV imputation)\n",
                x$rep_method, x$n_rep))
  } else {
    cat("  Variance:  model-based (no replicate weights)\n")
  }
  cat("\n")
  co <- x$coefficients
  out <- data.frame(
    Estimate = round(co$estimate, digits),
    Std.Error = round(co$se, digits),
    z = round(co$t, 2),
    p = signif(co$p, 2),
    row.names = rownames(co)
  )
  print(out)
  cat("\nslope = score points per 1 ESCS unit; ",
      "strength = % achievement variance explained (R^2 x 100)\n", sep = "")
  invisible(x)
}

#' @export
summary.social_gradient <- function(object, ...) {
  print(object, ...)
  invisible(object)
}
