test_that("the unweighted decomposition matches base-R ANOVA eta-squared", {
  set.seed(1)
  ns <- 80; per <- 30
  sch_eff <- rnorm(ns, 0, sqrt(40))
  y <- rep(sch_eff, each = per) + rnorm(ns * per, 0, sqrt(60))
  d <- data.frame(school = rep(seq_len(ns), each = per),
                  PV1MATH = 500 + y, w = 1)
  vd <- suppressWarnings(
    variance_decomposition(d, "PV1MATH", unit = "school", weight = "w"))
  ss <- summary(aov(PV1MATH ~ factor(school), data = d))[[1]][, "Sum Sq"]
  eta2 <- ss[1] / sum(ss)                            # SS_between / SS_total
  expect_equal(vd$coefficients["icc", "estimate"], unname(eta2), tolerance = 1e-6)
  # and the between-school share is in the right ballpark for ICC ~ 0.4
  expect_gt(vd$coefficients["icc", "estimate"], 0.35)
})

test_that("the decomposition is exact: between + within = total", {
  data(pisa_mini, package = "lsastrat")
  vd <- variance_decomposition(pisa_mini, paste0("PV", 1:10, "MATH"),
                               unit = "school_id", weight = "W_FSTUWT",
                               repweights = paste0("W_FSTURWT", 1:64))
  co <- vd$coefficients
  expect_equal(co["var_between", "estimate"] + co["var_within", "estimate"],
               co["var_total", "estimate"], tolerance = 1e-6)
  expect_gt(co["icc", "estimate"], 0)
  expect_lt(co["icc", "estimate"], 1)
  expect_gt(co["icc", "se"], 0)
})
