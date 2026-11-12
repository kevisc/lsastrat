# Internal input validators shared by all estimators, so error
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

# Resolve the weighting/replication arguments from an optional lsa_design().
# When `design` is supplied it provides all four; otherwise the individual
# arguments are returned unchanged.
.apply_design <- function(design, weight, repweights, rep_method, fay) {
  if (is.null(design)) {
    return(list(weight = weight, repweights = repweights,
                rep_method = rep_method, fay = fay))
  }
  if (!inherits(design, "lsa_design")) {
    stop("`design` must be created by lsa_design().", call. = FALSE)
  }
  list(weight = design$weight, repweights = design$repweights,
       rep_method = match.arg(design$rep_method, c("BRR", "JK2", "JK1")),
       fay = design$fay)
}

# Apply FUN (returning a named numeric vector) over the replicate weights,
# optionally in parallel. Set `options(lsastrat.cores = n)` to fork across n
# cores (Unix only; Windows falls back to sequential). The replicate fits are
# deterministic given the weights, so results do not depend on the core count.
# Returns a matrix with one column per replicate (rows = the FUN's names).
.rep_apply <- function(x, FUN) {
  cores <- getOption("lsastrat.cores", 1L)
  res <- if (is.numeric(cores) && cores > 1L && .Platform$OS.type == "unix") {
    parallel::mclapply(x, FUN, mc.cores = as.integer(cores))
  } else {
    lapply(x, FUN)
  }
  do.call(cbind, res)
}
