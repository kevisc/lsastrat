# Cross-validation against intsvy::pisa.reg.pv.
#
# intsvy combines per-PV BRR replicate variances with Rubin's rules using
#   SE = sqrt( Varw + (1 + 1/m) * Varb )
# which is the scheme in pool_pv(). This confirms social_gradient() reproduces
# intsvy's slope, standard error and R-squared on the same PISA-format data,
# anchoring the package to an established implementation.

test_that("social_gradient() matches intsvy::pisa.reg.pv on slope, SE and R^2", {
  skip_if_not_installed("intsvy")
  d <- sim_lsa(n = 3000, slope = 35, sd = 85, n_pv = 5, n_rep = 80, seed = 7)
  ach <- paste0("PV", 1:5, "MATH")

  iv <- intsvy::pisa.reg.pv(x = "ESCS", pvlabel = ach, data = d)$reg
  iv_slope    <- iv["ESCS", "Estimate"]
  iv_slope_se <- iv["ESCS", "Std. Error"]
  iv_r2       <- iv["R-squared", "Estimate"]

  g <- social_gradient(d, achievement = ach, escs = "ESCS",
                       weight = "W_FSTUWT", repweights = reps_of(d),
                       rep_method = "BRR", fay = 0.5, curvature = FALSE)

  expect_equal(g$coefficients["slope", "estimate"], iv_slope, tolerance = 0.02)
  expect_equal(g$coefficients["slope", "se"], iv_slope_se, tolerance = 0.02)
  expect_equal(g$coefficients["strength", "estimate"] / 100, iv_r2,
               tolerance = 0.02)
})
