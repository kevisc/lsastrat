#' Replicate-weight factors
#'
#' Returns the multiplier `c` in the replicate-variance formula
#' \eqn{V = c \sum_r (\hat\theta_r - \hat\theta_0)^2}, for the common
#' LSA replication designs.
#'
#' @param method One of `"BRR"` (balanced repeated replication, the PISA
#'   default), `"JK2"` (paired jackknife, used by TIMSS/PIRLS), or `"JK1"`.
#' @param n_rep Number of replicate weights.
#' @param fay Fay's adjustment factor for BRR (PISA uses 0.5). Ignored for
#'   jackknife methods.
#'
#' @details
#' * BRR/Fay: \eqn{c = 1 / (R (1 - k)^2)}, where `k` is `fay`. With `fay = 0`
#'   this is ordinary BRR (`1/R`); with `fay = 0.5` (PISA) it is `4/R`.
#' * JK2: \eqn{c = 1}.
#' * JK1: \eqn{c = (R - 1) / R}.
#'
#' @return A single numeric multiplier.
#' @keywords internal
rep_factor <- function(method = c("BRR", "JK2", "JK1"), n_rep, fay = 0.5) {
  method <- match.arg(method)
  switch(method,
    BRR = 1 / (n_rep * (1 - fay)^2),
    JK2 = 1,
    JK1 = (n_rep - 1) / n_rep
  )
}

#' Pool point estimates and variances across plausible values (Rubin's rules)
#'
#' Combines per-PV point estimates and their (design-based) sampling variances
#' into a single estimate, standard error, and normal-approximation test.
#'
#' @param estimates Numeric vector of per-PV point estimates
#'   (\eqn{\hat\theta_p}), length `m` = number of PVs.
#' @param variances Numeric vector of per-PV *sampling* variances
#'   (\eqn{U_p}), same length. Pass a vector of zeros when no design-based
#'   variance is available (the result is then the imputation variance only).
#'
#' @details
#' With `m` plausible values the pooled estimate is the mean of the per-PV
#' estimates. The total variance is
#' \deqn{T = \bar U + (1 + 1/m) B,}
#' where \eqn{\bar U} is the mean sampling variance (within-imputation) and
#' \eqn{B} is the between-PV variance (the imputation/measurement component).
#' This is the standard combination rule used for PISA, TIMSS and PIRLS.
#'
#' @return A named list: `estimate`, `se`, `t` (estimate / se), `p` (two-sided
#'   normal), `var_sampling` (\eqn{\bar U}), `var_imputation` (the
#'   \eqn{(1 + 1/m) B} term), and `m`.
#' @export
pool_pv <- function(estimates, variances) {
  estimates <- as.numeric(estimates)
  variances <- as.numeric(variances)
  if (length(estimates) != length(variances)) {
    stop("`estimates` and `variances` must have the same length.", call. = FALSE)
  }
  m <- length(estimates)
  est <- mean(estimates)
  u_bar <- mean(variances)
  b <- if (m > 1L) stats::var(estimates) else 0
  var_imp <- (1 + 1 / m) * b
  total <- u_bar + var_imp
  se <- sqrt(total)
  t_stat <- if (se > 0) est / se else NA_real_
  p <- if (is.na(t_stat)) NA_real_ else 2 * stats::pnorm(-abs(t_stat))
  list(
    estimate = est, se = se, t = t_stat, p = p,
    var_sampling = u_bar, var_imputation = var_imp, m = m
  )
}
