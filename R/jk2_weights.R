#' Build paired-jackknife (JK2) replicate weights for TIMSS and PIRLS
#'
#' The IEA studies (TIMSS, PIRLS, ICCS, ICILS) do not ship replicate weights.
#' They ship the final weight together with a jackknife zone (`JKZONE`) and a
#' within-zone replicate indicator (`JKREP`, coded 0 or 1). `jk2_weights()`
#' builds one replicate weight per zone from these three columns, so that the
#' data can be passed to any estimator with `rep_method = "JK2"`.
#'
#' For the replicate of zone \eqn{h}, the weight of every student in that zone
#' is multiplied by \eqn{2 \times} `JKREP`: one half of the zone gets twice its
#' weight and the other half gets zero. Students in all other zones keep their
#' weight. With these weights the sampling variance is
#' \eqn{\sum_h (\hat\theta_h - \hat\theta)^2}, which is the `"JK2"` factor of
#' [rep_factor()].
#'
#' This is the construction with one replicate per zone (75 replicates for 75
#' zones). From TIMSS 2015 and PIRLS 2016 on, the IEA reports use two
#' replicates per zone and halve the sum. Both are estimators of the same
#' sampling variance, but they do not give identical numbers, so standard
#' errors from these weights can differ slightly from the published ones for
#' those cycles.
#'
#' @param data A data frame of student-level records.
#' @param weight Name of the final weight column (default `"TOTWGT"`).
#' @param zone Name of the jackknife zone column (default `"JKZONE"`).
#' @param rep Name of the within-zone replicate indicator, coded 0 or 1
#'   (default `"JKREP"`).
#' @param prefix Prefix of the new columns (default `"JKW"`), which are named
#'   `prefix1`, `prefix2`, ... in the order of the sorted zone values.
#'
#' @return `data` with one added replicate-weight column per zone. The names
#'   of the new columns are stored in the attribute `"repweights"`.
#'
#' @references
#' Foy, P. & LaRoche, S. (2020). Estimating standard errors in the TIMSS 2019
#' results. In M. O. Martin, M. von Davier & I. V. S. Mullis (Eds.), *Methods
#' and Procedures: TIMSS 2019 Technical Report*. TIMSS & PIRLS International
#' Study Center.
#'
#' @examples
#' # a toy sample: 4 zones, 2 schools per zone, 3 students per school
#' d <- data.frame(
#'   JKZONE = rep(1:4, each = 6),
#'   JKREP  = rep(rep(0:1, each = 3), times = 4),
#'   TOTWGT = 1,
#'   score  = c(480, 510, 495, 530, 500, 520, 470, 505, 490, 515, 525, 500,
#'              540, 495, 510, 485, 500, 530, 505, 515, 490, 520, 480, 510)
#' )
#' d <- jk2_weights(d)
#' reps <- attr(d, "repweights")
#' lsa_model(d, ~ 1, "score", weight = "TOTWGT", repweights = reps,
#'           rep_method = "JK2")
#' @export
jk2_weights <- function(data, weight = "TOTWGT", zone = "JKZONE",
                        rep = "JKREP", prefix = "JKW") {
  .assert_data_frame(data)
  .assert_columns(data, c(weight, zone, rep))
  w <- data[[weight]]
  z <- data[[zone]]
  r <- data[[rep]]
  if (!is.numeric(w)) stop("`", weight, "` must be numeric.", call. = FALSE)
  r <- suppressWarnings(as.numeric(as.character(r)))

  used <- is.finite(w) & w > 0
  if (anyNA(z[used]) || anyNA(r[used])) {
    stop("`", zone, "` and `", rep, "` must not be missing for rows with a ",
         "positive weight.", call. = FALSE)
  }
  if (!all(r[used] %in% c(0, 1))) {
    stop("`", rep, "` must be coded 0 or 1.", call. = FALSE)
  }
  zones <- sort(unique(z[used]))
  if (length(zones) < 2L) {
    stop("JK2 needs at least two jackknife zones; found ", length(zones), ".",
         call. = FALSE)
  }
  new_names <- paste0(prefix, seq_along(zones))
  clash <- intersect(new_names, names(data))
  if (length(clash)) {
    stop("Columns already exist: ", paste(utils::head(clash, 3), collapse = ", "),
         if (length(clash) > 3) ", ..." else "", ". Choose another `prefix`.",
         call. = FALSE)
  }
  one_half <- vapply(zones, function(h) sum(used & z == h & r == 1) == 0L ||
                       sum(used & z == h & r == 0) == 0L, logical(1))
  if (any(one_half)) {
    warning(sum(one_half), " zone(s) hold only one of the two halves; their ",
            "replicate drops or doubles the whole zone.", call. = FALSE)
  }

  for (i in seq_along(zones)) {
    in_zone <- !is.na(z) & z == zones[i]
    data[[new_names[i]]] <- ifelse(in_zone, w * 2 * r, w)
  }
  attr(data, "repweights") <- new_names
  data
}
