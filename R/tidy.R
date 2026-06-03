#' Tidy an lsastrat estimate
#'
#' [generics::tidy()] and [generics::glance()] methods for
#' `"lsastrat_estimate"` objects, returning the broom-style tidy data frame of
#' coefficients and a one-row model summary. This lets lsastrat results flow
#' into the broom/tidyverse ecosystem (tables, plots, `dplyr`).
#'
#' @param x An `"lsastrat_estimate"` object.
#' @param ... Unused.
#' @return `tidy()` a data frame with columns `term`, `estimate`, `std.error`,
#'   `statistic`, `df`, `p.value`, `conf.low`, `conf.high`; `glance()` a
#'   one-row data frame of estimator metadata.
#' @examples
#' data(pisa_mini)
#' g <- social_gradient(pisa_mini, paste0("PV", 1:10, "MATH"), "ESCS",
#'                      "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
#' generics::tidy(g)
#' generics::glance(g)
#' @name tidy.lsastrat_estimate
NULL

#' @rdname tidy.lsastrat_estimate
#' @importFrom generics tidy
#' @export
generics::tidy

#' @rdname tidy.lsastrat_estimate
#' @importFrom generics glance
#' @export
generics::glance

#' @rdname tidy.lsastrat_estimate
#' @exportS3Method generics::tidy
tidy.lsastrat_estimate <- function(x, ...) {
  co <- x$coefficients
  data.frame(
    term = rownames(co),
    estimate = co$estimate,
    std.error = co$se,
    statistic = co$statistic,
    df = co$df,
    p.value = co$p,
    conf.low = co$ci_lo,
    conf.high = co$ci_hi,
    row.names = NULL,
    stringsAsFactors = FALSE
  )
}

#' @rdname tidy.lsastrat_estimate
#' @exportS3Method generics::glance
glance.lsastrat_estimate <- function(x, ...) {
  g1 <- function(v) if (is.null(x[[v]])) NA else x[[v]]
  data.frame(
    estimator = g1("estimator"),
    n_pv = g1("n_pv"),
    nobs = if (!is.null(x$n_analytic)) x$n_analytic else g1("n_obs"),
    design_based = g1("design_based"),
    stringsAsFactors = FALSE
  )
}
