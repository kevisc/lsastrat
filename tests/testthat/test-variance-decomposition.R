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

test_that("JK2 replicates that zero a whole school do not break the fit", {
  # IEA paired-zone design: in replicate z one school of zone z has weight 0
  # and its pair has double weight. Version 0.3.0 failed here with
  # "missing value where TRUE/FALSE needed".
  set.seed(42)
  nz <- 20
  per <- 15
  d <- data.frame(zone = rep(seq_len(nz), each = 2 * per),
                  jkrep = rep(rep(0:1, each = per), nz))
  d$school <- paste(d$zone, d$jkrep)
  d$w <- runif(nrow(d), 5, 15)
  sch <- rnorm(2 * nz, 0, 30)[as.integer(factor(d$school))]
  d$PV1 <- 500 + sch + rnorm(nrow(d), 0, 60)
  d$PV2 <- d$PV1 + rnorm(nrow(d), 0, 15)
  rw <- paste0("JK", seq_len(nz))
  for (z in seq_len(nz)) {
    d[[rw[z]]] <- d$w * ifelse(d$zone == z, ifelse(d$jkrep == 1, 2, 0), 1)
  }
  vd <- variance_decomposition(d, c("PV1", "PV2"), unit = "school",
                               weight = "w", repweights = rw,
                               rep_method = "JK2")
  co <- vd$coefficients
  expect_true(all(is.finite(co[, "estimate"])))
  expect_true(all(is.finite(co[, "se"])))
  expect_gt(co["icc", "se"], 0)

  # The replicate statistic equals the fit on the rows that carry weight.
  keep <- d$JK1 > 0
  expect_equal(
    lsastrat:::.vardecomp_fit(d$PV1, d$school, d$JK1),
    lsastrat:::.vardecomp_fit(d$PV1[keep], d$school[keep], d$JK1[keep])
  )
})
