#' School segregation indices for large-scale assessment data
#'
#' Computes the family of segregation indices used in educational
#' stratification research — measuring how unevenly student groups are
#' distributed across schools (or any nesting unit) — with survey-weighted
#' counts, replicate-weight standard errors, and plausible-value pooling when
#' group membership is defined by an achievement threshold (academic
#' segregation).
#'
#' Two ways to define the group:
#' * **Social segregation:** pass a categorical `group` column (e.g. an
#'   immigrant-background flag, or a disadvantaged/advantaged ESCS split).
#' * **Academic segregation:** pass `achievement` (a vector of plausible-value
#'   columns) together with `cutoff`; students scoring below the cutoff form
#'   the minority group, and the index is pooled across plausible values.
#'
#' @param data A data frame of student-level records.
#' @param unit Name of the school / nesting-unit identifier column.
#' @param group Name of a categorical group-membership column. Mutually
#'   exclusive with `achievement`/`cutoff`.
#' @param achievement Character vector of plausible-value column names, used
#'   with `cutoff` to define an achievement-based (academic) group.
#' @param cutoff Numeric threshold; students with achievement `< cutoff` form
#'   the `"below"` group.
#' @param indices Which indices to return. Any of `"D"` (dissimilarity),
#'   `"S"` (Gorard's segregation index), `"isolation"` (minority isolation),
#'   `"Hutchens"` (square-root index), `"H"` (Theil's information / entropy
#'   index) and `"M"` (mutual information). `H` and `M` support more than two
#'   groups; `D`, `S`, `isolation` and `Hutchens` are computed for the
#'   `minority` group versus the rest.
#' @param minority Which group level is the minority for the binary indices.
#'   Defaults to the least frequent level.
#' @param weight Name of the final student weight column. If `NULL`, equal
#'   weights are used (with a message).
#' @param repweights Optional character vector of replicate-weight columns.
#'   When supplied, standard errors are design-based via [rep_factor()]; when
#'   `NULL`, only point estimates (and, with plausible values, the
#'   between-PV/imputation component) are returned.
#' @param rep_method,fay Replication design and Fay factor; see [rep_factor()].
#'
#' @return An object of class `"segregation"`: a list with a `coefficients`
#'   data frame (one row per index; columns `estimate`, `se`, `t`, `p`) plus
#'   metadata.
#'
#' @references
#' Gorard, S. & Taylor, C. (2002). What is segregation? *Sociology*, 36(4).
#' Hutchens, R. (2004). One measure of segregation. *Int. Economic Review*,
#' 45(2). Mora, R. & Ruiz-Castillo, J. (2011); Elbers, B. (2023), R package
#' \pkg{segregation}.
#'
#' @examples
#' set.seed(1)
#' n <- 3000
#' school <- sample(1:60, n, replace = TRUE)
#' # disadvantaged students clustered into low-numbered schools
#' p_dis <- plogis(-0.05 * school + 1.5)
#' disadv <- rbinom(n, 1, p_dis)
#' d <- data.frame(school, grp = factor(disadv, labels = c("adv", "dis")),
#'                 w = runif(n, 0.5, 2))
#' segregation_index(d, unit = "school", group = "grp", weight = "w")
#' @export
segregation_index <- function(data,
                              unit,
                              group = NULL,
                              achievement = NULL,
                              cutoff = NULL,
                              indices = c("D", "S", "isolation", "Hutchens", "H", "M"),
                              minority = NULL,
                              weight = NULL,
                              repweights = NULL,
                              rep_method = c("BRR", "JK2", "JK1"),
                              fay = 0.5) {
  rep_method <- match.arg(rep_method)
  indices <- match.arg(indices, several.ok = TRUE)
  stopifnot(is.data.frame(data))

  by_pv <- !is.null(achievement)
  if (by_pv == !is.null(group)) {
    stop("Supply exactly one of `group` or `achievement` (+ `cutoff`).",
         call. = FALSE)
  }
  if (by_pv && is.null(cutoff)) {
    stop("`achievement` requires a `cutoff`.", call. = FALSE)
  }

  cols <- c(unit, group, achievement, weight, repweights)
  miss <- setdiff(cols, names(data))
  if (length(miss)) {
    stop("Columns not found in `data`: ", paste(miss, collapse = ", "),
         call. = FALSE)
  }

  if (is.null(weight)) {
    message("No `weight` supplied; using equal weights.")
    w <- rep(1, nrow(data))
  } else {
    w <- data[[weight]]
  }
  unit_vec <- data[[unit]]

  # Build the per-"PV" list of group vectors. For social segregation this is
  # a single fixed grouping; for academic segregation one grouping per PV.
  group_list <- if (by_pv) {
    lapply(achievement, function(a)
      factor(ifelse(data[[a]] < cutoff, "below", "atabove"),
             levels = c("below", "atabove")))
  } else {
    list(as.factor(data[[group]]))
  }
  if (is.null(minority)) {
    minority <- if (by_pv) "below" else .least_frequent(group_list[[1]], w)
  }

  design_based <- !is.null(repweights)
  if (!design_based) {
    warning("No `repweights` supplied: standard errors omit the sampling ",
            "(design) variance. Supply replicate weights for design-based SEs.",
            call. = FALSE)
  } else {
    cfac <- rep_factor(rep_method, n_rep = length(repweights), fay = fay)
  }

  m <- length(group_list)
  est_mat <- matrix(NA_real_, length(indices), m, dimnames = list(indices, NULL))
  var_mat <- matrix(0, length(indices), m, dimnames = list(indices, NULL))

  for (p in seq_len(m)) {
    g <- group_list[[p]]
    point <- .seg_indices(.seg_table(unit_vec, g, w), indices, minority)
    est_mat[, p] <- point[indices]

    if (design_based) {
      reps <- vapply(repweights, function(rw) {
        .seg_indices(.seg_table(unit_vec, g, data[[rw]]), indices, minority)[indices]
      }, numeric(length(indices)))
      var_mat[, p] <- cfac * rowSums((reps - point[indices])^2)
    }
  }

  rows <- lapply(indices, function(ix) {
    pl <- pool_pv(est_mat[ix, ], var_mat[ix, ])
    data.frame(estimate = pl$estimate, se = pl$se, t = pl$t, p = pl$p)
  })
  coefs <- do.call(rbind, rows)
  rownames(coefs) <- indices

  structure(
    list(
      coefficients = coefs,
      unit = unit,
      type = if (by_pv) "academic" else "social",
      minority = minority,
      n_groups = nlevels(group_list[[1]]),
      n_units = length(unique(unit_vec[!is.na(unit_vec)])),
      n_pv = m,
      design_based = design_based,
      rep_method = if (design_based) rep_method else NA_character_,
      n_rep = if (design_based) length(repweights) else 0L
    ),
    class = "segregation"
  )
}

# Weighted units-by-groups count table; empty cells -> 0.
.seg_table <- function(unit, group, w) {
  ok <- is.finite(w) & w > 0 & !is.na(unit) & !is.na(group)
  tab <- tapply(w[ok], list(unit[ok], droplevels(as.factor(group[ok]))), sum)
  tab[is.na(tab)] <- 0
  tab
}

.least_frequent <- function(g, w) {
  tot <- tapply(w, g, sum)
  names(tot)[which.min(tot)]
}

# Index math from a weighted units (rows) x groups (cols) count table.
.seg_indices <- function(tab, indices, minority) {
  out <- stats::setNames(rep(NA_real_, length(indices)), indices)
  N <- sum(tab)
  if (N <= 0) return(out)

  # --- entropy-based, any number of groups ---
  pg <- colSums(tab) / N
  pi_ <- rowSums(tab) / N
  if (any(c("H", "M") %in% indices)) {
    P <- tab / N
    pos <- P > 0
    ratio <- P / outer(pi_, pg)
    M <- sum(P[pos] * log(ratio[pos]))
    E <- -sum(pg[pg > 0] * log(pg[pg > 0]))   # entropy of group distribution
    if ("M" %in% indices) out["M"] <- M
    if ("H" %in% indices) out["H"] <- if (E > 0) M / E else NA_real_
  }

  # --- binary indices: minority group vs the rest ---
  bin <- intersect(indices, c("D", "S", "isolation", "Hutchens"))
  if (length(bin)) {
    if (!minority %in% colnames(tab)) {
      # minority level absent in this (replicate) table: indices undefined
      return(out)
    }
    mi <- tab[, minority]
    ti <- rowSums(tab)
    ni <- ti - mi
    Mtot <- sum(mi); Ntot <- sum(ni); Ttot <- sum(ti)
    if (Mtot > 0 && Ntot > 0) {
      sm <- mi / Mtot          # minority share in unit
      sn <- ni / Ntot          # rest share in unit
      si <- ti / Ttot          # unit share of all students
      pos <- ti > 0
      if ("D" %in% indices)       out["D"] <- 0.5 * sum(abs(sm - sn))
      if ("S" %in% indices)       out["S"] <- 0.5 * sum(abs(sm - si))
      if ("Hutchens" %in% indices) out["Hutchens"] <- 1 - sum(sqrt(sm * sn))
      if ("isolation" %in% indices)
        out["isolation"] <- sum((sm[pos]) * (mi[pos] / ti[pos]))
    }
  }
  out
}

#' @export
print.segregation <- function(x, digits = 3, ...) {
  cat(sprintf("Segregation indices (%s segregation)\n", x$type))
  cat(sprintf("  unit: %s   |   %d units   |   %d group(s)   |   minority: %s\n",
              x$unit, x$n_units, x$n_groups, x$minority))
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
  invisible(x)
}

#' @export
summary.segregation <- function(object, ...) {
  print(object, ...)
  invisible(object)
}
