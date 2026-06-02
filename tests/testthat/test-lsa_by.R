test_that("lsa_by stacks an estimator across groups", {
  data(pisa_mini, package = "lsastrat")
  reps <- paste0("W_FSTURWT", 1:64)
  g <- lsa_by(pisa_mini, by = "IMMIG", estimator = social_gradient,
              achievement = paste0("PV", 1:10, "MATH"), escs = "ESCS",
              weight = "W_FSTUWT", repweights = reps)
  expect_s3_class(g, "lsastrat_by")
  expect_equal(g$n_groups, 3L)
  expect_setequal(unique(g$results$group),
                  c("native", "second_gen", "first_gen"))
  expect_true(all(c("group", "term", "estimate", "ci_lo", "ci_hi") %in%
                  names(g$results)))
  expect_true("slope" %in% g$results$term)
})

test_that("lsa_by works with a string estimator name and other estimators", {
  data(pisa_mini, package = "lsastrat")
  s <- lsa_by(pisa_mini, by = "IMMIG", estimator = "segregation_index",
              unit = "school_id", group = "books", indices = c("D", "M"),
              weight = "W_FSTUWT", variance = "none")
  expect_s3_class(s, "lsastrat_by")
  expect_true(all(c("D", "M") %in% s$results$term))
})

test_that("failing groups are dropped with a warning, not fatal", {
  data(pisa_mini, package = "lsastrat")
  d <- pisa_mini
  # a group with a single school -> segregation bootstrap cannot run there,
  # but 'none' variance is fine; instead force a tiny group to trigger failure
  d$grp <- ifelse(seq_len(nrow(d)) <= 2, "tiny", "rest")
  expect_warning(
    res <- lsa_by(d, by = "grp", estimator = ieop, achievement = "PV1MATH",
                  circumstances = c("IMMIG", "books"), weight = "W_FSTUWT"),
    "failed for"
  )
  expect_true("rest" %in% res$groups)
})

test_that("plot.lsastrat_by returns invisibly", {
  data(pisa_mini, package = "lsastrat")
  g <- lsa_by(pisa_mini, "IMMIG", social_gradient,
              achievement = paste0("PV", 1:5, "MATH"), escs = "ESCS",
              weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  expect_invisible(plot(g, term = "slope"))
})
