test_that("design = lsa_design() matches passing the arguments directly", {
  data(pisa_mini, package = "lsastrat")
  reps <- paste0("W_FSTURWT", 1:64)
  math <- paste0("PV", 1:10, "MATH")
  des <- lsa_design(weight = "W_FSTUWT", repweights = reps,
                    rep_method = "BRR", fay = 0.5)

  direct <- social_gradient(pisa_mini, math, "ESCS", "W_FSTUWT",
                            repweights = reps)
  viadesign <- social_gradient(pisa_mini, math, "ESCS", design = des)
  expect_equal(direct$coefficients, viadesign$coefficients)
})

test_that("design = works across estimators", {
  data(pisa_mini, package = "lsastrat")
  des <- lsa_design(weight = "W_FSTUWT",
                    repweights = paste0("W_FSTURWT", 1:64))
  s <- segregation_index(pisa_mini, "school_id", group = "IMMIG",
                         design = des, indices = c("D", "H"))
  expect_true(s$design_based)
  io <- ieop(pisa_mini, paste0("PV", 1:5, "MATH"),
             c("IMMIG", "books"), design = des)
  expect_gt(io$coefficients["iop", "se"], 0)
})

test_that("a non-lsa_design object is rejected", {
  data(pisa_mini, package = "lsastrat")
  expect_error(
    suppressWarnings(social_gradient(pisa_mini, "PV1MATH", "ESCS",
                                     design = list(weight = "W_FSTUWT"))),
    "lsa_design"
  )
})

test_that("tidy() and glance() return broom-style frames", {
  data(pisa_mini, package = "lsastrat")
  g <- social_gradient(pisa_mini, paste0("PV", 1:10, "MATH"), "ESCS",
                       "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
  td <- generics::tidy(g)
  expect_true(all(c("term", "estimate", "std.error", "statistic",
                    "p.value", "conf.low", "conf.high") %in% names(td)))
  expect_equal(nrow(td), 3L)
  gl <- generics::glance(g)
  expect_equal(gl$estimator, "social_gradient")
  expect_equal(nrow(gl), 1L)
})
