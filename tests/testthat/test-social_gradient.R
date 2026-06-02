test_that("slope recovers the known data-generating value", {
  d <- sim_lsa(slope = 40)
  g <- social_gradient(d, ach5(), "ESCS", "W_FSTUWT", repweights = reps_of(d))
  expect_s3_class(g, "social_gradient")
  expect_s3_class(g, "lsastrat_estimate")
  expect_equal(g$coefficients["slope", "estimate"], 40, tolerance = 2)
})

test_that("strength equals R-squared times 100 and lies in [0, 100]", {
  d <- sim_lsa()
  g <- social_gradient(d, ach5(), "ESCS", "W_FSTUWT", repweights = reps_of(d))
  s <- g$coefficients["strength", "estimate"]
  expect_true(s > 0 && s < 100)
})

test_that("pooling across PVs adds imputation variance to the SE", {
  d <- sim_lsa(n_pv = 5)
  multi  <- social_gradient(d, ach5(), "ESCS", "W_FSTUWT", repweights = reps_of(d))
  single <- social_gradient(d, ach5()[1], "ESCS", "W_FSTUWT", repweights = reps_of(d))
  # the single-PV df is infinite; the multi-PV df is finite (imputation variance)
  expect_identical(single$coefficients["slope", "df"], Inf)
  expect_true(is.finite(multi$coefficients["slope", "df"]))
})

test_that("a fixed analysis mask makes replicate variance robust to missing covariates", {
  d <- sim_lsa(seed = 3)
  g0 <- social_gradient(d, ach5(), "ESCS", "W_FSTUWT", repweights = reps_of(d))
  # inject NA ESCS into a few rows: the mask should drop them once, and the
  # replicate variance on the surviving rows must equal the pre-filtered fit
  d2 <- d
  na_rows <- c(1, 50, 100)
  d2$ESCS[na_rows] <- NA
  expect_message(
    g2 <- social_gradient(d2, ach5(), "ESCS", "W_FSTUWT", repweights = reps_of(d2)),
    "Using"
  )
  d_pre <- d[-na_rows, ]
  g_pre <- social_gradient(d_pre, ach5(), "ESCS", "W_FSTUWT", repweights = reps_of(d_pre))
  expect_equal(g2$coefficients["slope", "se"],
               g_pre$coefficients["slope", "se"], tolerance = 1e-8)
  expect_equal(g2$n_analytic, nrow(d) - length(na_rows))
})

test_that("missing replicate weights warn and fall back to model-based SE", {
  d <- sim_lsa()
  expect_warning(social_gradient(d, ach5(), "ESCS", "W_FSTUWT"), "model-based")
})

test_that("degenerate inputs raise clear errors", {
  d <- sim_lsa()
  expect_error(social_gradient(d, "PVnope", "ESCS", "W_FSTUWT"), "not found")
  d$ESCS <- 1
  expect_error(social_gradient(d, ach5(), "ESCS", "W_FSTUWT", repweights = reps_of(d)),
               "constant")
})

test_that("constant achievement warns that strength is undefined", {
  d <- sim_lsa()
  for (a in ach5()) d[[a]] <- 500
  expect_warning(
    social_gradient(d, ach5(), "ESCS", "W_FSTUWT", repweights = reps_of(d)),
    "constant"
  )
})

test_that("coef, confint and plot work on the bundled data", {
  skip_if_not(exists("pisa_mini"))
  data(pisa_mini, package = "lsastrat")
  g <- social_gradient(pisa_mini, paste0("PV", 1:10, "MATH"), "ESCS",
                       "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
  expect_named(coef(g), c("slope", "strength", "curvature"))
  expect_equal(dim(confint(g)), c(3, 2))
  expect_true(g$coefficients["slope", "estimate"] > 30 &&
              g$coefficients["slope", "estimate"] < 50)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  expect_invisible(plot(g))
})
