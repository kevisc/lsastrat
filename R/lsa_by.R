#' Run an estimator across groups (e.g. countries)
#'
#' Applies any lsastrat estimator ([social_gradient()], [segregation_index()],
#' [ieop()], [variance_decomposition()]) separately within each level of a
#' grouping variable and stacks the pooled coefficients into one tidy,
#' comparable table. This is the workhorse for comparative large-scale
#' assessment research: one call returns the gradient (or any other quantity)
#' for every country, with confidence intervals, ready to plot or tabulate.
#'
#' @param data A data frame of student-level records.
#' @param by Name of the grouping column (e.g. a country identifier).
#' @param estimator The estimator to apply: a function such as
#'   `social_gradient`, or its name as a string.
#' @param ... Arguments passed on to `estimator` (everything except `data`).
#' @param .progress Logical; message each group as it is processed.
#'
#' @return An object of class `"lsastrat_by"`: a list with `results` (a data
#'   frame with a `group` column followed by `term` and the pooled coefficient
#'   columns) plus metadata. Groups for which the estimator fails are dropped
#'   with a warning.
#'
#' @seealso [plot.lsastrat_by()] for forest/caterpillar plots.
#' @examples
#' data(pisa_mini)
#' # gradient by immigrant background (any grouping column works)
#' lsa_by(pisa_mini, by = "IMMIG", estimator = social_gradient,
#'        achievement = paste0("PV", 1:10, "MATH"), escs = "ESCS",
#'        weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
#' @export
lsa_by <- function(data, by, estimator, ..., .progress = FALSE) {
  .assert_data_frame(data)
  .assert_columns(data, by)
  est_fun <- match.fun(estimator)
  est_name <- if (is.character(estimator)) estimator else
    deparse(substitute(estimator))

  groups <- split(data, droplevels(as.factor(data[[by]])))
  rows <- list()
  failed <- character(0)
  for (g in names(groups)) {
    if (.progress) message("lsa_by: ", by, " = ", g)
    res <- tryCatch(
      suppressWarnings(est_fun(groups[[g]], ...)),
      error = function(e) {
        failed[[length(failed) + 1L]] <<- paste0(g, " (", conditionMessage(e), ")")
        NULL
      }
    )
    if (!is.null(res)) {
      df <- as.data.frame(res)
      rows[[g]] <- cbind(group = g, df, stringsAsFactors = FALSE)
    }
  }
  if (length(failed)) {
    warning("Estimator failed for ", length(failed), " group(s): ",
            paste(failed, collapse = "; "), call. = FALSE)
  }
  if (!length(rows)) {
    stop("Estimator failed for every group.", call. = FALSE)
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL

  structure(
    list(results = out, by = by, estimator = est_name,
         groups = names(rows), terms = unique(out$term),
         n_groups = length(rows)),
    class = "lsastrat_by"
  )
}

#' @export
print.lsastrat_by <- function(x, digits = 3, ...) {
  cat(sprintf("`%s` by %s  (%d groups)\n\n", x$estimator, x$by, x$n_groups))
  df <- x$results
  num <- vapply(df, is.numeric, logical(1))
  df[num] <- lapply(df[num], round, digits)
  print(df, row.names = FALSE)
  invisible(x)
}

#' @export
as.data.frame.lsastrat_by <- function(x, ...) x$results

#' Forest / caterpillar plot of an estimate across groups
#'
#' Plots the point estimate and confidence interval of one term across the
#' groups produced by [lsa_by()], sorted by estimate. A horizontal axis shows
#' the quantity; each row is a group.
#'
#' @param x An `"lsastrat_by"` object.
#' @param term Which term (row name) to plot; defaults to the first term.
#' @param sort Logical; order groups by estimate (default `TRUE`).
#' @param ... Passed to [graphics::plot()].
#' @return `x`, invisibly.
#' @examples
#' data(pisa_mini)
#' g <- lsa_by(pisa_mini, "IMMIG", social_gradient,
#'             achievement = paste0("PV", 1:10, "MATH"), escs = "ESCS",
#'             weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
#' plot(g, term = "slope")
#' @export
plot.lsastrat_by <- function(x, term = NULL, sort = TRUE, ...) {
  df <- x$results
  if (is.null(term)) term <- df$term[1]
  d <- df[df$term == term, , drop = FALSE]
  if (!nrow(d)) stop("Term '", term, "' not found.", call. = FALSE)
  if (sort) d <- d[order(d$estimate), , drop = FALSE]
  y <- seq_len(nrow(d))
  xr <- range(c(d$ci_lo, d$ci_hi), na.rm = TRUE)
  graphics::plot(d$estimate, y, xlim = xr, yaxt = "n", pch = 19,
                 xlab = term, ylab = "",
                 main = sprintf("%s: %s by %s", x$estimator, term, x$by), ...)
  graphics::axis(2, at = y, labels = d$group, las = 1)
  graphics::segments(d$ci_lo, y, d$ci_hi, y)
  graphics::abline(v = 0, col = "grey70", lty = 3)
  invisible(x)
}
