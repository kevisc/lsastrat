#' Shapley decomposition of inequality of educational opportunity
#'
#' Attributes the relative inequality of educational opportunity (the
#' circumstance \eqn{R^2} from [ieop()]) to each individual circumstance using
#' Shapley values: each circumstance's contribution is its average marginal
#' increase in \eqn{R^2} over all orderings of the circumstance set. The
#' contributions are additive and **sum to the total relative IOp**, so they
#' answer "how much of the inequality of opportunity is due to migration vs
#' parental education vs books?". Estimates are pooled across plausible values
#' and, when replicate weights are supplied, carry design-based standard
#' errors.
#'
#' Because the Shapley value requires fitting a regression for every subset of
#' circumstances (\eqn{2^k}), the number of circumstances is capped at 8.
#'
#' @inheritParams ieop
#' @param circumstances Character vector of circumstance columns; each entry
#'   (a variable, including all of its dummy levels) is one Shapley "player".
#'
#' @return An object of class `"ieop_decompose"` / `"lsastrat_estimate"` with
#'   one row per circumstance (the Shapley contribution to relative IOp).
#'
#' @references
#' Shorrocks, A. F. (2013). Decomposition procedures for distributional
#' analysis: a unified framework based on the Shapley value. *Journal of
#' Economic Inequality*, 11, 99-126.
#'
#' @examples
#' data(pisa_mini)
#' ieop_decompose(pisa_mini, paste0("PV", 1:10, "MATH"),
#'                circumstances = c("IMMIG", "parental_edu", "books"),
#'                weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
#' @export
ieop_decompose <- function(data,
                           achievement,
                           circumstances,
                           weight = NULL,
                           repweights = NULL,
                           rep_method = c("BRR", "JK2", "JK1"),
                           fay = 0.5,
                           level = 0.95) {
  rep_method <- match.arg(rep_method)
  .assert_data_frame(data)
  .assert_character(achievement, "achievement")
  if (!is.character(circumstances) || length(circumstances) == 0L) {
    stop("Supply at least one circumstance variable.", call. = FALSE)
  }
  k <- length(circumstances)
  if (k > 8L) {
    stop("Shapley decomposition supports at most 8 circumstances (2^k subset ",
         "regressions); got ", k, ".", call. = FALSE)
  }
  .assert_columns(data, c(achievement, circumstances, weight, repweights))

  wfull <- .resolve_weight(data, weight)
  design_based <- !is.null(repweights)
  if (!design_based) {
    warning("No `repweights` supplied: standard errors omit the sampling ",
            "(design) variance.", call. = FALSE)
  } else {
    cfac <- rep_factor(rep_method, n_rep = length(repweights), fay = fay)
    if (k >= 6L) {
      message("ieop_decompose: ", k, " circumstances x ", length(repweights),
              " replicates -- this may take a while.")
    }
  }

  mask <- is.finite(wfull) & wfull > 0 &
    stats::complete.cases(data[circumstances]) &
    stats::complete.cases(data[achievement])
  n_analytic <- sum(mask)
  if (n_analytic < (k + 2L)) {
    stop("Too few complete cases (", n_analytic, ").", call. = FALSE)
  }
  dsub <- data[mask, circumstances, drop = FALSE]
  wf <- wfull[mask]
  ys <- lapply(achievement, function(a) data[[a]][mask])
  rws <- if (design_based) lapply(repweights, function(r) data[[r]][mask]) else NULL

  m <- length(achievement)
  est_mat <- matrix(NA_real_, k, m, dimnames = list(circumstances, NULL))
  var_mat <- matrix(0, k, m, dimnames = list(circumstances, NULL))

  for (j in seq_along(ys)) {
    point <- .shapley_iop(ys[[j]], dsub, circumstances, wf)
    est_mat[, j] <- point
    if (design_based) {
      reps <- vapply(rws, function(w) .shapley_iop(ys[[j]], dsub, circumstances, w),
                     numeric(k))
      var_mat[, j] <- cfac * rowSums((reps - point)^2)
    }
  }

  coefs <- pool_rows(est_mat, var_mat, circumstances, level = level)

  header <- c(
    "Inequality of opportunity: Shapley decomposition",
    sprintf("  %d plausible value(s)  |  n = %d  |  %d circumstance(s)",
            m, n_analytic, k),
    if (design_based)
      sprintf("  Variance: %s, %d replicate weights (+ PV imputation); t reference",
              rep_method, length(repweights))
    else "  Variance: point estimates only (no replicate weights)"
  )

  new_lsastrat_estimate(
    coefs,
    meta = list(
      header = header,
      footnote = "Shapley contributions to relative IOp (R^2); they sum to the total",
      estimator = "ieop_decompose",
      achievement = achievement, circumstances = circumstances,
      n_pv = m, n_obs = nrow(data), n_analytic = n_analytic,
      design_based = design_based,
      rep_method = if (design_based) rep_method else NA_character_,
      n_rep = if (design_based) length(repweights) else 0L,
      fay = if (design_based) fay else NA_real_,
      call = match.call(), version = utils::packageVersion("lsastrat")
    ),
    subclass = "ieop_decompose"
  )
}

# Shapley contributions of each circumstance to the weighted R^2, on an
# already-masked sample. Fits one weighted regression per subset (2^k).
.shapley_iop <- function(y, dsub, circumstances, w) {
  k <- length(circumstances)
  v_tot <- .wvar(y, w)
  bits <- 2^(seq_len(k) - 1L)

  # R^2 for every subset (indexed by bitmask)
  r2 <- numeric(2^k)
  d2 <- dsub
  d2$.y_ <- y
  for (mask in seq_len(2^k - 1L)) {
    vars <- circumstances[bitwAnd(mask, bits) > 0]
    form <- stats::reformulate(vars, response = ".y_")
    environment(form) <- environment()
    fit <- stats::lm(form, data = d2, weights = w)
    r2[mask + 1L] <- if (v_tot > 0) .wvar(stats::fitted(fit), w) / v_tot else NA_real_
  }

  # Shapley weights by subset size, then average marginal contribution
  wsize <- vapply(0:(k - 1L),
                  function(s) factorial(s) * factorial(k - s - 1L) / factorial(k),
                  numeric(1))
  contrib <- numeric(k)
  for (j in seq_len(k)) {
    bitj <- bits[j]
    for (mask in 0:(2^k - 1L)) {
      if (bitwAnd(mask, bitj) == 0L) {
        s <- sum(bitwAnd(mask, bits) > 0)
        contrib[j] <- contrib[j] +
          wsize[s + 1L] * (r2[bitwOr(mask, bitj) + 1L] - r2[mask + 1L])
      }
    }
  }
  stats::setNames(contrib, circumstances)
}
