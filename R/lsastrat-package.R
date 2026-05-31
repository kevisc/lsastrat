#' lsastrat: Stratification and Inequality Metrics for Large-Scale Assessments
#'
#' Tools for computing educational stratification and inequality quantities
#' from large-scale assessment (LSA) data (PISA, TIMSS, PIRLS) as first-class
#' outputs, with correct plausible-value pooling and replicate-weight variance
#' estimation.
#'
#' @section Core estimation model:
#' All estimators in lsastrat share one variance scheme. A statistic is
#' computed separately on each plausible value (PV), and for each PV on each
#' set of replicate weights. The replicate weights give the *sampling*
#' variance (design-based); the spread *across* PVs gives the *imputation*
#' (measurement) variance. The two are combined with Rubin's rules. See
#' [pool_pv()].
#'
#' @keywords internal
"_PACKAGE"
