test_that("equity_scatter returns a per-group quality/equity table", {
  data(pisa_mini, package = "lsastrat")
  es <- equity_scatter(pisa_mini, by = "IMMIG",
                       achievement = paste0("PV", 1:5, "MATH"),
                       escs = "ESCS", weight = "W_FSTUWT")
  expect_s3_class(es, "equity_scatter")
  expect_equal(nrow(es$data), 3L)
  expect_true(all(c("group", "mean", "slope", "strength") %in% names(es$data)))
  grDevices::pdf(NULL); on.exit(grDevices::dev.off())
  expect_invisible(plot(es))
})

test_that("lsa_design bundles the replication arguments", {
  d <- lsa_design(weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
  expect_s3_class(d, "lsa_design")
  expect_equal(d$rep_method, "BRR")
})

test_that("lsa_multiverse crosses the grid and tracks a term", {
  data(pisa_mini, package = "lsastrat")
  des <- lsa_design(weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
  mv <- lsa_multiverse(
    pisa_mini, estimator = social_gradient,
    grid = list(
      achievement = list(math = paste0("PV", 1:10, "MATH"),
                         read = paste0("PV", 1:10, "READ")),
      curvature = list(linear = FALSE, quadratic = TRUE)
    ),
    fixed = list(escs = "ESCS"), design = des, term = "slope")
  expect_s3_class(mv, "lsa_multiverse")
  expect_equal(mv$n_spec, 4L)                       # 2 x 2 forking paths
  expect_true(all(c("achievement", "curvature", "estimate", "ci_lo", "ci_hi")
                  %in% names(mv$specs)))
  expect_setequal(unique(mv$specs$achievement), c("math", "read"))
  expect_true(mv$share_sig >= 0 && mv$share_sig <= 1)
})

test_that("specification-curve plot returns invisibly", {
  data(pisa_mini, package = "lsastrat")
  mv <- lsa_multiverse(
    pisa_mini, "ieop",
    grid = list(circumstances = list(
      ses = c("IMMIG", "parental_edu"),
      full = c("IMMIG", "parental_edu", "books"))),
    fixed = list(achievement = paste0("PV", 1:5, "MATH"), weight = "W_FSTUWT"),
    term = "iop")
  expect_equal(mv$n_spec, 2L)
  grDevices::pdf(NULL); on.exit(grDevices::dev.off())
  expect_invisible(plot(mv))
})

test_that("the printed sign agreement does not depend on the direction", {
  d <- sim_lsa(n = 600, slope = 30, n_pv = 3, n_rep = 16, seed = 11)
  ach <- paste0("PV", 1:3, "MATH")
  d2 <- d
  d2[ach] <- lapply(d2[ach], function(v) -v)
  des <- lsa_design(weight = "W_FSTUWT", repweights = reps_of(d))
  run <- function(x) lsa_multiverse(
    x, social_gradient,
    grid = list(curvature = list(linear = FALSE, quadratic = TRUE)),
    fixed = list(achievement = ach, escs = "ESCS"), design = des,
    term = "slope")
  pos <- run(d)
  neg <- run(d2)
  expect_equal(pos$share_same_sign, 1)
  expect_equal(neg$share_same_sign, 1)
  expect_equal(neg$share_pos, 0)
  expect_output(print(neg), "100% of specifications share the sign")
})
