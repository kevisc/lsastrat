# Plausible-value / weight-aware multiverse (specification-curve) analysis

Runs an lsastrat estimator across a grid of analytic specifications –
the "forking paths" of a multiverse analysis – and collects one tracked
quantity from each, so the robustness of a finding to defensible
analytic choices can be read off a specification curve. Every
specification inherits correct plausible-value pooling and
replicate-weight inference from the underlying estimator.

## Usage

``` r
lsa_multiverse(
  data,
  estimator,
  grid,
  fixed = list(),
  design = NULL,
  term = NULL,
  .progress = FALSE
)
```

## Arguments

- data:

  A data frame of student-level records.

- estimator:

  The estimator to run: a function (e.g. `social_gradient`) or its name.

- grid:

  A named list of forking paths. Each name is an **argument** of
  `estimator`; each element is a named list of the alternative values
  for that argument (the inner names label the choices). All
  combinations are crossed.

- fixed:

  A named list of arguments held constant across specifications.

- design:

  Optional
  [`lsa_design()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_design.md)
  whose fields are added to `fixed`.

- term:

  Which output term (row of the estimator's coefficients) to track;
  defaults to the first term.

- .progress:

  Logical; message each specification as it runs.

## Value

An object of class `"lsa_multiverse"`: a list with `specs` (one row per
specification: a column per forking path plus `estimate`, `ci_lo`,
`ci_hi`) and a summary: the median and range of the estimates, the share
of specifications with a positive estimate (`share_pos`), the share that
has the sign of the median (`share_same_sign`), and the share whose
interval excludes zero (`share_sig`). Plot it with
[`plot.lsa_multiverse()`](https://kevinschoenholzer.com/lsastrat/reference/plot.lsa_multiverse.md).

## Examples

``` r
data(pisa_mini)
des <- lsa_design(weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
mv <- lsa_multiverse(
  pisa_mini, estimator = social_gradient,
  grid = list(
    achievement = list(math = paste0("PV", 1:10, "MATH"),
                       read = paste0("PV", 1:10, "READ")),
    curvature = list(linear = FALSE, quadratic = TRUE)
  ),
  fixed = list(escs = "ESCS"), design = des, term = "slope")
mv
#> Multiverse: `social_gradient`, term = slope  (4 specifications)
#>   median estimate: 39.1   range: [36.8, 41.4]
#>   100% of specifications share the sign of the median; 100% exclude 0 (95% CI)
```
