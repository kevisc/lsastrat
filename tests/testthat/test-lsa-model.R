test_that("lsa_model with lm reproduces social_gradient's slope", {
  data(pisa_mini, package = "lsastrat")
  des <- lsa_design(weight = "W_FSTUWT",
                    repweights = paste0("W_FSTURWT", 1:64))
  math <- paste0("PV", 1:10, "MATH")

  g <- social_gradient(pisa_mini, math, "ESCS", design = des, curvature = FALSE)
  m <- lsa_model(pisa_mini, ~ ESCS, achievement = math, design = des)

  expect_s3_class(m, "lsa_model")
  expect_equal(m$coefficients["ESCS", "estimate"],
               g$coefficients["slope", "estimate"], tolerance = 1e-8)
  expect_equal(m$coefficients["ESCS", "se"],
               g$coefficients["slope", "se"], tolerance = 1e-8)
})

test_that("lsa_model fits a multiple regression with several terms", {
  data(pisa_mini, package = "lsastrat")
  des <- lsa_design(weight = "W_FSTUWT",
                    repweights = paste0("W_FSTURWT", 1:64))
  m <- lsa_model(pisa_mini, ~ ESCS + IMMIG + female,
                 achievement = paste0("PV", 1:5, "MATH"), design = des)
  expect_true("ESCS" %in% rownames(m$coefficients))
  expect_true(any(grepl("IMMIG", rownames(m$coefficients))))
  expect_true(all(m$coefficients$se > 0))
})

test_that("lsa_model supports a non-lm fitter (logistic glm)", {
  data(pisa_mini, package = "lsastrat")
  d <- pisa_mini
  # binary outcome PVs: above the median math score
  cut <- median(d$PV1MATH)
  for (a in paste0("PV", 1:5, "MATH")) d[[paste0(a, "_hi")]] <- as.integer(d[[a]] > cut)
  des <- lsa_design(weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
  m <- lsa_model(d, ~ ESCS, achievement = paste0("PV", 1:5, "MATH_hi"),
                 fitter = stats::glm, family = stats::quasibinomial(),
                 design = des)
  expect_true("ESCS" %in% rownames(m$coefficients))
  expect_gt(m$coefficients["ESCS", "estimate"], 0)   # higher ESCS -> higher odds
})

test_that("a two-sided or bad formula errors", {
  data(pisa_mini, package = "lsastrat")
  expect_error(
    suppressWarnings(lsa_model(pisa_mini, PV1MATH ~ ESCS, achievement = "PV1MATH")),
    "one-sided formula"
  )
})
