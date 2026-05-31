# Cross-validation against intsvy::pisa.reg.pv.
#
# intsvy combines per-PV BRR replicate variances with Rubin's rules using
#   SE = sqrt( Varw + (1 + 1/m) * Varb )
# which is exactly the scheme in pool_pv(). This test confirms that
# social_gradient() reproduces intsvy's slope and standard error on the same
# PISA-format data, so we are anchored to an established implementation.

make_pisa_format <- function(n = 3000, n_pv = 5, n_rep = 80,
                             slope = 35, sd = 85, seed = 7) {
  set.seed(seed)
  escs <- rnorm(n)
  truth <- 500 + slope * escs
  pv <- replicate(n_pv, truth + rnorm(n, sd = sd))
  colnames(pv) <- paste0("PV", seq_len(n_pv), "READ")
  w <- runif(n, 0.5, 3)
  # Fay BRR-style replicate weights: perturb the final weight up/down.
  rw <- replicate(n_rep, w * ifelse(runif(n) < 0.5, 1.5, 0.5))
  colnames(rw) <- paste0("W_FSTR", seq_len(n_rep))  # intsvy picks ^W_.*[0-9]+$
  data.frame(ESCS = escs, pv, W_FSTUWT = w, rw, check.names = FALSE)
}

test_that("social_gradient() matches intsvy::pisa.reg.pv on slope and SE", {
  skip_if_not_installed("intsvy")
  d <- make_pisa_format()
  reps <- grep("^W_FSTR", names(d), value = TRUE)
  ach  <- paste0("PV", 1:5, "READ")

  # intsvy 2.9: pvlabel is the full vector of PV column names
  iv <- intsvy::pisa.reg.pv(x = "ESCS", pvlabel = ach, data = d)$reg
  # intsvy's RegTab has rows: (Intercept), ESCS, R-squared
  iv_slope    <- iv["ESCS", "Estimate"]
  iv_slope_se <- iv["ESCS", "Std. Error"]
  iv_r2       <- iv["R-squared", "Estimate"]

  g <- social_gradient(d, achievement = ach, escs = "ESCS",
                       weight = "W_FSTUWT", repweights = reps,
                       rep_method = "BRR", fay = 0.5, curvature = FALSE)

  # intsvy rounds its table to 2 decimals; match within that tolerance
  expect_equal(g$coefficients["slope", "estimate"], iv_slope, tolerance = 0.02)
  expect_equal(g$coefficients["slope", "se"], iv_slope_se, tolerance = 0.02)
  # our strength is R-squared * 100
  expect_equal(g$coefficients["strength", "estimate"] / 100, iv_r2,
               tolerance = 0.02)
})
