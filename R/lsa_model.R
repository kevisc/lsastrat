#' Fit any model to plausible-value outcomes with replicate-weight inference
#'
#' A general estimation engine: fit an arbitrary model (linear, generalised
#' linear, multilevel, ...) to a plausible-value outcome on each plausible
#' value and each replicate weight, and pool the coefficients with Rubin's
#' rules and replicate-weight variance. This lifts the package beyond the
#' built-in estimators -- and beyond the OLS-only support of `intsvy` and
#' similar -- to *any* model whose fitter accepts `formula`, `data` and
#' `weights`.
#'
#' @param data A data frame of student-level records.
#' @param formula A one-sided formula of the predictor/structure, e.g.
#'   `~ ESCS + IMMIG` or, for a multilevel model, `~ ESCS + (1 | school_id)`.
#'   The outcome is filled in from `achievement` for each plausible value.
#' @param achievement Character vector of achievement plausible-value columns
#'   (the outcome set). A single column is allowed.
#' @param fitter The model-fitting function (default [stats::lm]); e.g.
#'   `stats::glm`, `lme4::lmer`. Must accept `formula`, `data` and `weights`.
#' @param coefs A function extracting a **named numeric vector** of the
#'   parameters to pool from a fitted model (default [stats::coef]; use
#'   `lme4::fixef` for `lme4::lmer`).
#' @param weight,repweights,rep_method,fay,design Weighting/replication
#'   specification, exactly as in the other estimators (see [social_gradient()]
#'   and [lsa_design()]).
#' @param level Confidence level for the stored interval (default `0.95`).
#' @param ... Further arguments passed to `fitter` (e.g. `family = binomial()`
#'   for a logistic model).
#'
#' @return An object of class `"lsa_model"` / `"lsastrat_estimate"` with one
#'   row per model coefficient (see [lsastrat_estimate] for methods).
#'
#' @details
#' Standard errors are design-based: each coefficient's sampling variance comes
#' from refitting on the replicate weights, and the spread across plausible
#' values adds the imputation component (Rubin's rules). With multilevel
#' fitters this means many model fits (replicates x plausible values); use a
#' modest number of replicates while prototyping. For weighted logistic models
#' prefer `family = quasibinomial()` over `binomial()` to avoid the
#' "non-integer #successes" warning that survey weights trigger.
#'
#' @examples
#' data(pisa_mini)
#' des <- lsa_design(weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
#' # a multiple regression on a PV outcome
#' lsa_model(pisa_mini, ~ ESCS + IMMIG, achievement = paste0("PV", 1:10, "MATH"),
#'           design = des)
#' @export
lsa_model <- function(data,
                      formula,
                      achievement,
                      fitter = stats::lm,
                      coefs = stats::coef,
                      weight = NULL,
                      repweights = NULL,
                      rep_method = c("BRR", "JK2", "JK1"),
                      fay = 0.5,
                      design = NULL,
                      level = 0.95,
                      ...) {
  rep_method <- match.arg(rep_method)
  .d <- .apply_design(design, weight, repweights, rep_method, fay)
  weight <- .d$weight; repweights <- .d$repweights
  rep_method <- .d$rep_method; fay <- .d$fay
  .assert_data_frame(data)
  .assert_character(achievement, "achievement")
  if (!inherits(formula, "formula") || length(formula) != 2L) {
    stop("`formula` must be a one-sided formula, e.g. ~ ESCS + IMMIG.",
         call. = FALSE)
  }
  fitter_name <- deparse(substitute(fitter))
  rhs <- paste(deparse(formula[[2L]]), collapse = " ")
  extra <- list(...)

  .assert_columns(data, c(achievement, weight, repweights))
  wfull <- .resolve_weight(data, weight)
  design_based <- !is.null(repweights)
  if (!design_based) {
    warning("No `repweights` supplied: standard errors omit the sampling ",
            "(design) variance.", call. = FALSE)
  } else {
    cfac <- rep_factor(rep_method, n_rep = length(repweights), fay = fay)
  }

  model_vars <- unique(c(all.vars(formula), achievement))
  .assert_columns(data, model_vars)
  mask <- is.finite(wfull) & wfull > 0 & stats::complete.cases(data[model_vars])
  n_analytic <- sum(mask)
  if (n_analytic < 3L) stop("Too few complete cases (", n_analytic, ").",
                            call. = FALSE)
  d <- data[mask, , drop = FALSE]
  wf <- wfull[mask]
  rws <- if (design_based) lapply(repweights, function(r) data[[r]][mask]) else NULL

  m <- length(achievement)
  forms <- lapply(achievement, function(a) stats::as.formula(paste(a, "~", rhs)))

  # canonical coefficient names from the first PV's point fit
  point1 <- .lsa_model_fit(forms[[1]], d, wf, fitter, coefs, extra)
  terms <- names(point1)
  if (is.null(terms)) {
    stop("`coefs` must return a *named* numeric vector.", call. = FALSE)
  }
  est_mat <- matrix(NA_real_, length(terms), m, dimnames = list(terms, NULL))
  var_mat <- matrix(0, length(terms), m, dimnames = list(terms, NULL))

  for (j in seq_len(m)) {
    pt <- if (j == 1L) point1 else .lsa_model_fit(forms[[j]], d, wf, fitter, coefs, extra)
    est_mat[, j] <- pt[terms]
    if (design_based) {
      reps <- vapply(rws, function(w)
        .lsa_model_fit(forms[[j]], d, w, fitter, coefs, extra)[terms],
        numeric(length(terms)))
      var_mat[, j] <- cfac * rowSums((reps - pt[terms])^2)
    }
  }

  coefs_df <- pool_rows(est_mat, var_mat, terms, level = level)

  header <- c(
    sprintf("Model: %s(%s ~ %s)", fitter_name, "<PV>", rhs),
    sprintf("  %d plausible value(s)  |  n = %d", m, n_analytic),
    if (design_based)
      sprintf("  Variance: %s, %d replicate weights (+ PV imputation); t reference",
              rep_method, length(repweights))
    else "  Variance: point estimates only (no replicate weights)"
  )

  new_lsastrat_estimate(
    coefs_df,
    meta = list(
      header = header, footnote = sprintf("fitter = %s", fitter_name),
      estimator = "lsa_model", fitter = fitter_name, formula = rhs,
      achievement = achievement, n_pv = m, n_obs = nrow(data),
      n_analytic = n_analytic, design_based = design_based,
      rep_method = if (design_based) rep_method else NA_character_,
      n_rep = if (design_based) length(repweights) else 0L,
      fay = if (design_based) fay else NA_real_,
      call = match.call(), version = utils::packageVersion("lsastrat")
    ),
    subclass = "lsa_model"
  )
}

# Fit one model and return the named coefficient vector. The weights vector is
# passed by value via do.call, so no formula-environment gymnastics are needed.
.lsa_model_fit <- function(form, data, w, fitter, coefs, extra) {
  fit <- do.call(fitter, c(list(form, data = data, weights = w), extra))
  coefs(fit)
}
