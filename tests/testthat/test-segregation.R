# Analytic edge cases (point estimates only) ----------------------------------
perfect_df <- function() {
  data.frame(school = rep(c("A", "B"), each = 10),
             grp = factor(c(rep("min", 10), rep("rest", 10))), w = 1)
}
even_df <- function() {
  data.frame(school = rep(1:10, each = 10),
             grp = factor(rep(c("min", "rest"), times = 50)), w = 1)
}

test_that("perfect segregation gives the known maxima", {
  s <- segregation_index(perfect_df(), "school", group = "grp",
                         minority = "min", weight = "w", variance = "none")
  co <- s$coefficients
  expect_equal(co["D", "estimate"], 1)
  expect_equal(co["Hutchens", "estimate"], 1)
  expect_equal(co["isolation", "estimate"], 1)
  expect_equal(co["H", "estimate"], 1)
  expect_equal(co["M", "estimate"], log(2))
  expect_equal(co["S", "estimate"], 0.5)            # Gorard's S maxes at 1 - P
})

test_that("an evenly mixed system has near-zero segregation", {
  s <- segregation_index(even_df(), "school", group = "grp",
                         minority = "min", weight = "w", variance = "none")
  co <- s$coefficients
  expect_equal(co["D", "estimate"], 0)
  expect_equal(co["H", "estimate"], 0)
  expect_equal(co["M", "estimate"], 0)
  expect_equal(co["isolation", "estimate"], 0.5)    # = overall minority share
})

# Bootstrap + bias correction --------------------------------------------------
test_that("bootstrap bias correction reduces the spurious mutual information", {
  # group assigned INDEPENDENTLY of school => true M = 0; small schools bias M up
  set.seed(7)
  n <- 3000
  d <- data.frame(school = sample(150, n, replace = TRUE),
                  grp = factor(rbinom(n, 1, 0.3)), w = 1)
  raw <- segregation_index(d, "school", group = "grp", indices = "M",
                           variance = "none")$coefficients["M", "estimate"]
  bc <- segregation_index(d, "school", group = "grp", indices = "M",
                          variance = "bootstrap", n_boot = 99, boot_seed = 1,
                          debias = TRUE)
  expect_gt(raw, 0)                                            # spurious M
  expect_lt(bc$coefficients["M", "estimate"], raw)            # debias shrinks it
  expect_gt(bc$coefficients["M", "se"], 0)
})

test_that("estimates are invariant to weight rescaling", {
  d <- even_df(); d$grp <- factor(sample(c("min", "rest"), nrow(d), TRUE))
  a <- segregation_index(d, "school", group = "grp", minority = "min",
                         weight = "w", variance = "bootstrap", n_boot = 49,
                         boot_seed = 3)
  d$w <- d$w * 1000
  b <- segregation_index(d, "school", group = "grp", minority = "min",
                         weight = "w", variance = "bootstrap", n_boot = 49,
                         boot_seed = 3)
  expect_equal(a$coefficients$estimate, b$coefficients$estimate, tolerance = 1e-8)
  expect_equal(a$coefficients$se, b$coefficients$se, tolerance = 1e-8)
})

# Crash regression (the reproduced critical bug) -------------------------------
test_that("a replicate that erases the only minority PSU yields NA SE, not a crash", {
  school <- rep(1:10, each = 20)
  grp <- rep("rest", 200)
  grp[which(school == 1)[1:3]] <- "min"               # 3 minority, all in school 1
  d <- data.frame(school, grp = factor(grp), w = 1,
                  W_FSTR1 = ifelse(school == 1, 0, 2)) # JK2 replicate deletes school 1
  expect_warning(
    s <- segregation_index(d, "school", group = "grp", minority = "min",
                           weight = "w", repweights = "W_FSTR1",
                           rep_method = "JK2", indices = c("D", "M")),
    "undefined"
  )
  expect_true(is.na(s$coefficients["D", "se"]))       # graceful NA, no error
})

# Errors and modes -------------------------------------------------------------
test_that("variance = 'replicate' without repweights errors", {
  expect_error(
    segregation_index(even_df(), "school", group = "grp", weight = "w",
                      variance = "replicate"),
    "requires `repweights`"
  )
})

test_that("a single group level warns of degenerate indices", {
  d <- data.frame(s = rep(1:5, each = 10), g = factor(rep("a", 50)), w = 1)
  expect_warning(
    segregation_index(d, "s", group = "g", weight = "w", variance = "none"),
    "Fewer than two groups"
  )
})

test_that("group and achievement are mutually exclusive", {
  expect_error(
    segregation_index(perfect_df(), "school", group = "grp",
                      achievement = "x", cutoff = 1),
    "exactly one"
  )
})

test_that("academic segregation pools across plausible values", {
  data(pisa_mini, package = "lsastrat")
  s <- segregation_index(pisa_mini, "school_id",
                         achievement = paste0("PV", 1:10, "MATH"),
                         cutoff = 480, indices = c("D", "H"),
                         variance = "none")
  expect_equal(s$type, "academic")
  expect_equal(s$n_pv, 10)
  expect_gt(s$coefficients["D", "estimate"], 0)
})

# Cross-validation against the segregation package (raw plug-in) ---------------
test_that("D and Theil's H match Elbers' segregation package", {
  skip_if_not_installed("segregation")
  set.seed(11)
  n <- 5000
  d <- data.frame(school = as.character(sample(60, n, replace = TRUE)),
                  grp = factor(rbinom(n, 1, 0.4), labels = c("adv", "dis")),
                  w = runif(n, 0.5, 2))
  ours <- segregation_index(d, "school", group = "grp", minority = "dis",
                            weight = "w", variance = "none")$coefficients
  mt <- segregation::mutual_total(d, "grp", "school", weight = "w")
  theirs_H <- mt$est[mt$stat == "H"]
  theirs_D <- segregation::dissimilarity(d, "grp", "school", weight = "w")$est
  expect_equal(ours["H", "estimate"], theirs_H, tolerance = 1e-6)
  expect_equal(ours["D", "estimate"], theirs_D, tolerance = 1e-6)
})
