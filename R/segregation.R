#' School segregation indices for large-scale assessment data
#'
#' Computes the family of segregation indices used in educational
#' stratification research -- measuring how unevenly student groups are
#' distributed across schools (or any nesting unit) -- with survey-weighted
#' counts, plausible-value pooling for achievement-based groups, and a choice
#' of variance estimator: replicate weights or a clustered bootstrap with
#' finite-sample bias correction.
#'
#' Two ways to define the group:
#' * **Social segregation:** pass a categorical `group` column (e.g. an
#'   immigrant-background flag, or a disadvantaged/advantaged ESCS split).
#' * **Academic segregation:** pass `achievement` (a vector of plausible-value
#'   columns) together with `cutoff`; students scoring below the cutoff form
#'   the minority group, and the index is pooled across plausible values.
#'
#' @section Variance and bias:
#' The entropy and dissimilarity indices (M, H, D, Gorard's S, Hutchens) are
#' positively biased in finite samples, and large-scale assessments -- with
#' tens of students sampled per school across many schools -- are the
#' worst case. With `variance = "bootstrap"` a two-stage clustered bootstrap is
#' used: stage one resamples whole clusters (the design level, giving a
#' design-correct sampling variance) and stage two resamples students within
#' each drawn cluster (the within-school fluctuation that drives the
#' finite-sample bias). The bootstrap bias estimate is then subtracted when
#' `debias = TRUE` (Elbers, 2023). With `variance = "replicate"` the supplied
#' replicate weights give the sampling variance but no bias correction is
#' applied; the point estimates are then the (upward-biased) plug-in values, so
#' bootstrap variance is recommended when bias is a concern.
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
#'   groups; `D`, `S`, `isolation` and `Hutchens` compare the `minority` group
#'   to the rest.
#' @param minority Which group level is the minority for the binary indices.
#'   Defaults to the least frequent (weighted) level.
#' @param weight Name of the final student weight column. If `NULL`, equal
#'   weights are used (with a message).
#' @param repweights Optional character vector of replicate-weight columns
#'   (used when `variance = "replicate"`).
#' @param rep_method,fay Replication design and Fay factor; see [rep_factor()].
#' @param variance Variance estimator: `"replicate"` (default when
#'   `repweights` are supplied), `"bootstrap"` (default otherwise), or
#'   `"none"` (point estimates only).
#' @param n_boot Number of bootstrap resamples (default 200).
#' @param debias Logical; apply bootstrap bias correction under
#'   `variance = "bootstrap"` (default `TRUE`).
#' @param boot_cluster Name of the column defining the stage-one bootstrap
#'   clusters (the primary sampling units); defaults to `unit`.
#' @param boot_seed Optional integer seed for reproducible bootstrap draws (the
#'   global RNG state is restored on exit).
#' @param level Confidence level for the stored interval (default `0.95`).
#'
#' @return An object of class `"segregation"` / `"lsastrat_estimate"` (see
#'   [lsastrat_estimate] for methods): a `coefficients` data frame (one row per
#'   index) plus metadata.
#'
#' @references
#' Gorard, S. & Taylor, C. (2002). What is segregation? *Sociology*, 36(4).
#' Hutchens, R. (2004). One measure of segregation. *International Economic
#' Review*, 45(2). Mora, R. & Ruiz-Castillo, J. (2011). Entropy-based
#' segregation indices. *Sociological Methodology*, 41(1). Elbers, B. (2023).
#' A method for studying differences in segregation. *Sociological Methods &
#' Research* (R package \pkg{segregation}).
#'
#' @examples
#' data(pisa_mini)
#' # social segregation by immigrant background, bootstrap bias-corrected
#' segregation_index(pisa_mini, unit = "school_id", group = "IMMIG",
#'                   weight = "W_FSTUWT", variance = "bootstrap",
#'                   n_boot = 99, boot_seed = 1)
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
                              fay = 0.5,
                              variance = c("replicate", "bootstrap", "none"),
                              n_boot = 200L,
                              debias = TRUE,
                              boot_cluster = NULL,
                              boot_seed = NULL,
                              level = 0.95) {
  rep_method <- match.arg(rep_method)
  indices <- match.arg(indices, several.ok = TRUE)
  .assert_data_frame(data)

  by_pv <- !is.null(achievement)
  if (by_pv == !is.null(group)) {
    stop("Supply exactly one of `group` or `achievement` (+ `cutoff`).",
         call. = FALSE)
  }
  if (by_pv) {
    .assert_character(achievement, "achievement")
    if (is.null(cutoff) || !is.numeric(cutoff) || length(cutoff) != 1L) {
      stop("`achievement` requires a single numeric `cutoff`.", call. = FALSE)
    }
  }
  if (is.null(boot_cluster)) boot_cluster <- unit
  .assert_columns(data, c(unit, group, achievement, weight, repweights, boot_cluster))

  # Resolve variance estimator (default depends on whether repweights exist).
  variance <- if (missing(variance)) {
    if (!is.null(repweights)) "replicate" else "bootstrap"
  } else {
    match.arg(variance)
  }
  if (variance == "replicate" && is.null(repweights)) {
    stop("variance = \"replicate\" requires `repweights`.", call. = FALSE)
  }
  if (variance == "replicate") {
    cfac <- rep_factor(rep_method, n_rep = length(repweights), fay = fay)
  }

  wfull <- .resolve_weight(data, weight)

  # Analysis-sample mask computed once.
  grp_ok <- if (by_pv) stats::complete.cases(data[achievement]) else !is.na(data[[group]])
  mask <- is.finite(wfull) & wfull > 0 & !is.na(data[[unit]]) & grp_ok
  n_analytic <- sum(mask)
  if (n_analytic < 2L) {
    stop("Too few complete cases (", n_analytic, ").", call. = FALSE)
  }

  unit_v <- data[[unit]][mask]
  wfull <- wfull[mask]
  clusters <- data[[boot_cluster]][mask]
  n_units <- length(unique(unit_v))
  n_clusters <- length(unique(clusters))

  group_list <- if (by_pv) {
    lapply(achievement, function(a)
      factor(ifelse(data[[a]][mask] < cutoff, "below", "atabove"),
             levels = c("below", "atabove")))
  } else {
    list(droplevels(as.factor(data[[group]][mask])))
  }
  if (is.null(minority)) {
    minority <- if (by_pv) "below" else .least_frequent(group_list[[1]], wfull)
  }
  if (nlevels(droplevels(group_list[[1]])) < 2L) {
    warning("Fewer than two groups are present; segregation indices are ",
            "degenerate (NA or 0).", call. = FALSE)
  }

  if (variance == "bootstrap") {
    if (n_clusters < 2L) {
      stop("Bootstrap needs at least 2 clusters; found ", n_clusters, ".",
           call. = FALSE)
    }
    if (n_clusters < 10L) {
      warning("Only ", n_clusters, " bootstrap clusters; SEs will be unstable.",
              call. = FALSE)
    }
    if (!is.null(boot_seed)) {
      if (exists(".Random.seed", envir = .GlobalEnv)) {
        old_seed <- get(".Random.seed", envir = .GlobalEnv)
        on.exit(assign(".Random.seed", old_seed, envir = .GlobalEnv), add = TRUE)
      }
      set.seed(boot_seed)
    }
  }

  m <- length(group_list)
  est_mat <- matrix(NA_real_, length(indices), m, dimnames = list(indices, NULL))
  var_mat <- matrix(0, length(indices), m, dimnames = list(indices, NULL))
  bias_mat <- matrix(NA_real_, length(indices), m, dimnames = list(indices, NULL))

  for (p in seq_len(m)) {
    g <- group_list[[p]]
    tab0 <- .seg_table(unit_v, g, wfull)
    point <- .seg_indices(tab0, indices, minority)

    if (variance == "bootstrap") {
      bs <- .seg_bootstrap(unit_v, g, wfull, clusters, indices, minority,
                           n_boot, debias)
      est_mat[, p] <- bs$est[indices]
      var_mat[, p] <- bs$var[indices]
      bias_mat[, p] <- bs$bias[indices]
    } else {
      est_mat[, p] <- point[indices]
      if (variance == "replicate") {
        reps <- vapply(repweights, function(rw)
          .seg_indices(.seg_table(unit_v, g, data[[rw]][mask]), indices, minority)[indices],
          numeric(length(indices)))
        if (any(!is.finite(reps))) {
          affected <- indices[apply(!is.finite(reps), 1L, any)]
          warning("Index/indices ", paste(affected, collapse = ", "),
                  " undefined in some replicates (group level absent); ",
                  "SE set to NA for those.", call. = FALSE)
        }
        var_mat[, p] <- cfac * rowSums((reps - point[indices])^2)
      }
    }
  }

  coefs <- pool_rows(est_mat, var_mat, indices, level = level)

  var_line <- switch(variance,
    replicate = sprintf("  Variance: %s, %d replicate weights%s; t reference",
                        rep_method, length(repweights),
                        if (m > 1) " (+ PV imputation)" else ""),
    bootstrap = sprintf("  Variance: clustered bootstrap (B=%d, cluster=%s)%s%s",
                        n_boot, boot_cluster,
                        if (debias) ", bias-corrected" else "",
                        if (m > 1) " (+ PV imputation)" else ""),
    none = "  Variance: point estimates only"
  )

  new_lsastrat_estimate(
    coefs,
    meta = list(
      header = c(
        sprintf("Segregation indices (%s segregation)", if (by_pv) "academic" else "social"),
        sprintf("  unit: %s  |  %d units  |  %d group(s)  |  minority: %s",
                unit, n_units, nlevels(group_list[[1]]), minority),
        var_line
      ),
      estimator = "segregation_index",
      unit = unit, type = if (by_pv) "academic" else "social",
      minority = minority, n_groups = nlevels(group_list[[1]]),
      n_units = n_units, n_clusters = n_clusters, n_pv = m, n_analytic = n_analytic,
      variance = variance, n_boot = if (variance == "bootstrap") n_boot else NA_integer_,
      debias = if (variance == "bootstrap") debias else NA,
      bias = if (variance == "bootstrap") rowMeans(bias_mat) else NULL,
      design_based = variance != "none",
      rep_method = if (variance == "replicate") rep_method else NA_character_,
      n_rep = if (variance == "replicate") length(repweights) else 0L,
      fay = if (variance == "replicate") fay else NA_real_,
      plot_data = .seg_plot_data(.seg_table(unit_v, group_list[[1]], wfull), minority),
      call = match.call(), version = utils::packageVersion("lsastrat")
    ),
    subclass = "segregation"
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

  # entropy-based, any number of groups
  pg <- colSums(tab) / N
  pi_ <- rowSums(tab) / N
  if (any(c("H", "M") %in% indices)) {
    P <- tab / N
    pos <- P > 0
    ratio <- P / outer(pi_, pg)
    M <- sum(P[pos] * log(ratio[pos]))
    E <- -sum(pg[pg > 0] * log(pg[pg > 0]))
    if ("M" %in% indices) out["M"] <- M
    if ("H" %in% indices) out["H"] <- if (E > 0) M / E else NA_real_
  }

  # binary indices: minority group vs the rest
  bin <- intersect(indices, c("D", "S", "isolation", "Hutchens"))
  if (length(bin)) {
    if (!minority %in% colnames(tab)) return(out)
    mi <- tab[, minority]
    ti <- rowSums(tab)
    ni <- ti - mi
    Mtot <- sum(mi); Ntot <- sum(ni); Ttot <- sum(ti)
    if (Mtot > 0 && Ntot > 0) {
      sm <- mi / Mtot
      sn <- ni / Ntot
      si <- ti / Ttot
      pos <- ti > 0
      if ("D" %in% indices)        out["D"] <- 0.5 * sum(abs(sm - sn))
      if ("S" %in% indices)        out["S"] <- 0.5 * sum(abs(sm - si))
      if ("Hutchens" %in% indices) out["Hutchens"] <- 1 - sum(sqrt(sm * sn))
      if ("isolation" %in% indices) out["isolation"] <- sum(sm[pos] * (mi[pos] / ti[pos]))
    }
  }
  out
}

# Two-stage clustered bootstrap with Elbers-style bias correction. Stage 1
# resamples whole clusters (the design level -> correct sampling variance);
# stage 2 resamples students within each drawn cluster (-> the within-unit
# cell-count fluctuation that drives, and lets us estimate, the finite-sample
# upward bias of the entropy/dissimilarity indices). Each drawn cluster
# instance keeps its units distinct so duplicate draws are not merged.
.seg_bootstrap <- function(unit, group, w, clusters, indices, minority,
                           n_boot, debias) {
  raw <- .seg_indices(.seg_table(unit, group, w), indices, minority)
  clist <- split(seq_along(clusters), clusters)
  K <- length(clist)
  boot <- matrix(NA_real_, length(indices), n_boot, dimnames = list(indices, NULL))

  for (b in seq_len(n_boot)) {
    pick <- sample.int(K, K, replace = TRUE)
    rows <- vector("list", K)
    ulab <- vector("list", K)
    for (t in seq_len(K)) {
      mem <- clist[[pick[t]]]
      rs <- if (length(mem) > 1L) sample(mem, length(mem), replace = TRUE) else mem
      rows[[t]] <- rs
      ulab[[t]] <- paste0(t, "_", unit[rs])   # keep units distinct per draw
    }
    ridx <- unlist(rows, use.names = FALSE)
    tabb <- .seg_table(unlist(ulab, use.names = FALSE), group[ridx], w[ridx])
    boot[, b] <- .seg_indices(tabb, indices, minority)
  }

  mean_boot <- rowMeans(boot, na.rm = TRUE)
  var_boot <- apply(boot, 1L, stats::var, na.rm = TRUE)
  bias <- mean_boot - raw
  est <- if (debias) raw - bias else raw
  clampset <- intersect(indices, c("M", "H", "D", "S", "Hutchens"))
  est[clampset] <- pmax(est[clampset], 0)
  list(est = est, var = var_boot, raw = raw, bias = bias)
}

# Per-unit minority shares (sorted) for the segregation-profile plot.
.seg_plot_data <- function(tab, minority) {
  ti <- rowSums(tab)
  shares <- if (minority %in% colnames(tab)) sort(tab[, minority] / ti) else NULL
  list(shares = as.numeric(shares),
       overall = if (minority %in% colnames(tab)) sum(tab[, minority]) / sum(tab) else NA_real_)
}

#' Plot a school segregation profile
#'
#' Draws the sorted per-unit minority shares (the segregation profile) with the
#' overall minority share marked. A flat profile at the overall share means no
#' segregation; a steep one means strong segregation. Base graphics only.
#'
#' @param x A `"segregation"` object.
#' @param ... Passed to [graphics::plot()].
#' @return `x`, invisibly.
#' @export
plot.segregation <- function(x, ...) {
  pd <- x$plot_data
  if (is.null(pd$shares)) {
    stop("No minority shares to plot (minority level absent).", call. = FALSE)
  }
  graphics::plot(seq_along(pd$shares), pd$shares, type = "h", col = "grey60",
                 xlab = "Units (sorted by minority share)",
                 ylab = sprintf("Share %s", x$minority),
                 main = "School segregation profile", ...)
  graphics::abline(h = pd$overall, col = "firebrick", lwd = 2, lty = 2)
  graphics::legend("topleft", sprintf("overall share = %.2f", pd$overall),
                   bty = "n", col = "firebrick", lwd = 2, lty = 2)
  invisible(x)
}
