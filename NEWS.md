# lsastrat 0.3.0

General estimation, a shared design object, and tidyverse integration.

* `lsa_model()`: fit **any** model (`lm`, `glm`, multilevel via `lme4::lmer`,
  ...) to plausible-value outcomes, with replicate-weight variance and Rubin
  pooling. Lifts the package beyond the built-in estimators and beyond the
  OLS-only support of comparable tools.
* All estimators now accept a `design =` argument -- an [lsa_design()] object
  bundling `weight`, `repweights`, `rep_method` and `fay` -- so those
  arguments need not be repeated on every call.
* `tidy()` and `glance()` methods (via the `generics` package) for
  broom/tidyverse integration.

# lsastrat 0.2.0

Comparative analysis, decompositions, a multiverse engine, and ggplot2 support.

## Comparative analysis
* `lsa_by()`: run any estimator across the levels of a grouping variable (e.g.
  countries) and stack the pooled coefficients into one tidy, comparable table.
* `equity_scatter()`: the OECD-style quality-vs-equity scatter (mean
  achievement against gradient strength) across groups.

## New estimators
* `variance_decomposition()`: between- vs within-school variance decomposition
  and the intraclass correlation (between-school share).
* `ieop_decompose()`: Shapley decomposition attributing the inequality of
  educational opportunity to each circumstance (contributions sum to the
  total).
* `oaxaca_gap()`: twofold and threefold Oaxaca-Blinder decomposition of an
  achievement gap into explained (composition) and unexplained (structure).

## Multiverse
* `lsa_multiverse()` and `lsa_design()`: a plausible-value / replicate-weight
  aware specification-curve engine -- run an estimator across a grid of
  analytic forking paths and summarise the robustness of a finding, with a
  specification-curve plot.

## Visualisation
* `plot()` methods for `lsastrat_by`, `equity_scatter` and `lsa_multiverse`.
* `autoplot()` methods (ggplot2, Suggests) for estimates, the gradient,
  by-group forests, the equity scatter and the specification curve.

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
