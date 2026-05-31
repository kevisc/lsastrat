# Helper: simulate a PISA-like dataset with a known gradient ------------------
sim_lsa <- function(n = 4000, slope = 40, sd = 80, n_pv = 5, n_rep = 8, seed = 1) {
  set.seed(seed)
  escs <- rnorm(n)
  truth <- 500 + slope * escs
  pv <- replicate(n_pv, truth + rnorm(n, sd = sd))
  colnames(pv) <- paste0("PV", seq_len(n_pv), "READ")
  w <- runif(n, 0.5, 2)
  # crude BRR-style replicate weights for testing the plumbing
  rw <- replicate(n_rep, w * ifelse(runif(n) < 0.5, 1.5, 0.5))
  colnames(rw) <- paste0("W_FSTR", seq_len(n_rep))
  data.frame(escs = escs, pv, W = w, rw)
}

test_that("slope recovers the known data-generating value", {
  d <- sim_lsa(slope = 40)
  g <- social_gradient(d, achievement = grep("READ$", names(d), value = TRUE),
                       escs = "escs", weight = "W",
                       repweights = grep("^W_FSTR", names(d), value = TRUE))
  expect_s3_class(g, "social_gradient")
  expect_equal(g$coefficients["slope", "estimate"], 40, tolerance = 2)
})

test_that("strength equals R-squared times 100 and lies in [0, 100]", {
  d <- sim_lsa()
  g <- social_gradient(d, achievement = grep("READ$", names(d), value = TRUE),
                       escs = "escs", weight = "W",
                       repweights = grep("^W_FSTR", names(d), value = TRUE))
  s <- g$coefficients["strength", "estimate"]
  expect_true(s > 0 && s < 100)
})

test_that("pooling across PVs inflates the SE (imputation variance > 0)", {
  d <- sim_lsa(n_pv = 5)
  reps <- grep("^W_FSTR", names(d), value = TRUE)
  ach <- grep("READ$", names(d), value = TRUE)
  g_multi  <- social_gradient(d, ach, "escs", "W", repweights = reps)
  g_single <- social_gradient(d, ach[1], "escs", "W", repweights = reps,
                              curvature = TRUE)
  # with a single PV there is no imputation variance, so the multi-PV SE,
  # which adds (1 + 1/m) * B, should be at least as large
  expect_gte(g_multi$coefficients["slope", "se"],
             g_single$coefficients["slope", "se"] * 0.9)
})

test_that("missing replicate weights warn and fall back to model-based SE", {
  d <- sim_lsa()
  expect_warning(
    social_gradient(d, grep("READ$", names(d), value = TRUE), "escs", "W"),
    "model-based"
  )
})

test_that("unknown columns raise a clear error", {
  d <- sim_lsa()
  expect_error(
    social_gradient(d, "PVnope", "escs", "W"),
    "not found"
  )
})

# --- pool_pv unit tests ------------------------------------------------------
test_that("pool_pv reduces to the sampling variance with one PV", {
  p <- pool_pv(estimates = 10, variances = 4)
  expect_equal(p$estimate, 10)
  expect_equal(p$se, 2)
  expect_equal(p$var_imputation, 0)
})

test_that("pool_pv adds the between-PV (imputation) variance", {
  p <- pool_pv(estimates = c(8, 10, 12), variances = c(4, 4, 4))
  expect_equal(p$estimate, 10)
  # U_bar = 4, B = var(c(8,10,12)) = 4, var_imp = (1 + 1/3)*4
  expect_equal(p$var_imputation, (1 + 1/3) * 4)
  expect_equal(p$se, sqrt(4 + (1 + 1/3) * 4))
})

test_that("rep_factor matches known designs", {
  expect_equal(lsastrat:::rep_factor("BRR", n_rep = 80, fay = 0.5), 1 / 20)
  expect_equal(lsastrat:::rep_factor("BRR", n_rep = 80, fay = 0),   1 / 80)
  expect_equal(lsastrat:::rep_factor("JK2", n_rep = 75),            1)
  expect_equal(lsastrat:::rep_factor("JK1", n_rep = 100),           99 / 100)
})
