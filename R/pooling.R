#' Replicate-weight variance factors
#'
#' Returns the multiplier \eqn{c} in the replicate-variance formula
#' \eqn{V = c \sum_r (\hat\theta_r - \hat\theta_0)^2}, for the common
#' large-scale-assessment replication designs.
#'
#' @param method One of `"BRR"` (balanced repeated replication, the PISA
#'   default), `"JK2"` (paired jackknife, used by TIMSS/PIRLS), or `"JK1"`.
#' @param n_rep Number of replicate weights.
#' @param fay Fay's adjustment factor for BRR (PISA uses 0.5). Must lie in
#'   \eqn{[0, 1)}. Ignored for jackknife methods.
#'
#' @details
#' * BRR/Fay: \eqn{c = 1 / (R (1 - k)^2)}, where `k` is `fay`. With `fay = 0`
#'   this is ordinary BRR (\eqn{1/R}); with `fay = 0.5` (PISA) it is \eqn{4/R}.
#' * JK2 (IEA paired-zone construction): \eqn{c = 1}.
#' * JK1 (single-stratum / equal-zone): \eqn{c = (R - 1) / R}.
#'
#' @return A single numeric multiplier.
#' @references
#' OECD (2009). *PISA Data Analysis Manual: SPSS and SAS, Second Edition*.
#' OECD Publishing. (Replicate-weight variance estimation.)
#' @examples
#' rep_factor("BRR", n_rep = 80, fay = 0.5) # PISA: 1/20
#' rep_factor("JK2", n_rep = 75)            # TIMSS/PIRLS: 1
#' @export
rep_factor <- function(method = c("BRR", "JK2", "JK1"), n_rep, fay = 0.5) {
  method <- match.arg(method)
  if (!is.numeric(n_rep) || length(n_rep) != 1L || n_rep < 1) {
    stop("`n_rep` must be a positive integer.", call. = FALSE)
  }
  if (method == "BRR" && (!is.numeric(fay) || fay < 0 || fay >= 1)) {
    stop("`fay` must be a single number in [0, 1).", call. = FALSE)
  }
  switch(method,
    BRR = 1 / (n_rep * (1 - fay)^2),
    JK2 = 1,
    JK1 = (n_rep - 1) / n_rep
  )
}

#' Pool point estimates and variances across plausible values (Rubin's rules)
#'
#' Combines per-plausible-value point estimates and their (design-based)
#' sampling variances into a single estimate, standard error, and
#' \eqn{t}-reference test following the multiple-imputation combining rules of
#' Rubin (1987).
#'
#' @param estimates Numeric vector of per-PV point estimates
#'   (\eqn{\hat\theta_p}), length `m` = number of plausible values.
#' @param variances Numeric vector of per-PV *sampling* variances
#'   (\eqn{U_p}), same length. Pass zeros when no design-based variance is
#'   available (the result is then the imputation variance only). A non-finite
#'   entry propagates to an `NA` standard error rather than an error.
#' @param level Confidence level for the returned interval (default `0.95`).
#'
#' @details
#' With `m` plausible values the pooled estimate is the mean of the per-PV
#' estimates. The total variance is
#' \deqn{T = \bar U + (1 + 1/m) B,}
#' where \eqn{\bar U} is the mean sampling variance (within-imputation) and
#' \eqn{B} is the between-PV variance (the imputation/measurement component).
#' Inference uses a \eqn{t} reference with Rubin's degrees of freedom
#' \deqn{\nu = (m - 1)\left(1 + \frac{\bar U}{(1 + 1/m) B}\right)^2,}
#' which correctly widens intervals when the imputation component is
#' non-negligible relative to the sampling component (the usual case for the
#' small number of plausible values, 5 or 10, in PISA/TIMSS/PIRLS). When there
#' is no imputation variance (a single plausible value) the reference reduces
#' to the normal (\eqn{\nu = \infty}); when there is no sampling variance the
#' reference is \eqn{t} on \eqn{m - 1} degrees of freedom.
#'
#' @return A named list: `estimate`, `se`, `statistic` (estimate / se), `df`
#'   (Rubin degrees of freedom), `p` (two-sided), `ci_lo`, `ci_hi`,
#'   `var_sampling` (\eqn{\bar U}), `var_imputation` (the \eqn{(1 + 1/m) B}
#'   term), and `m`.
#' @references
#' Rubin, D. B. (1987). *Multiple Imputation for Nonresponse in Surveys*.
#' Wiley. Barnard, J. & Rubin, D. B. (1999). Small-sample degrees of freedom
#' with multiple imputation. *Biometrika*, 86(4), 948-955.
#' @examples
#' # five plausible values, each with a sampling variance of 4
#' pool_pv(estimates = c(508, 511, 509, 513, 510), variances = rep(16, 5))
#' @export
pool_pv <- function(estimates, variances, level = 0.95) {
  estimates <- as.numeric(estimates)
  variances <- as.numeric(variances)
  if (length(estimates) != length(variances)) {
    stop("`estimates` and `variances` must have the same length.", call. = FALSE)
  }
  m <- length(estimates)
  est <- mean(estimates)
  u_bar <- mean(variances)                       # NA propagates by design
  b <- if (m > 1L) stats::var(estimates) else 0
  var_imp <- (1 + 1 / m) * b
  total <- u_bar + var_imp
  se <- sqrt(total)

  # Rubin degrees of freedom; Inf (-> normal) when there is no imputation
  # variance, m-1 when there is no sampling variance.
  df <- if (is.finite(var_imp) && var_imp > 0 && is.finite(u_bar)) {
    (m - 1) * (1 + u_bar / var_imp)^2
  } else if (is.finite(var_imp) && var_imp > 0) {
    m - 1
  } else {
    Inf
  }

  stat <- if (is.finite(se) && se > 0) est / se else NA_real_
  p <- if (is.na(stat)) NA_real_ else 2 * stats::pt(-abs(stat), df = df)
  a <- (1 - level) / 2
  q <- if (is.finite(se)) stats::qt(1 - a, df = df) else NA_real_
  list(
    estimate = est, se = se, statistic = stat, df = df, p = p,
    ci_lo = est - q * se, ci_hi = est + q * se,
    var_sampling = u_bar, var_imputation = var_imp, m = m
  )
}

# Pool a matrix of per-term, per-PV estimates/variances into a coefficient
# data frame. Rows are terms; columns are plausible values. Shared by every
# estimator so the combining rules live in exactly one place.
pool_rows <- function(est_mat, var_mat, terms = rownames(est_mat), level = 0.95) {
  rows <- lapply(seq_along(terms), function(i) {
    pl <- pool_pv(est_mat[i, ], var_mat[i, ], level = level)
    data.frame(estimate = pl$estimate, se = pl$se, statistic = pl$statistic,
               df = pl$df, p = pl$p, ci_lo = pl$ci_lo, ci_hi = pl$ci_hi)
  })
  out <- do.call(rbind, rows)
  rownames(out) <- terms
  out
}

# ---------------------------------------------------------------------------
# Shared parent class for all lsastrat estimators.
# ---------------------------------------------------------------------------

# Constructor: `coefficients` is the pooled data frame from pool_rows();
# `meta` is a named list of provenance/printing fields (must include a
# character `header`; may include `footnote`, `call`, `estimator`, etc.).
new_lsastrat_estimate <- function(coefficients, meta = list(), subclass) {
  obj <- c(list(coefficients = coefficients), meta)
  class(obj) <- c(subclass, "lsastrat_estimate")
  obj
}

#' Methods for lsastrat estimate objects
#'
#' All three estimators ([social_gradient()], [segregation_index()],
#' [ieop()]) return an object of class `"lsastrat_estimate"` carrying a pooled
#' `coefficients` data frame (columns `estimate`, `se`, `statistic`, `df`,
#' `p`, `ci_lo`, `ci_hi`). These methods provide a uniform interface.
#'
#' @param x,object An `"lsastrat_estimate"` object.
#' @param parm Optional subset of terms (rows) for `confint`.
#' @param level Confidence level for `confint`.
#' @param digits Number of digits for `print`.
#' @param ... Unused.
#' @return `coef` a named numeric vector; `confint` a matrix; `as.data.frame`
#'   a data frame with a `term` column; `print`/`summary` the object invisibly.
#' @name lsastrat_estimate
NULL

#' @rdname lsastrat_estimate
#' @export
print.lsastrat_estimate <- function(x, digits = 3, ...) {
  cat(x$header, sep = "\n")
  cat("\n\n")
  co <- x$coefficients
  tab <- data.frame(
    Estimate = round(co$estimate, digits),
    Std.Error = round(co$se, digits),
    t = round(co$statistic, 2),
    df = ifelse(is.finite(co$df), round(co$df, 1), Inf),
    p = signif(co$p, 2),
    row.names = rownames(co)
  )
  print(tab)
  if (!is.null(x$footnote)) cat("\n", x$footnote, "\n", sep = "")
  invisible(x)
}

#' @rdname lsastrat_estimate
#' @export
summary.lsastrat_estimate <- function(object, ...) {
  print(object, ...)
  invisible(object)
}

#' @rdname lsastrat_estimate
#' @export
coef.lsastrat_estimate <- function(object, ...) {
  stats::setNames(object$coefficients$estimate, rownames(object$coefficients))
}

#' @rdname lsastrat_estimate
#' @export
confint.lsastrat_estimate <- function(object, parm, level = 0.95, ...) {
  co <- object$coefficients
  a <- (1 - level) / 2
  lo <- co$estimate - stats::qt(1 - a, df = co$df) * co$se
  hi <- co$estimate + stats::qt(1 - a, df = co$df) * co$se
  out <- cbind(lo, hi)
  colnames(out) <- paste0(format(100 * c(a, 1 - a), trim = TRUE, nsmall = 1), " %")
  rownames(out) <- rownames(co)
  if (!missing(parm)) out <- out[parm, , drop = FALSE]
  out
}

#' @rdname lsastrat_estimate
#' @export
as.data.frame.lsastrat_estimate <- function(x, ...) {
  co <- x$coefficients
  data.frame(term = rownames(co), co, row.names = NULL, check.names = FALSE)
}
