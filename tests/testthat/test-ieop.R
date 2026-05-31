sim_ieop <- function(n = 3000, signal = 25, noise = 70, n_pv = 5, seed = 1) {
  set.seed(seed)
  books <- factor(sample(c("few", "some", "many"), n, replace = TRUE))
  pared <- rnorm(n)
  base <- 500 + signal * pared +
    20 * (books == "many") - 15 * (books == "few")
  pv <- replicate(n_pv, base + rnorm(n, sd = noise))
  colnames(pv) <- paste0("PV", seq_len(n_pv), "MATH")
  w <- runif(n, 0.5, 2)
  rw <- replicate(16, w * ifelse(runif(n) < 0.5, 1.5, 0.5))
  colnames(rw) <- paste0("W_FSTR", 1:16)
  data.frame(books, pared, pv, W = w, rw)
}

ach_cols <- function(d) grep("MATH$", names(d), value = TRUE)
rep_cols <- function(d) grep("^W_FSTR", names(d), value = TRUE)

test_that("relative IOp equals the weighted regression R-squared", {
  d <- sim_ieop()
  res <- suppressWarnings(
    ieop(d, achievement = "PV1MATH", circumstances = c("books", "pared"),
         weight = "W"))
  # independent check via base lm on the same PV
  fit <- lm(PV1MATH ~ books + pared, data = d, weights = d$W)
  r2 <- summary(fit)$r.squared
  expect_equal(res$coefficients["iop", "estimate"], r2, tolerance = 1e-8)
})

test_that("explained variance never exceeds total variance and IOp in [0,1]", {
  d <- sim_ieop()
  res <- suppressWarnings(
    ieop(d, achievement = ach_cols(d), circumstances = c("books", "pared"),
         weight = "W"))
  co <- res$coefficients
  expect_gte(co["iop", "estimate"], 0)
  expect_lte(co["iop", "estimate"], 1)
  expect_lte(co["explained_var", "estimate"], co["total_var", "estimate"])
})

test_that("more circumstance signal yields higher IOp", {
  weak   <- suppressWarnings(ieop(sim_ieop(signal = 5,  noise = 90),
              achievement = "PV1MATH", circumstances = c("books", "pared"),
              weight = "W"))
  strong <- suppressWarnings(ieop(sim_ieop(signal = 60, noise = 40),
              achievement = "PV1MATH", circumstances = c("books", "pared"),
              weight = "W"))
  expect_gt(strong$coefficients["iop", "estimate"],
            weak$coefficients["iop", "estimate"])
})

test_that("pure-noise achievement gives IOp near zero", {
  set.seed(2); n <- 3000
  d <- data.frame(
    c1 = rnorm(n), c2 = factor(sample(letters[1:3], n, replace = TRUE)),
    PV1MATH = rnorm(n, 500, 80), W = runif(n, 0.5, 2))
  res <- suppressWarnings(
    ieop(d, "PV1MATH", circumstances = c("c1", "c2"), weight = "W"))
  expect_lt(res$coefficients["iop", "estimate"], 0.02)
})

test_that("replicate weights produce positive standard errors", {
  d <- sim_ieop()
  res <- ieop(d, achievement = ach_cols(d),
              circumstances = c("books", "pared"),
              weight = "W", repweights = rep_cols(d))
  expect_true(res$design_based)
  expect_gt(res$coefficients["iop", "se"], 0)
  expect_equal(res$n_pv, 5)
})

test_that("unknown columns and empty circumstances raise clear errors", {
  d <- sim_ieop()
  expect_error(
    suppressWarnings(ieop(d, "PVnope", circumstances = "books", weight = "W")),
    "not found"
  )
  expect_error(
    suppressWarnings(ieop(d, "PV1MATH", circumstances = character(0),
                          weight = "W")),
    "at least one circumstance"
  )
})
