# lsastrat 0.1.0

First public release. `lsastrat` computes educational stratification and
inequality quantities from large-scale assessment data (PISA, TIMSS, PIRLS) as
first-class outputs, with plausible-value pooling and replicate-weight variance.

## Estimators

* `social_gradient()`: the socio-economic achievement gradient — slope,
  strength (R-squared x 100) and curvature, following the OECD definition.
  Cross-validated against `intsvy::pisa.reg.pv()`.
* `segregation_index()`: school segregation indices (Dissimilarity D, Gorard's
  S, isolation, Hutchens square-root, Theil's H, mutual information M) for
  social or achievement-based (plausible-value pooled) grouping, with a choice
  of replicate-weight or two-stage clustered-bootstrap variance and
  finite-sample bias correction (Elbers, 2023). D and H cross-validated
  against the `segregation` package.
* `ieop()`: the Ferreira-Gignoux decomposition of inequality of educational
  opportunity (relative IOp = R-squared, with a degrees-of-freedom adjusted
  alternative and an overfitting warning, plus absolute IOp and total
  variance).

## Variance engine

* `pool_pv()` and `rep_factor()`: the shared Rubin's-rules pooling and
  replicate-weight machinery, exported for reuse. Inference uses a Rubin
  *t* reference, not the normal, which correctly widens intervals for the small
  number of plausible values typical in LSA.

## Infrastructure

* Shared S3 class `lsastrat_estimate` with `coef()`, `confint()`,
  `as.data.frame()`, `print()`/`summary()`, plus `plot()` methods for the
  gradient and segregation profile.
* Bundled simulated data set `pisa_mini` for examples, tests and the vignette.
* Note: only the segregation indices receive finite-sample bias correction; the
  gradient slope/strength and IOp are not subject to the same small-cell
  upward bias.
