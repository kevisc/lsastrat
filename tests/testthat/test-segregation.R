# Analytic edge cases ---------------------------------------------------------
# Two schools, fully segregated 50/50 split.
perfect_df <- function() {
  data.frame(
    school = rep(c("A", "B"), each = 10),
    grp = factor(c(rep("min", 10), rep("rest", 10))),
    w = 1
  )
}
# Ten schools, each exactly the overall 50/50 mix -> no segregation.
even_df <- function() {
  data.frame(
    school = rep(1:10, each = 10),
    grp = factor(rep(c("min", "rest"), times = 50)),
    w = 1
  )
}

test_that("point-estimate-only use warns about omitted sampling variance", {
  expect_warning(
    segregation_index(perfect_df(), unit = "school", group = "grp",
                      minority = "min", weight = "w"),
    "omit the sampling"
  )
})

test_that("perfect segregation gives the known maxima", {
  s <- suppressWarnings(
    segregation_index(perfect_df(), unit = "school", group = "grp",
                      minority = "min", weight = "w"))
  co <- s$coefficients
  expect_equal(co["D", "estimate"], 1)
  expect_equal(co["Hutchens", "estimate"], 1)
  expect_equal(co["isolation", "estimate"], 1)
  expect_equal(co["H", "estimate"], 1)          # Theil's H = 1 when fully segregated
  expect_equal(co["M", "estimate"], log(2))     # mutual information in nats
  # Gorard's S maxes at (1 - P); here P = 0.5
  expect_equal(co["S", "estimate"], 0.5)
})

test_that("an evenly mixed system has near-zero segregation", {
  s <- suppressWarnings(
    segregation_index(even_df(), unit = "school", group = "grp",
                      minority = "min", weight = "w"))
  co <- s$coefficients
  expect_equal(co["D", "estimate"], 0)
  expect_equal(co["S", "estimate"], 0)
  expect_equal(co["H", "estimate"], 0)
  expect_equal(co["M", "estimate"], 0)
  expect_equal(co["isolation", "estimate"], 0.5)  # = overall minority share P
})

test_that("indices stay in their valid ranges on random data", {
  set.seed(3)
  n <- 4000
  school <- sample(1:50, n, replace = TRUE)
  disadv <- rbinom(n, 1, plogis(-0.04 * school + 1))
  d <- data.frame(school, grp = factor(disadv, labels = c("adv", "dis")),
                  w = runif(n, 0.5, 2))
  s <- suppressWarnings(
    segregation_index(d, unit = "school", group = "grp", weight = "w"))
  co <- s$coefficients
  for (ix in c("D", "S", "Hutchens", "H", "M", "isolation")) {
    expect_gte(co[ix, "estimate"], 0)
  }
  expect_lte(co["D", "estimate"], 1)
  expect_lte(co["H", "estimate"], 1)
})

test_that("replicate weights produce positive standard errors", {
  set.seed(5); n <- 3000
  school <- sample(1:40, n, replace = TRUE)
  disadv <- rbinom(n, 1, plogis(-0.05 * school + 1))
  w <- runif(n, 0.5, 2)
  rw <- replicate(20, w * ifelse(runif(n) < 0.5, 1.5, 0.5))
  colnames(rw) <- paste0("W_FSTR", 1:20)
  d <- data.frame(school, grp = factor(disadv, labels = c("adv", "dis")),
                  W = w, rw)
  s <- segregation_index(d, unit = "school", group = "grp", weight = "W",
                         repweights = paste0("W_FSTR", 1:20))
  expect_true(s$design_based)
  expect_gt(s$coefficients["D", "se"], 0)
  expect_gt(s$coefficients["H", "se"], 0)
})

test_that("academic segregation pools across plausible values", {
  set.seed(8); n <- 3000
  school <- sample(1:40, n, replace = TRUE)
  ability <- -0.04 * school + rnorm(n)            # low-id schools score lower
  pv <- replicate(5, 500 + 30 * ability + rnorm(n, sd = 50))
  colnames(pv) <- paste0("PV", 1:5, "MATH")
  d <- data.frame(school, pv, w = runif(n, 0.5, 2))
  s <- suppressWarnings(
    segregation_index(d, unit = "school",
                      achievement = paste0("PV", 1:5, "MATH"),
                      cutoff = 480, indices = c("D", "H"), weight = "w"))
  expect_equal(s$type, "academic")
  expect_equal(s$n_pv, 5)
  expect_gt(s$coefficients["D", "estimate"], 0)
})

test_that("group and achievement are mutually exclusive", {
  expect_error(
    segregation_index(perfect_df(), unit = "school", group = "grp",
                      achievement = "x", cutoff = 1),
    "exactly one"
  )
})

# Cross-validation against the segregation package ----------------------------
test_that("D and Theil's H match Elbers' segregation package", {
  skip_if_not_installed("segregation")
  set.seed(11); n <- 5000
  school <- sample(1:60, n, replace = TRUE)
  disadv <- rbinom(n, 1, plogis(-0.05 * school + 1.2))
  d <- data.frame(school = as.character(school),
                  grp = factor(disadv, labels = c("adv", "dis")),
                  w = runif(n, 0.5, 2))

  ours <- suppressWarnings(
    segregation_index(d, unit = "school", group = "grp",
                      minority = "dis", weight = "w"))$coefficients

  # segregation::mutual_total returns M and H (H is base-independent)
  mt <- segregation::mutual_total(d, "grp", "school", weight = "w")
  theirs_H <- mt$est[mt$stat == "H"]
  theirs_D <- segregation::dissimilarity(d, "grp", "school", weight = "w")$est

  expect_equal(ours["H", "estimate"], theirs_H, tolerance = 1e-6)
  expect_equal(ours["D", "estimate"], theirs_D, tolerance = 1e-6)
})
