#' Between- and within-school variance decomposition
#'
#' Decomposes the variance of achievement into a **between-unit** (e.g.
#' between-school) and a **within-unit** component, and reports the
#' intraclass correlation `icc` -- the share of achievement variance that lies
#' between schools. This is a foundational stratification quantity: a high
#' between-school share signals a strongly differentiated, segregated system.
#' OECD reports it as "between-school variance as a percentage of total".
#'
#' The decomposition is the design-based (weighted) analysis-of-variance
#' decomposition, `var_total = var_between + var_within`, pooled over plausible
#' values with Rubin's rules and with replicate-weight standard errors when
#' replicate weights are supplied (see [pool_pv()]).
#'
#' @param data A data frame of student-level records.
#' @param achievement Character vector of achievement plausible-value columns.
#' @param unit Name of the school / nesting-unit identifier column.
#' @param weight Name of the final student weight column. If `NULL`, equal
#'   weights are used (with a message).
#' @param repweights Optional character vector of replicate-weight columns.
#' @param rep_method,fay Replication design and Fay factor; see [rep_factor()].
#' @param design Optional [lsa_design()] bundling `weight`, `repweights`,
#'   `rep_method` and `fay`; when supplied it overrides those arguments.
#' @param statistics Which quantities to return: `"icc"` (between-unit share),
#'   `"var_between"`, `"var_within"`, `"var_total"`.
#' @param level Confidence level for the stored interval (default `0.95`).
#'
#' @return An object of class `"variance_decomposition"` /
#'   `"lsastrat_estimate"` (see [lsastrat_estimate] for methods).
#'
#' @examples
#' data(pisa_mini)
#' variance_decomposition(pisa_mini, paste0("PV", 1:10, "MATH"),
#'                        unit = "school_id", weight = "W_FSTUWT",
#'                        repweights = paste0("W_FSTURWT", 1:64))
#' @export
variance_decomposition <- function(data,
                                   achievement,
                                   unit,
                                   weight = NULL,
                                   repweights = NULL,
                                   rep_method = c("BRR", "JK2", "JK1"),
                                   fay = 0.5,
                                   design = NULL,
                                   statistics = c("icc", "var_between",
                                                  "var_within", "var_total"),
                                   level = 0.95) {
  rep_method <- match.arg(rep_method)
  .d <- .apply_design(design, weight, repweights, rep_method, fay)
  weight <- .d$weight; repweights <- .d$repweights
  rep_method <- .d$rep_method; fay <- .d$fay
  statistics <- match.arg(statistics, several.ok = TRUE)
  .assert_data_frame(data)
  .assert_character(achievement, "achievement")
  .assert_columns(data, c(achievement, unit, weight, repweights))

  wfull <- .resolve_weight(data, weight)
  design_based <- !is.null(repweights)
  if (!design_based) {
    warning("No `repweights` supplied: standard errors omit the sampling ",
            "(design) variance.", call. = FALSE)
  } else {
    cfac <- rep_factor(rep_method, n_rep = length(repweights), fay = fay)
  }

  mask <- is.finite(wfull) & wfull > 0 & !is.na(data[[unit]]) &
    stats::complete.cases(data[achievement])
  n_analytic <- sum(mask)
  if (n_analytic < 2L) {
    stop("Too few complete cases (", n_analytic, ").", call. = FALSE)
  }
  unit_v <- as.character(data[[unit]][mask])
  wf <- wfull[mask]
  ys <- lapply(achievement, function(a) data[[a]][mask])
  rws <- if (design_based) lapply(repweights, function(r) data[[r]][mask]) else NULL
  n_units <- length(unique(unit_v))

  m <- length(achievement)
  est_mat <- matrix(NA_real_, length(statistics), m,
                    dimnames = list(statistics, NULL))
  var_mat <- matrix(0, length(statistics), m,
                    dimnames = list(statistics, NULL))

  for (j in seq_along(ys)) {
    point <- .vardecomp_fit(ys[[j]], unit_v, wf)
    est_mat[, j] <- point[statistics]
    if (design_based) {
      reps <- .rep_apply(rws, function(w)
        .vardecomp_fit(ys[[j]], unit_v, w)[statistics])
      var_mat[, j] <- cfac * rowSums((reps - point[statistics])^2)
    }
  }

  coefs <- pool_rows(est_mat, var_mat, statistics, level = level)

  header <- c(
    "Between/within-unit variance decomposition",
    sprintf("  unit: %s  |  %d units  |  %d plausible value(s)  |  n = %d",
            unit, n_units, m, n_analytic),
    if (design_based)
      sprintf("  Variance: %s, %d replicate weights (+ PV imputation); t reference",
              rep_method, length(repweights))
    else "  Variance: point estimates only (no replicate weights)"
  )

  new_lsastrat_estimate(
    coefs,
    meta = list(
      header = header,
      footnote = "icc = between-unit share of achievement variance",
      estimator = "variance_decomposition",
      unit = unit, achievement = achievement, n_pv = m,
      n_units = n_units, n_obs = nrow(data), n_analytic = n_analytic,
      design_based = design_based,
      rep_method = if (design_based) rep_method else NA_character_,
      n_rep = if (design_based) length(repweights) else 0L,
      fay = if (design_based) fay else NA_real_,
      call = match.call(), version = utils::packageVersion("lsastrat")
    ),
    subclass = "variance_decomposition"
  )
}

# Weighted ANOVA decomposition on an already-masked sample.
.vardecomp_fit <- function(y, unit, w) {
  gm <- stats::weighted.mean(y, w)
  W <- sum(w)
  uw <- tapply(w, unit, sum)
  um <- tapply(w * y, unit, sum) / uw
  v_between <- sum(uw * (um - gm)^2) / W
  v_within <- sum(w * (y - um[unit])^2) / W
  v_total <- v_between + v_within
  c(icc = if (v_total > 0) v_between / v_total else NA_real_,
    var_between = v_between, var_within = v_within, var_total = v_total)
}
