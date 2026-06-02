# Internal input validators shared by the three estimators, so error
# messages and argument checking are consistent across the package.

.assert_data_frame <- function(data) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
}

.assert_columns <- function(data, cols) {
  cols <- cols[!is.na(cols)]
  miss <- setdiff(cols, names(data))
  if (length(miss)) {
    stop("Columns not found in `data`: ", paste(miss, collapse = ", "),
         call. = FALSE)
  }
}

.assert_character <- function(x, arg) {
  if (!is.character(x) || length(x) == 0L) {
    stop(sprintf("`%s` must be a non-empty character vector of column names.",
                 arg), call. = FALSE)
  }
}

# Resolve the final weight column to a numeric vector, defaulting to equal
# weights (with a message) when `weight` is NULL.
.resolve_weight <- function(data, weight) {
  if (is.null(weight)) {
    message("No `weight` supplied; using equal weights.")
    rep(1, nrow(data))
  } else {
    data[[weight]]
  }
}
