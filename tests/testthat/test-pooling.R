# --- rep_factor --------------------------------------------------------------
test_that("rep_factor matches known designs", {
  expect_equal(rep_factor("BRR", n_rep = 80, fay = 0.5), 1 / 20)
  expect_equal(rep_factor("BRR", n_rep = 80, fay = 0),   1 / 80)
  expect_equal(rep_factor("JK2", n_rep = 75),            1)
  expect_equal(rep_factor("JK1", n_rep = 100),           99 / 100)
})

test_that("rep_factor validates fay and n_rep", {
  expect_error(rep_factor("BRR", n_rep = 80, fay = 1), "fay")
  expect_error(rep_factor("BRR", n_rep = 80, fay = -0.1), "fay")
  expect_error(rep_factor("BRR", n_rep = 0), "n_rep")
})

# --- pool_pv -----------------------------------------------------------------
test_that("a single PV reduces to the sampling variance (normal reference)", {
  p <- pool_pv(estimates = 10, variances = 4)
  expect_equal(p$estimate, 10)
  expect_equal(p$se, 2)
  expect_equal(p$var_imputation, 0)
  expect_identical(p$df, Inf)
})

test_that("pool_pv adds the between-PV (imputation) variance with finite df", {
  p <- pool_pv(estimates = c(8, 10, 12), variances = c(4, 4, 4))
  expect_equal(p$estimate, 10)
  expect_equal(p$var_imputation, (1 + 1 / 3) * 4)        # B = 4
  expect_equal(p$se, sqrt(4 + (1 + 1 / 3) * 4))
  expect_true(is.finite(p$df) && p$df > 0)
})

test_that("non-finite variance yields NA inference, not an error (crash regression)", {
  expect_silent(p <- pool_pv(c(0.62, 0.60), c(NA, 0.001)))
  expect_true(is.na(p$se))
  expect_true(is.na(p$statistic))
  expect_true(is.na(p$p))
})

test_that("t reference is wider than the normal for small m with no sampling variance", {
  # no replicate variance (Ubar = 0): df = m - 1 = 4, qt(.975,4) ~ 2.776 > 1.96
  p <- pool_pv(estimates = c(9, 10, 11, 10, 10), variances = rep(0, 5))
  expect_equal(p$df, 4)
  half_width <- (p$ci_hi - p$ci_lo) / 2
  expect_equal(half_width, stats::qt(0.975, 4) * p$se)
  expect_gt(half_width, stats::qnorm(0.975) * p$se)      # wider than z
})
