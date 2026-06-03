#' Oaxaca-Blinder decomposition of an achievement gap
#'
#' Decomposes the mean achievement gap between two groups (for example native
#' vs immigrant-background students) into a part **explained** by differences
#' in characteristics (endowments/composition) and an **unexplained** part due
#' to differences in returns (structure). This is the standard stratification
#' tool for asking "how much of the gap is because the groups differ in their
#' resources, and how much remains after accounting for them?".
#'
#' The `"twofold"` form uses a pooled reference model (Neumark) and reports
#' `gap`, `explained` and `unexplained`. The `"threefold"` form reports
#' `gap`, `endowments`, `coefficients` and `interaction`. Estimates are pooled
#' over plausible values with replicate-weight standard errors (see
#' [pool_pv()]).
#'
#' @param data A data frame of student-level records.
#' @param achievement Character vector of achievement plausible-value columns.
#' @param group Name of the two-group column.
#' @param predictors Character vector of explanatory variables.
#' @param groups Optional length-2 character vector `c(high, low)`; the gap is
#'   `mean(high) - mean(low)`. Defaults to the two levels present (the more
#'   advantaged, by mean achievement, is taken as `high`).
#' @param weight Name of the final student weight column. If `NULL`, equal
#'   weights are used (with a message).
#' @param repweights Optional character vector of replicate-weight columns.
#' @param rep_method,fay Replication design and Fay factor; see [rep_factor()].
#' @param design Optional [lsa_design()] bundling `weight`, `repweights`,
#'   `rep_method` and `fay`; when supplied it overrides those arguments.
#' @param type `"twofold"` (default) or `"threefold"`.
#' @param level Confidence level for the stored interval (default `0.95`).
#'
#' @return An object of class `"oaxaca_gap"` / `"lsastrat_estimate"`.
#'
#' @references
#' Oaxaca, R. (1973). Male-female wage differentials in urban labor markets.
#' *International Economic Review*, 14(3), 693-709. Blinder, A. S. (1973).
#' Wage discrimination: reduced form and structural estimates. *Journal of
#' Human Resources*, 8(4), 436-455.
#'
#' @examples
#' data(pisa_mini)
#' # native vs first-generation immigrant gap, explained by ESCS, books, parental ed
#' d <- pisa_mini[pisa_mini$IMMIG %in% c("native", "first_gen"), ]
#' d$IMMIG <- factor(d$IMMIG)
#' oaxaca_gap(d, paste0("PV", 1:10, "MATH"), group = "IMMIG",
#'            predictors = c("ESCS", "books", "parental_edu"),
#'            weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
#' @export
oaxaca_gap <- function(data,
                       achievement,
                       group,
                       predictors,
                       groups = NULL,
                       weight = NULL,
                       repweights = NULL,
                       rep_method = c("BRR", "JK2", "JK1"),
                       fay = 0.5,
                       design = NULL,
                       type = c("twofold", "threefold"),
                       level = 0.95) {
  rep_method <- match.arg(rep_method)
  type <- match.arg(type)
  .d <- .apply_design(design, weight, repweights, rep_method, fay)
  weight <- .d$weight; repweights <- .d$repweights
  rep_method <- .d$rep_method; fay <- .d$fay
  .assert_data_frame(data)
  .assert_character(achievement, "achievement")
  .assert_character(predictors, "predictors")
  .assert_columns(data, c(achievement, group, predictors, weight, repweights))

  wfull <- .resolve_weight(data, weight)
  design_based <- !is.null(repweights)
  if (!design_based) {
    warning("No `repweights` supplied: standard errors omit the sampling ",
            "(design) variance.", call. = FALSE)
  } else {
    cfac <- rep_factor(rep_method, n_rep = length(repweights), fay = fay)
  }

  gv0 <- as.character(data[[group]])
  mask <- is.finite(wfull) & wfull > 0 & !is.na(gv0) &
    stats::complete.cases(data[predictors]) &
    stats::complete.cases(data[achievement])

  # resolve the two groups
  present <- unique(gv0[mask])
  if (is.null(groups)) {
    if (length(present) != 2L) {
      stop("`group` must have exactly two levels, or pass `groups=c(high, low)`.",
           call. = FALSE)
    }
    mean_by <- vapply(present, function(g)
      stats::weighted.mean(data[[achievement[1]]][mask & gv0 == g],
                           wfull[mask & gv0 == g]), numeric(1))
    groups <- present[order(mean_by, decreasing = TRUE)]
  }
  if (length(groups) != 2L || !all(groups %in% present)) {
    stop("`groups` must name two levels present in `", group, "`.", call. = FALSE)
  }
  mask <- mask & gv0 %in% groups
  n_analytic <- sum(mask)

  gvec <- gv0[mask]
  wf <- wfull[mask]
  dsub <- data[mask, predictors, drop = FALSE]
  mm <- stats::model.matrix(stats::reformulate(predictors), dsub)
  ys <- lapply(achievement, function(a) data[[a]][mask])
  rws <- if (design_based) lapply(repweights, function(r) data[[r]][mask]) else NULL

  params <- if (type == "twofold") c("gap", "explained", "unexplained")
            else c("gap", "endowments", "coefficients", "interaction")
  m <- length(achievement)
  est_mat <- matrix(NA_real_, length(params), m, dimnames = list(params, NULL))
  var_mat <- matrix(0, length(params), m, dimnames = list(params, NULL))

  for (j in seq_along(ys)) {
    point <- .oaxaca_fit(ys[[j]], gvec, mm, wf, groups[1], groups[2], type)
    est_mat[, j] <- point[params]
    if (design_based) {
      reps <- vapply(rws, function(w)
        .oaxaca_fit(ys[[j]], gvec, mm, w, groups[1], groups[2], type)[params],
        numeric(length(params)))
      var_mat[, j] <- cfac * rowSums((reps - point[params])^2)
    }
  }

  coefs <- pool_rows(est_mat, var_mat, params, level = level)

  header <- c(
    sprintf("Oaxaca-Blinder gap decomposition (%s)", type),
    sprintf("  %s: %s - %s  |  %d plausible value(s)  |  n = %d",
            group, groups[1], groups[2], m, n_analytic),
    if (design_based)
      sprintf("  Variance: %s, %d replicate weights (+ PV imputation); t reference",
              rep_method, length(repweights))
    else "  Variance: point estimates only (no replicate weights)"
  )

  new_lsastrat_estimate(
    coefs,
    meta = list(
      header = header,
      footnote = sprintf("gap = mean(%s) - mean(%s); components sum to gap",
                         groups[1], groups[2]),
      estimator = "oaxaca_gap",
      group = group, groups = groups, predictors = predictors, type = type,
      achievement = achievement, n_pv = m, n_obs = nrow(data),
      n_analytic = n_analytic, design_based = design_based,
      rep_method = if (design_based) rep_method else NA_character_,
      n_rep = if (design_based) length(repweights) else 0L,
      fay = if (design_based) fay else NA_real_,
      call = match.call(), version = utils::packageVersion("lsastrat")
    ),
    subclass = "oaxaca_gap"
  )
}

# Oaxaca-Blinder components on an already-masked sample, using an aligned
# model matrix `mm` so group-specific fits share columns.
.oaxaca_fit <- function(y, g, mm, w, A, B, type) {
  iA <- g == A
  iB <- g == B
  beta <- function(idx) {
    f <- stats::lm.wfit(mm[idx, , drop = FALSE], y[idx], w[idx])
    b <- f$coefficients
    b[is.na(b)] <- 0
    b
  }
  xbar <- function(idx) colSums(mm[idx, , drop = FALSE] * w[idx]) / sum(w[idx])
  bA <- beta(iA); bB <- beta(iB)
  xA <- xbar(iA); xB <- xbar(iB)
  gap <- sum(xA * bA) - sum(xB * bB)
  dX <- xA - xB
  dB <- bA - bB
  if (type == "twofold") {
    bstar <- beta(iA | iB)
    explained <- sum(dX * bstar)
    c(gap = gap, explained = explained, unexplained = gap - explained)
  } else {
    c(gap = gap, endowments = sum(dX * bB),
      coefficients = sum(xB * dB), interaction = sum(dX * dB))
  }
}
