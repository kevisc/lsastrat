#' Inequality of educational opportunity (Ferreira-Gignoux)
#'
#' Computes the Ferreira-Gignoux (2014) measure of inequality of educational
#' opportunity (IOp): the share of achievement inequality attributable to
#' pre-determined *circumstances* (family background, gender, migration status,
#' and similar variables that lie outside the student's control). It is the
#' \eqn{R^2} of a regression of achievement on the circumstance vector, using
#' the **variance** as the inequality index.
#'
#' Following Ferreira & Gignoux, the variance is the inequality measure of
#' choice because, unlike the Gini coefficient or the mean log deviation, it is
#' ordinally invariant under the affine standardisation that assessment scores
#' undergo (a score scale of mean 500, SD 100 is an arbitrary normalisation).
#' The relative IOp is then
#' \deqn{IOp = \frac{\mathrm{Var}(\hat y)}{\mathrm{Var}(y)} = R^2,}
#' the ratio of the variance of the circumstance-predicted ("smoothed")
#' achievement to total achievement variance. The absolute IOp is
#' \eqn{\mathrm{Var}(\hat y)} in squared score points.
#'
#' Achievement is supplied as plausible values and pooled with Rubin's rules;
#' standard errors are design-based when replicate weights are given (see
#' [pool_pv()] and [rep_factor()]).
#'
#' @param data A data frame of student-level records.
#' @param achievement Character vector of achievement plausible-value columns.
#' @param circumstances Character vector of circumstance columns (the vector
#'   \eqn{C}). Character columns are treated as categorical (entered as
#'   dummies); numeric columns enter linearly. For the canonical PISA
#'   application this is the ten variables of Ferreira & Gignoux (2014):
#'   gender, father's and mother's education, father's occupation, language at
#'   home, migration status, books at home, and household durables/cultural
#'   possessions.
#' @param weight Name of the final student weight column. If `NULL`, equal
#'   weights are used (with a message).
#' @param repweights Optional character vector of replicate-weight columns.
#'   When supplied, standard errors are design-based; otherwise only the
#'   point estimate (plus the between-PV component) is returned, with a
#'   warning.
#' @param rep_method,fay Replication design and Fay factor; see [rep_factor()].
#' @param statistics Which quantities to return: `"iop"` (relative IOp = R^2,
#'   the headline), `"explained_var"` (absolute IOp, Var of predicted scores)
#'   and `"total_var"` (total achievement variance).
#'
#' @return An object of class `"ieop"`: a list with a `coefficients` data frame
#'   (one row per statistic; columns `estimate`, `se`, `t`, `p`) plus metadata.
#'
#' @references
#' Ferreira, F. H. G. & Gignoux, J. (2014). The measurement of educational
#' inequality: Achievement and opportunity. *World Bank Economic Review*,
#' 28(2), 210-246.
#'
#' @examples
#' set.seed(1)
#' n <- 2000
#' books <- factor(sample(c("few", "some", "many"), n, replace = TRUE))
#' pared <- rnorm(n)                       # parental education (standardised)
#' # achievement driven partly by circumstances, partly by other factors
#' base <- 500 + 25 * pared + 20 * (books == "many") - 15 * (books == "few")
#' pv <- replicate(5, base + rnorm(n, sd = 70))
#' colnames(pv) <- paste0("PV", 1:5, "MATH")
#' d <- data.frame(books, pared, pv, w = runif(n, 0.5, 2))
#' ieop(d, achievement = paste0("PV", 1:5, "MATH"),
#'      circumstances = c("books", "pared"), weight = "w")
#' @export
ieop <- function(data,
                 achievement,
                 circumstances,
                 weight = NULL,
                 repweights = NULL,
                 rep_method = c("BRR", "JK2", "JK1"),
                 fay = 0.5,
                 statistics = c("iop", "explained_var", "total_var")) {
  rep_method <- match.arg(rep_method)
  statistics <- match.arg(statistics, several.ok = TRUE)
  stopifnot(is.data.frame(data))

  cols <- c(achievement, circumstances, weight, repweights)
  miss <- setdiff(cols, names(data))
  if (length(miss)) {
    stop("Columns not found in `data`: ", paste(miss, collapse = ", "),
         call. = FALSE)
  }
  if (!length(circumstances)) {
    stop("Supply at least one circumstance variable.", call. = FALSE)
  }

  if (is.null(weight)) {
    message("No `weight` supplied; using equal weights.")
    data[[".w_eq"]] <- 1
    weight <- ".w_eq"
  }

  design_based <- !is.null(repweights)
  if (!design_based) {
    warning("No `repweights` supplied: standard errors omit the sampling ",
            "(design) variance. Supply replicate weights for design-based SEs.",
            call. = FALSE)
  } else {
    cfac <- rep_factor(rep_method, n_rep = length(repweights), fay = fay)
  }

  rhs <- paste(circumstances, collapse = " + ")
  m <- length(achievement)
  est_mat <- matrix(NA_real_, length(statistics), m,
                    dimnames = list(statistics, NULL))
  var_mat <- matrix(0, length(statistics), m,
                    dimnames = list(statistics, NULL))

  for (j in seq_len(m)) {
    form <- stats::as.formula(paste(achievement[j], "~", rhs))
    point <- .ieop_fit(form, data, data[[weight]], statistics)
    est_mat[, j] <- point[statistics]

    if (design_based) {
      reps <- vapply(repweights, function(rw) {
        .ieop_fit(form, data, data[[rw]], statistics)[statistics]
      }, numeric(length(statistics)))
      var_mat[, j] <- cfac * rowSums((reps - point[statistics])^2)
    }
  }

  rows <- lapply(statistics, function(s) {
    pl <- pool_pv(est_mat[s, ], var_mat[s, ])
    data.frame(estimate = pl$estimate, se = pl$se, t = pl$t, p = pl$p)
  })
  coefs <- do.call(rbind, rows)
  rownames(coefs) <- statistics

  structure(
    list(
      coefficients = coefs,
      achievement = achievement,
      circumstances = circumstances,
      n_pv = m,
      n_obs = nrow(data),
      design_based = design_based,
      rep_method = if (design_based) rep_method else NA_character_,
      n_rep = if (design_based) length(repweights) else 0L
    ),
    class = "ieop"
  )
}

# One weighted fit: relative IOp (= Var(fitted)/Var(y) = R^2), absolute IOp
# (Var of fitted), and total achievement variance, all population-weighted.
.ieop_fit <- function(form, data, w, statistics) {
  vars <- all.vars(form)
  ok <- is.finite(w) & w > 0 & stats::complete.cases(data[vars])
  d <- data[ok, , drop = FALSE]
  w <- w[ok]
  y <- d[[vars[1]]]

  # bind the formula to this frame so lm() resolves the `w` weights vector
  environment(form) <- environment()
  fit <- stats::lm(form, data = d, weights = w)
  yhat <- stats::fitted(fit)

  v_tot <- .wvar(y, w)
  v_exp <- .wvar(yhat, w)
  iop <- if (v_tot > 0) v_exp / v_tot else NA_real_

  c(iop = iop, explained_var = v_exp, total_var = v_tot)[statistics]
}

# Population (weighted) variance, divided by the sum of weights.
.wvar <- function(x, w) {
  mu <- stats::weighted.mean(x, w)
  sum(w * (x - mu)^2) / sum(w)
}

#' @export
print.ieop <- function(x, digits = 3, ...) {
  cat("Inequality of educational opportunity (Ferreira-Gignoux)\n")
  cat(sprintf("  %d plausible value(s)   |   n = %d   |   %d circumstance(s)\n",
              x$n_pv, x$n_obs, length(x$circumstances)))
  cat(sprintf("  circumstances: %s\n",
              paste(x$circumstances, collapse = ", ")))
  if (x$design_based) {
    cat(sprintf("  Variance: %s, %d replicate weights%s\n", x$rep_method,
                x$n_rep, if (x$n_pv > 1) " (+ PV imputation)" else ""))
  } else {
    cat("  Variance: point estimates only (no replicate weights)\n")
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
  cat("\niop = share of achievement variance explained by circumstances ",
      "(relative IOp = R^2)\n", sep = "")
  invisible(x)
}

#' @export
summary.ieop <- function(object, ...) {
  print(object, ...)
  invisible(object)
}
