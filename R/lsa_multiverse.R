#' Bundle a survey design for reuse
#'
#' A lightweight container for the weighting/replication arguments shared by
#' every estimator, so they need not be repeated on each call. Pass the result
#' as `design =` to any estimator, to [lsa_model()], or to [lsa_multiverse()].
#'
#' @param rep_method Replication design: `"BRR"` (PISA), `"JK2"` (TIMSS,
#'   PIRLS) or `"JK1"`. PIAAC names the method of each country in the variable
#'   `VEMETHOD`.
#'
#' @param weight Name of the final student weight column.
#' @param repweights Optional character vector of replicate-weight columns.
#' @param fay Fay factor for BRR; see [rep_factor()].
#' @return An object of class `"lsa_design"`.
#' @examples
#' lsa_design(weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
#' @export
lsa_design <- function(weight = NULL, repweights = NULL,
                       rep_method = "BRR", fay = 0.5) {
  structure(list(weight = weight, repweights = repweights,
                 rep_method = rep_method, fay = fay),
            class = "lsa_design")
}

#' Plausible-value / weight-aware multiverse (specification-curve) analysis
#'
#' Runs an lsastrat estimator across a grid of analytic specifications -- the
#' "forking paths" of a multiverse analysis -- and collects one tracked
#' quantity from each, so the robustness of a finding to defensible analytic
#' choices can be read off a specification curve. Every specification inherits
#' correct plausible-value pooling and replicate-weight inference from the
#' underlying estimator.
#'
#' @param data A data frame of student-level records.
#' @param estimator The estimator to run: a function (e.g. `social_gradient`)
#'   or its name.
#' @param grid A named list of forking paths. Each name is an **argument** of
#'   `estimator`; each element is a named list of the alternative values for
#'   that argument (the inner names label the choices). All combinations are
#'   crossed.
#' @param fixed A named list of arguments held constant across specifications.
#' @param design Optional [lsa_design()] whose fields are added to `fixed`.
#' @param term Which output term (row of the estimator's coefficients) to
#'   track; defaults to the first term.
#' @param .progress Logical; message each specification as it runs.
#'
#' @return An object of class `"lsa_multiverse"`: a list with `specs` (one row
#'   per specification: a column per forking path plus `estimate`, `ci_lo`,
#'   `ci_hi`) and a summary: the median and range of the estimates, the share
#'   of specifications with a positive estimate (`share_pos`), the share that
#'   has the sign of the median (`share_same_sign`), and the share whose
#'   interval excludes zero (`share_sig`). Plot it with
#'   [plot.lsa_multiverse()].
#'
#' @examples
#' data(pisa_mini)
#' des <- lsa_design(weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
#' mv <- lsa_multiverse(
#'   pisa_mini, estimator = social_gradient,
#'   grid = list(
#'     achievement = list(math = paste0("PV", 1:10, "MATH"),
#'                        read = paste0("PV", 1:10, "READ")),
#'     curvature = list(linear = FALSE, quadratic = TRUE)
#'   ),
#'   fixed = list(escs = "ESCS"), design = des, term = "slope")
#' mv
#' @export
lsa_multiverse <- function(data, estimator, grid, fixed = list(),
                           design = NULL, term = NULL, .progress = FALSE) {
  .assert_data_frame(data)
  est_fun <- match.fun(estimator)
  est_name <- if (is.character(estimator)) estimator else
    deparse(substitute(estimator))
  if (!is.list(grid) || is.null(names(grid)) || any(names(grid) == "")) {
    stop("`grid` must be a named list of forking paths.", call. = FALSE)
  }
  if (inherits(design, "lsa_design")) {
    fixed <- utils::modifyList(fixed, Filter(Negate(is.null), unclass(design)))
  }

  keys <- names(grid)
  choices <- lapply(grid, names)
  idx <- expand.grid(lapply(grid, seq_along), KEEP.OUT.ATTRS = FALSE)

  rows <- list()
  failed <- 0L
  for (i in seq_len(nrow(idx))) {
    combo <- stats::setNames(
      lapply(keys, function(k) grid[[k]][[idx[i, k]]]), keys)
    labels <- stats::setNames(
      vapply(keys, function(k) choices[[k]][idx[i, k]], character(1)), keys)
    if (.progress) message("spec ", i, "/", nrow(idx), ": ",
                           paste(keys, labels, sep = "=", collapse = ", "))
    res <- tryCatch(
      suppressWarnings(do.call(est_fun, c(list(data), fixed, combo))),
      error = function(e) NULL)
    if (is.null(res)) { failed <- failed + 1L; next }
    co <- res$coefficients
    tm <- if (is.null(term)) rownames(co)[1] else term
    if (!tm %in% rownames(co)) {
      stop("Term '", tm, "' not produced by the estimator.", call. = FALSE)
    }
    rows[[length(rows) + 1L]] <- data.frame(
      as.list(labels),
      estimate = co[tm, "estimate"], ci_lo = co[tm, "ci_lo"],
      ci_hi = co[tm, "ci_hi"], stringsAsFactors = FALSE)
  }
  if (failed) {
    warning(failed, " specification(s) failed and were dropped.", call. = FALSE)
  }
  if (!length(rows)) stop("Every specification failed.", call. = FALSE)
  specs <- do.call(rbind, rows)
  tracked <- if (is.null(term)) "(first term)" else term

  structure(
    list(specs = specs, keys = keys, term = tracked, estimator = est_name,
         n_spec = nrow(specs),
         median = stats::median(specs$estimate),
         range = range(specs$estimate),
         share_sig = mean(specs$ci_lo > 0 | specs$ci_hi < 0),
         share_pos = mean(specs$estimate > 0),
         share_same_sign = mean(sign(specs$estimate) ==
                                  sign(stats::median(specs$estimate)))),
    class = "lsa_multiverse"
  )
}

#' @export
print.lsa_multiverse <- function(x, ...) {
  cat(sprintf("Multiverse: `%s`, term = %s  (%d specifications)\n",
              x$estimator, x$term, x$n_spec))
  cat(sprintf("  median estimate: %.3g   range: [%.3g, %.3g]\n",
              x$median, x$range[1], x$range[2]))
  cat(sprintf(paste0("  %.0f%% of specifications share the sign of the median; ",
                     "%.0f%% exclude 0 (95%% CI)\n"),
              100 * x$share_same_sign, 100 * x$share_sig))
  invisible(x)
}

#' @export
as.data.frame.lsa_multiverse <- function(x, ...) x$specs

#' Specification-curve plot
#'
#' Draws the canonical two-panel specification curve: the sorted point
#' estimates with confidence intervals on top, and the active analytic choice
#' for each specification below.
#'
#' @param x An `"lsa_multiverse"` object.
#' @param ... Passed to [graphics::plot()] for the top panel.
#' @return `x`, invisibly.
#' @export
plot.lsa_multiverse <- function(x, ...) {
  s <- x$specs[order(x$specs$estimate), , drop = FALSE]
  n <- nrow(s)
  # build the choice rows (one per factor level) for the lower panel
  lvls <- lapply(x$keys, function(k) unique(x$specs[[k]]))
  names(lvls) <- x$keys
  rowlab <- unlist(lapply(x$keys, function(k) paste0(k, ": ", lvls[[k]])))
  nrows <- length(rowlab)

  op <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(op))
  graphics::layout(matrix(1:2, ncol = 1), heights = c(2, max(1.2, nrows * 0.25)))
  graphics::par(mar = c(0.5, 4, 2, 1))
  graphics::plot(seq_len(n), s$estimate, pch = 19, xaxt = "n",
                 xlab = "", ylab = x$term,
                 main = sprintf("Specification curve: %s (%s)",
                                x$estimator, x$term),
                 ylim = range(c(s$ci_lo, s$ci_hi), na.rm = TRUE), ...)
  graphics::segments(seq_len(n), s$ci_lo, seq_len(n), s$ci_hi, col = "grey60")
  graphics::abline(h = 0, lty = 3, col = "firebrick")

  graphics::par(mar = c(3, 4, 0.5, 1))
  graphics::plot(NA, xlim = c(1, n), ylim = c(0.5, nrows + 0.5),
                 xlab = "Specification (sorted)", ylab = "", yaxt = "n")
  graphics::axis(2, at = seq_len(nrows), labels = rev(rowlab), las = 1,
                 cex.axis = 0.7)
  r <- 0
  for (k in x$keys) {
    for (lv in lvls[[k]]) {
      r <- r + 1
      active <- which(s[[k]] == lv)
      graphics::points(active, rep(nrows - r + 1, length(active)),
                       pch = 15, cex = 0.6)
    }
  }
  invisible(x)
}
