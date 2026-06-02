test_that("relative IOp equals the weighted regression R-squared", {
  data(pisa_mini, package = "lsastrat")
  res <- suppressWarnings(
    ieop(pisa_mini, "PV1MATH", c("IMMIG", "parental_edu", "books"), "W_FSTUWT"))
  fit <- lm(PV1MATH ~ IMMIG + parental_edu + books, data = pisa_mini,
            weights = pisa_mini$W_FSTUWT)
  expect_equal(res$coefficients["iop", "estimate"], summary(fit)$r.squared,
               tolerance = 1e-8)
})

test_that("explained variance never exceeds total variance and IOp in [0,1]", {
  data(pisa_mini, package = "lsastrat")
  res <- ieop(pisa_mini, paste0("PV", 1:10, "MATH"),
              c("IMMIG", "parental_edu", "books"), "W_FSTUWT",
              repweights = paste0("W_FSTURWT", 1:64))
  co <- res$coefficients
  expect_gte(co["iop", "estimate"], 0)
  expect_lte(co["iop", "estimate"], 1)
  expect_lte(co["explained_var", "estimate"], co["total_var", "estimate"])
  expect_equal(res$n_pv, 10)
  expect_gt(co["iop", "se"], 0)
})

test_that("adjusted IOp corrects the overfitting bias of raw R-squared", {
  # achievement independent of a high-cardinality circumstance => true IOp = 0
  set.seed(2)
  n <- 2000
  d <- data.frame(PV1MATH = rnorm(n, 500, 80),
                  c = factor(sample(150, n, replace = TRUE)),
                  W_FSTUWT = runif(n, 0.5, 2))
  rw <- replicate(8, d$W_FSTUWT * ifelse(runif(n) < 0.5, 1.5, 0.5))
  colnames(rw) <- paste0("W_FSTR", 1:8)
  d <- cbind(d, rw)
  expect_warning(
    res <- ieop(d, "PV1MATH", "c", "W_FSTUWT", repweights = paste0("W_FSTR", 1:8)),
    "upward-biased"
  )
  co <- res$coefficients
  expect_gt(co["iop", "estimate"], 0.03)                       # raw R^2 inflated
  expect_lt(co["iop_adj", "estimate"], co["iop", "estimate"])  # adjustment shrinks
  expect_lt(co["iop_adj", "estimate"], 0.03)                   # ~ 0 (true value)
})

test_that("unknown columns and empty circumstances raise clear errors", {
  data(pisa_mini, package = "lsastrat")
  expect_error(
    suppressWarnings(ieop(pisa_mini, "PVnope", "IMMIG", "W_FSTUWT")),
    "not found"
  )
  expect_error(
    suppressWarnings(ieop(pisa_mini, "PV1MATH", character(0), "W_FSTUWT")),
    "at least one circumstance"
  )
})
