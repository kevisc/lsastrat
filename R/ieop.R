#' Inequality of educational opportunity (Ferreira-Gignoux)
#'
#' Computes the Ferreira-Gignoux (2014) measure of inequality of educational
#' opportunity (IOp): the share of achievement inequality attributable to
#' pre-determined *circumstances* (family background, gender, migration status,
#' and similar variables outside the student's control). It is the \eqn{R^2} of
#' a regression of achievement on the circumstance vector, using the
#' **variance** as the inequality index.
#'
#' Following Ferreira & Gignoux, the variance is the inequality measure of
#' choice because, unlike the Gini coefficient or the mean log deviation, it is
#' ordinally invariant under the affine standardisation that assessment scores
#' undergo. The relative IOp is
#' \deqn{IOp = \mathrm{Var}(\hat y) / \mathrm{Var}(y) = R^2,}
#' the ratio of circumstance-predicted ("smoothed") achievement variance to
#' total achievement variance. The absolute IOp is \eqn{\mathrm{Var}(\hat y)}
#' in squared score points.
#'
#' @section Overfitting and the adjusted measure:
#' The raw \eqn{R^2} is an **upper bound**: it is mechanically inflated when the
#' circumstance vector expands into many dummy columns (Ferreira & Gignoux,
#' 2014). `ieop()` therefore also reports `iop_adj`, a degrees-of-freedom
#' adjusted relative IOp,
#' \deqn{1 - (1 - R^2)\,\frac{n_\mathrm{eff} - 1}{n_\mathrm{eff} - k},}
#' where \eqn{n_\mathrm{eff}} is Kish's weighted effective sample size and
#' \eqn{k} the number of estimated parameters, and warns when \eqn{k} is large
#' relative to \eqn{n_\mathrm{eff}}. Cross-fitted / sample-split IOp is planned
#' for a future release.
#'
#' Achievement is supplied as plausible values and pooled with Rubin's rules;
#' standard errors are design-based when replicate weights are given.
#'
#' @param data A data frame of student-level records.
#' @param achievement Character vector of achievement plausible-value columns.
#' @param circumstances Character vector of circumstance columns (the vector
#'   \eqn{C}). Character/factor columns are treated as categorical; numeric
#'   columns enter linearly. The canonical PISA application (Ferreira &
#'   Gignoux, 2014) uses gender, parental education and occupation, books and
#'   household possessions, language at home and migration status.
#' @param weight Name of the final student weight column. If `NULL`, equal
#'   weights are used (with a message).
#' @param repweights Optional character vector of replicate-weight columns.
#' @param rep_method,fay Replication design and Fay factor; see [rep_factor()].
#' @param design Optional [lsa_design()] bundling `weight`, `repweights`,
#'   `rep_method` and `fay`; when supplied it overrides those arguments.
#' @param statistics Which quantities to return: `"iop"` (relative IOp = raw
#'   \eqn{R^2}), `"iop_adj"` (df-adjusted relative IOp), `"explained_var"`
#'   (absolute IOp) and `"total_var"` (total achievement variance).
#' @param level Confidence level for the stored interval (default `0.95`).
#'
#' @return An object of class `"ieop"` / `"lsastrat_estimate"` (see
#'   [lsastrat_estimate] for methods).
#'
#' @references
#' Ferreira, F. H. G. & Gignoux, J. (2014). The measurement of educational
#' inequality: Achievement and opportunity. *World Bank Economic Review*,
#' 28(2), 210-246.
#'
#' @examples
#' data(pisa_mini)
#' ieop(pisa_mini,
#'      achievement = paste0("PV", 1:10, "MATH"),
#'      circumstances = c("IMMIG", "parental_edu", "books"),
#'      weight = "W_FSTUWT",
#'      repweights = paste0("W_FSTURWT", 1:64))
#' @export
ieop <- function(data,
                 achievement,
                 circumstances,
                 weight = NULL,
                 repweights = NULL,
                 rep_method = c("BRR", "JK2", "JK1"),
                 fay = 0.5,
                 design = NULL,
                 statistics = c("iop", "iop_adj", "explained_var", "total_var"),
                 level = 0.95) {
  rep_method <- match.arg(rep_method)
  .d <- .apply_design(design, weight, repweights, rep_method, fay)
  weight <- .d$weight; repweights <- .d$repweights
  rep_method <- .d$rep_method; fay <- .d$fay
  statistics <- match.arg(statistics, several.ok = TRUE)
  .assert_data_frame(data)
  .assert_character(achievement, "achievement")
  if (!is.character(circumstances) || length(circumstances) == 0L) {
    stop("Supply at least one circumstance variable.", call. = FALSE)
  }
  .assert_columns(data, c(achievement, circumstances, weight, repweights))

  wfull <- .resolve_weight(data, weight)
  design_based <- !is.null(repweights)
  if (!design_based) {
    warning("No `repweights` supplied: standard errors omit the sampling ",
            "(design) variance. Supply replicate weights for design-based SEs.",
            call. = FALSE)
  } else {
    cfac <- rep_factor(rep_method, n_rep = length(repweights), fay = fay)
  }

  mask <- is.finite(wfull) & wfull > 0 &
    stats::complete.cases(data[circumstances]) &
    stats::complete.cases(data[achievement])
  n_analytic <- sum(mask)
  if (n_analytic < (length(circumstances) + 2L)) {
    stop("Too few complete cases (", n_analytic, ") for the circumstance set.",
         call. = FALSE)
  }
  d <- data[mask, , drop = FALSE]
  wf <- wfull[mask]
  rws <- if (design_based) lapply(repweights, function(r) data[[r]][mask]) else NULL

  # circumstance model matrix is constant across PVs and replicates
  mm <- stats::model.matrix(stats::reformulate(circumstances), d)
  ys <- lapply(achievement, function(a) d[[a]])
  m <- length(achievement)
  est_mat <- matrix(NA_real_, length(statistics), m,
                    dimnames = list(statistics, NULL))
  var_mat <- matrix(0, length(statistics), m,
                    dimnames = list(statistics, NULL))

  warned <- FALSE
  for (j in seq_len(m)) {
    point <- .ieop_fit(ys[[j]], mm, wf, statistics)
    est_mat[, j] <- point[statistics]
    if (!warned) {
      k <- attr(point, "rank") - 1L
      neff <- attr(point, "neff")
      if (k > 0 && k / neff > 0.05) {
        warning(sprintf(paste0("Circumstance model has %d parameters for an ",
                "effective n of %.0f; raw `iop` (R^2) is upward-biased. ",
                "Use `iop_adj`."), k, neff), call. = FALSE)
      }
      warned <- TRUE
    }
    if (design_based) {
      reps <- .rep_apply(rws, function(w)
        .ieop_fit(ys[[j]], mm, w, statistics)[statistics])
      var_mat[, j] <- cfac * rowSums((reps - point[statistics])^2)
    }
  }

  coefs <- pool_rows(est_mat, var_mat, statistics, level = level)

  header <- c(
    "Inequality of educational opportunity (Ferreira-Gignoux)",
    sprintf("  %d plausible value(s)  |  n = %d  |  %d circumstance(s): %s",
            m, n_analytic, length(circumstances),
            paste(circumstances, collapse = ", ")),
    if (design_based)
      sprintf("  Variance: %s, %d replicate weights (+ PV imputation); t reference",
              rep_method, length(repweights))
    else "  Variance: point estimates only (no replicate weights)"
  )

  new_lsastrat_estimate(
    coefs,
    meta = list(
      header = header,
      footnote = paste0("iop = share of achievement variance explained by ",
                        "circumstances (raw R^2, upper bound); iop_adj = ",
                        "df-adjusted"),
      estimator = "ieop",
      achievement = achievement, circumstances = circumstances,
      n_pv = m, n_obs = nrow(data), n_analytic = n_analytic,
      design_based = design_based,
      rep_method = if (design_based) rep_method else NA_character_,
      n_rep = if (design_based) length(repweights) else 0L,
      fay = if (design_based) fay else NA_real_,
      call = match.call(), version = utils::packageVersion("lsastrat")
    ),
    subclass = "ieop"
  )
}

# One weighted fit on a precomputed model matrix: raw relative IOp
# (= Var(fitted) / Var(y) = R^2), the df-adjusted relative IOp, absolute IOp
# (Var of fitted), and total achievement variance. Carries rank and effective
# n as attributes. Uses lm.wfit so the model matrix is built only once.
.ieop_fit <- function(y, mm, w, statistics) {
  fit <- stats::lm.wfit(mm, y, w)
  yhat <- fit$fitted.values

  v_tot <- .wvar(y, w)
  v_exp <- .wvar(yhat, w)
  iop <- if (v_tot > 0) v_exp / v_tot else NA_real_

  neff <- sum(w)^2 / sum(w^2)
  k <- fit$rank
  iop_adj <- if (is.finite(iop) && (neff - k) > 0) {
    1 - (1 - iop) * (neff - 1) / (neff - k)
  } else {
    NA_real_
  }

  out <- c(iop = iop, iop_adj = iop_adj,
           explained_var = v_exp, total_var = v_tot)[statistics]
  attr(out, "rank") <- k
  attr(out, "neff") <- neff
  out
}

# Population (weighted) variance, divided by the sum of weights.
.wvar <- function(x, w) {
  mu <- stats::weighted.mean(x, w)
  sum(w * (x - mu)^2) / sum(w)
}
