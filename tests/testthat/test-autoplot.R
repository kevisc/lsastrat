test_that("autoplot methods return ggplot objects", {
  skip_if_not_installed("ggplot2")
  data(pisa_mini, package = "lsastrat")
  reps <- paste0("W_FSTURWT", 1:64)
  math <- paste0("PV", 1:10, "MATH")

  g <- social_gradient(pisa_mini, math, "ESCS", "W_FSTUWT", repweights = reps)
  expect_s3_class(ggplot2::autoplot(g), "ggplot")            # social_gradient
  s <- segregation_index(pisa_mini, "school_id", group = "IMMIG",
                         weight = "W_FSTUWT", variance = "bootstrap",
                         n_boot = 49, boot_seed = 1)
  expect_s3_class(ggplot2::autoplot(s), "ggplot")            # lsastrat_estimate

  by <- lsa_by(pisa_mini, "IMMIG", social_gradient, achievement = math,
               escs = "ESCS", weight = "W_FSTUWT", repweights = reps)
  expect_s3_class(ggplot2::autoplot(by, term = "slope"), "ggplot")

  es <- equity_scatter(pisa_mini, "IMMIG", math, "ESCS", "W_FSTUWT")
  expect_s3_class(ggplot2::autoplot(es), "ggplot")

  mv <- lsa_multiverse(pisa_mini, social_gradient,
    grid = list(achievement = list(m = math, r = paste0("PV", 1:10, "READ"))),
    fixed = list(escs = "ESCS", weight = "W_FSTUWT"), term = "slope")
  expect_s3_class(ggplot2::autoplot(mv), "ggplot")
})
