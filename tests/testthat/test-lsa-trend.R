two_cycles <- function() {
  data(pisa_mini, package = "lsastrat")
  des <- lsa_design(weight = "W_FSTUWT",
                    repweights = paste0("W_FSTURWT", 1:64))
  math <- paste0("PV", 1:10, "MATH")
  h <- nrow(pisa_mini) %/% 2
  list(
    "2018" = social_gradient(pisa_mini[1:h, ], math, "ESCS", design = des),
    "2022" = social_gradient(pisa_mini[-(1:h), ], math, "ESCS", design = des)
  )
}

test_that("lsa_trend computes the change and adds linking error to its SE", {
  cy <- two_cycles()
  tr <- lsa_trend(cy, term = "slope", link_error = 4)
  expect_s3_class(tr, "lsa_trend")
  co <- tr$coefficients
  expect_equal(nrow(co), 2L)
  expect_true(is.na(co$change[1]) || co$change[1] == 0)   # baseline change is 0
  s1 <- cy[["2018"]]$coefficients["slope", c("estimate", "se")]
  s2 <- cy[["2022"]]$coefficients["slope", c("estimate", "se")]
  expect_equal(co$change[2], s2$estimate - s1$estimate, tolerance = 1e-8)
  expect_equal(co$change_se[2], sqrt(s1$se^2 + s2$se^2 + 16), tolerance = 1e-8)
})

test_that("a larger linking error widens the change SE", {
  cy <- two_cycles()
  se0 <- lsa_trend(cy, term = "slope", link_error = 0)$coefficients$change_se[2]
  se5 <- lsa_trend(cy, term = "slope", link_error = 5)$coefficients$change_se[2]
  expect_gt(se5, se0)
})

test_that("input validation", {
  cy <- two_cycles()
  expect_error(lsa_trend(unname(cy), term = "slope"), "named list")
  expect_error(lsa_trend(cy[1], term = "slope"), "at least two")
  expect_error(lsa_trend(cy, term = "nope"), "not in the cycle")
  expect_error(lsa_trend(cy, term = "slope", link_error = c(1, 2)), "length 1")
})

test_that("plot.lsa_trend returns invisibly", {
  tr <- lsa_trend(two_cycles(), term = "slope", link_error = 3.5)
  grDevices::pdf(NULL); on.exit(grDevices::dev.off())
  expect_invisible(plot(tr))
})
