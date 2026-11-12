# A TIMSS-like sample: `n_zone` zones, two schools per zone, with the IEA
# columns JKZONE / JKREP / TOTWGT.
sim_iea <- function(n_zone = 30, n_per = 12, seed = 5) {
  set.seed(seed)
  school <- rep(seq_len(2 * n_zone), each = n_per)
  d <- data.frame(
    school = school,
    JKZONE = (school + 1) %/% 2,
    JKREP = (school + 1) %% 2,
    TOTWGT = runif(length(school), 0.5, 2),
    ESCS = rnorm(length(school))
  )
  eff <- rnorm(2 * n_zone, sd = 25)[school]
  d$score <- 500 + 30 * d$ESCS + eff + rnorm(nrow(d), sd = 60)
  d
}

test_that("jk2_weights builds one replicate per zone by the IEA rule", {
  d <- sim_iea(n_zone = 6, n_per = 4)
  out <- jk2_weights(d)
  reps <- attr(out, "repweights")
  expect_equal(reps, paste0("JKW", 1:6))
  for (h in 1:6) {
    rw <- out[[reps[h]]]
    inz <- d$JKZONE == h
    expect_equal(rw[!inz], d$TOTWGT[!inz])
    expect_equal(rw[inz & d$JKREP == 1], 2 * d$TOTWGT[inz & d$JKREP == 1])
    expect_true(all(rw[inz & d$JKREP == 0] == 0))
  }
})

test_that("the JK2 standard error equals the textbook paired-jackknife formula", {
  d <- sim_iea()
  out <- jk2_weights(d)
  reps <- attr(out, "repweights")
  fit <- lsa_model(out, ~ ESCS, "score", weight = "TOTWGT", repweights = reps,
                   rep_method = "JK2")

  # independent computation: refit after doubling one half and dropping the
  # other half of each zone, then sum the squared deviations
  full <- coef(lm(score ~ ESCS, d, weights = TOTWGT))
  dev2 <- vapply(sort(unique(d$JKZONE)), function(h) {
    w <- d$TOTWGT
    inz <- d$JKZONE == h
    w[inz & d$JKREP == 1] <- 2 * w[inz & d$JKREP == 1]
    keep <- !(inz & d$JKREP == 0)
    (coef(lm(score ~ ESCS, d[keep, ], weights = w[keep])) - full)^2
  }, numeric(2))
  expect_equal(fit$coefficients$estimate, unname(full))
  expect_equal(fit$coefficients$se, unname(sqrt(rowSums(dev2))))
})

test_that("the school-level estimators run on jk2_weights output", {
  d <- sim_iea()
  d$low <- factor(ifelse(d$ESCS < -0.5, "low", "other"))
  out <- jk2_weights(d)
  reps <- attr(out, "repweights")
  v <- variance_decomposition(out, "score", unit = "school", weight = "TOTWGT",
                              repweights = reps, rep_method = "JK2")
  s <- segregation_index(out, unit = "school", group = "low", weight = "TOTWGT",
                         repweights = reps, rep_method = "JK2")
  expect_true(all(is.finite(v$coefficients$se)))
  expect_true(all(is.finite(s$coefficients$se)))
})

test_that("jk2_weights rejects bad input", {
  d <- sim_iea(n_zone = 4, n_per = 3)
  bad <- d
  bad$JKREP[1] <- 2
  expect_error(jk2_weights(bad), "coded 0 or 1")
  bad <- d
  bad$JKZONE[2] <- NA
  expect_error(jk2_weights(bad), "must not be missing")
  expect_error(jk2_weights(jk2_weights(d)), "already exist")
  expect_error(jk2_weights(d, weight = "nope"), "not found")
  one <- d[!(d$JKZONE == 1 & d$JKREP == 0), ]
  expect_warning(jk2_weights(one), "only one of the two halves")
})
