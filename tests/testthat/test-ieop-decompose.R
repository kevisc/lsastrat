test_that("Shapley contributions sum to the total relative IOp", {
  data(pisa_mini, package = "lsastrat")
  circ <- c("IMMIG", "parental_edu", "books")
  dec <- suppressWarnings(
    ieop_decompose(pisa_mini, "PV1MATH", circ, weight = "W_FSTUWT"))
  io <- suppressWarnings(
    ieop(pisa_mini, "PV1MATH", circ, weight = "W_FSTUWT"))
  expect_equal(sum(dec$coefficients$estimate),
               io$coefficients["iop", "estimate"], tolerance = 1e-8)
  expect_equal(rownames(dec$coefficients), circ)
})

test_that("each circumstance gets a contribution and design SEs are positive", {
  data(pisa_mini, package = "lsastrat")
  dec <- ieop_decompose(pisa_mini, paste0("PV", 1:5, "MATH"),
                        c("IMMIG", "parental_edu", "books"),
                        weight = "W_FSTUWT",
                        repweights = paste0("W_FSTURWT", 1:64))
  expect_equal(nrow(dec$coefficients), 3L)
  expect_true(all(dec$coefficients$se > 0))
})

test_that("more than 8 circumstances is rejected", {
  data(pisa_mini, package = "lsastrat")
  expect_error(
    suppressWarnings(ieop_decompose(pisa_mini, "PV1MATH",
                                    circumstances = rep("ESCS", 9),
                                    weight = "W_FSTUWT")),
    "at most 8"
  )
})
