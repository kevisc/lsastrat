test_that("the lsastrat.cores parallel path matches sequential results", {
  skip_on_os("windows")
  skip_on_cran()
  data(pisa_mini, package = "lsastrat")
  des <- lsa_design(weight = "W_FSTUWT",
                    repweights = paste0("W_FSTURWT", 1:64))
  math <- paste0("PV", 1:10, "MATH")
  old <- getOption("lsastrat.cores")
  on.exit(options(lsastrat.cores = old), add = TRUE)

  options(lsastrat.cores = 1L)
  seq_g <- social_gradient(pisa_mini, math, "ESCS", design = des)
  seq_s <- segregation_index(pisa_mini, "school_id", group = "IMMIG",
                             design = des, indices = c("D", "H"))

  options(lsastrat.cores = 2L)
  par_g <- social_gradient(pisa_mini, math, "ESCS", design = des)
  par_s <- segregation_index(pisa_mini, "school_id", group = "IMMIG",
                             design = des, indices = c("D", "H"))

  expect_equal(seq_g$coefficients, par_g$coefficients)
  expect_equal(seq_s$coefficients, par_s$coefficients)
})
