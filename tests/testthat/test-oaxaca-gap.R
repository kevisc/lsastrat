two_group <- function() {
  data(pisa_mini, package = "lsastrat")
  d <- pisa_mini[pisa_mini$IMMIG %in% c("native", "first_gen"), ]
  d$IMMIG <- factor(d$IMMIG)
  d
}

test_that("twofold components sum to the gap, which equals the mean difference", {
  d <- two_group()
  ox <- suppressWarnings(
    oaxaca_gap(d, "PV1MATH", group = "IMMIG",
               predictors = c("ESCS", "books"), weight = "W_FSTUWT"))
  co <- ox$coefficients
  expect_equal(co["explained", "estimate"] + co["unexplained", "estimate"],
               co["gap", "estimate"], tolerance = 1e-8)
  # gap equals the weighted mean difference (native - first_gen)
  mh <- weighted.mean(d$PV1MATH[d$IMMIG == "native"],
                      d$W_FSTUWT[d$IMMIG == "native"])
  ml <- weighted.mean(d$PV1MATH[d$IMMIG == "first_gen"],
                      d$W_FSTUWT[d$IMMIG == "first_gen"])
  expect_equal(co["gap", "estimate"], mh - ml, tolerance = 1e-8)
})

test_that("threefold components sum to the gap", {
  d <- two_group()
  ox <- suppressWarnings(
    oaxaca_gap(d, "PV1MATH", group = "IMMIG",
               predictors = c("ESCS", "books"), type = "threefold",
               weight = "W_FSTUWT"))
  co <- ox$coefficients
  expect_equal(
    co["endowments", "estimate"] + co["coefficients", "estimate"] +
      co["interaction", "estimate"],
    co["gap", "estimate"], tolerance = 1e-8)
})

test_that("design-based SEs are positive and >2 groups needs `groups`", {
  d <- two_group()
  ox <- oaxaca_gap(d, paste0("PV", 1:5, "MATH"), group = "IMMIG",
                   predictors = c("ESCS", "books"), weight = "W_FSTUWT",
                   repweights = paste0("W_FSTURWT", 1:64))
  expect_true(all(ox$coefficients$se > 0))
  data(pisa_mini, package = "lsastrat")
  expect_error(
    suppressWarnings(oaxaca_gap(pisa_mini, "PV1MATH", group = "IMMIG",
                                predictors = "ESCS", weight = "W_FSTUWT")),
    "exactly two levels"
  )
})
