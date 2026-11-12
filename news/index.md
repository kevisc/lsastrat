# Changelog

## lsastrat 0.3.1

- New
  [`jk2_weights()`](https://kevinschoenholzer.com/lsastrat/reference/jk2_weights.md):
  builds the paired-jackknife replicate weights for TIMSS and PIRLS from
  the final weight, `JKZONE` and `JKREP`. The IEA files do not ship
  replicate weights, so until now users had to build them by hand before
  they could set `rep_method = "JK2"`.
- [`variance_decomposition()`](https://kevinschoenholzer.com/lsastrat/reference/variance_decomposition.md)
  now works with paired-jackknife (`"JK2"`) replicate weights, as used
  by TIMSS and PIRLS. A JK2 replicate sets the weight of one whole
  school to zero. Version 0.3.0 then stopped with “missing value where
  TRUE/FALSE needed”. The fit now drops zero-weight rows in each
  replicate. Results under BRR weights do not change.
- New script `data-raw/validate_piaac.R`: a check on the PIAAC Cycle 1
  public-use files for Germany (JK1) and Italy (JK2). It reproduces the
  published national means in numeracy and literacy. The README now
  states that the package also serves PIAAC.
- [`print()`](https://rdrr.io/r/base/print.html) for an `lsa_multiverse`
  object reported the share of positive estimates under the label
  “same-signed”, so a result that was negative in every specification
  printed as “0% same-signed”. The line now reports the share of
  specifications that have the sign of the median estimate. The object
  carries this value as `share_same_sign`; `share_pos` is unchanged.
- `autoplot()` no longer calls
  [`ggplot2::geom_errorbarh()`](https://ggplot2.tidyverse.org/reference/geom_linerange.html),
  which ggplot2 4.0 deprecated.
- `citation("lsastrat")` now reports the installed version and the
  Zenodo DOI. It reported version 0.1.0 before.
- Help pages: the page on
  [`lsa_design()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_design.md)
  now says that every estimator accepts a design, and the page on the
  shared methods lists all estimators. The page on
  [`lsa_model()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_model.md)
  states that weights are not scaled by level in multilevel models.

## lsastrat 0.3.0

General estimation, a shared design object, and tidyverse integration.

- [`lsa_model()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_model.md):
  fit **any** model (`lm`, `glm`, multilevel via `lme4::lmer`, …) to
  plausible-value outcomes, with replicate-weight variance and Rubin
  pooling. Lifts the package beyond the built-in estimators and beyond
  the OLS-only support of comparable tools.
- All estimators now accept a `design =` argument – an \[lsa_design()\]
  object bundling `weight`, `repweights`, `rep_method` and `fay` – so
  those arguments need not be repeated on every call.
- [`lsa_trend()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_trend.md):
  compare a quantity across assessment cycles and report the change from
  baseline with the linking (equating) error folded into the standard
  error.
- [`tidy()`](https://kevinschoenholzer.com/lsastrat/reference/tidy.lsastrat_estimate.md)
  and
  [`glance()`](https://kevinschoenholzer.com/lsastrat/reference/tidy.lsastrat_estimate.md)
  methods (via the `generics` package) for broom/tidyverse integration.
- Performance:
  [`social_gradient()`](https://kevinschoenholzer.com/lsastrat/reference/social_gradient.md),
  [`ieop()`](https://kevinschoenholzer.com/lsastrat/reference/ieop.md)
  and
  [`ieop_decompose()`](https://kevinschoenholzer.com/lsastrat/reference/ieop_decompose.md)
  now reuse a precomputed model matrix across plausible values and
  replicate weights (`lm.wfit`), giving identical results several times
  faster on large data (the Shapley decomposition is ~3x faster).
- Parallel processing: set `options(lsastrat.cores = n)` to run the
  replicate-weight refits across `n` cores (Unix/macOS; sequential
  fallback on Windows). Results are identical regardless of the core
  count.

## lsastrat 0.2.0

Comparative analysis, decompositions, a multiverse engine, and ggplot2
support.

### Comparative analysis

- [`lsa_by()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_by.md):
  run any estimator across the levels of a grouping variable (e.g.
  countries) and stack the pooled coefficients into one tidy, comparable
  table.
- [`equity_scatter()`](https://kevinschoenholzer.com/lsastrat/reference/equity_scatter.md):
  the OECD-style quality-vs-equity scatter (mean achievement against
  gradient strength) across groups.

### New estimators

- [`variance_decomposition()`](https://kevinschoenholzer.com/lsastrat/reference/variance_decomposition.md):
  between- vs within-school variance decomposition and the intraclass
  correlation (between-school share).
- [`ieop_decompose()`](https://kevinschoenholzer.com/lsastrat/reference/ieop_decompose.md):
  Shapley decomposition attributing the inequality of educational
  opportunity to each circumstance (contributions sum to the total).
- [`oaxaca_gap()`](https://kevinschoenholzer.com/lsastrat/reference/oaxaca_gap.md):
  twofold and threefold Oaxaca-Blinder decomposition of an achievement
  gap into explained (composition) and unexplained (structure).

### Multiverse

- [`lsa_multiverse()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_multiverse.md)
  and
  [`lsa_design()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_design.md):
  a plausible-value / replicate-weight aware specification-curve engine
  – run an estimator across a grid of analytic forking paths and
  summarise the robustness of a finding, with a specification-curve
  plot.

### Visualisation

- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods for
  `lsastrat_by`, `equity_scatter` and `lsa_multiverse`.
- `autoplot()` methods (ggplot2, Suggests) for estimates, the gradient,
  by-group forests, the equity scatter and the specification curve.

## lsastrat 0.1.0

First public release. `lsastrat` computes educational stratification and
inequality quantities from large-scale assessment data (PISA, TIMSS,
PIRLS) as first-class outputs, with plausible-value pooling and
replicate-weight variance.

### Estimators

- [`social_gradient()`](https://kevinschoenholzer.com/lsastrat/reference/social_gradient.md):
  the socio-economic achievement gradient, with slope, strength
  (R-squared x 100) and curvature, following the OECD definition.
  Cross-validated against
  [`intsvy::pisa.reg.pv()`](https://rdrr.io/pkg/intsvy/man/pisa.reg.pv.html).
- [`segregation_index()`](https://kevinschoenholzer.com/lsastrat/reference/segregation_index.md):
  school segregation indices (Dissimilarity D, Gorard’s S, isolation,
  Hutchens square-root, Theil’s H, mutual information M) for social or
  achievement-based (plausible-value pooled) grouping, with a choice of
  replicate-weight or two-stage clustered-bootstrap variance and
  finite-sample bias correction (Elbers, 2023). D and H cross-validated
  against the `segregation` package.
- [`ieop()`](https://kevinschoenholzer.com/lsastrat/reference/ieop.md):
  the Ferreira-Gignoux decomposition of inequality of educational
  opportunity (relative IOp = R-squared, with a degrees-of-freedom
  adjusted alternative and an overfitting warning, plus absolute IOp and
  total variance).

### Variance engine

- [`pool_pv()`](https://kevinschoenholzer.com/lsastrat/reference/pool_pv.md)
  and
  [`rep_factor()`](https://kevinschoenholzer.com/lsastrat/reference/rep_factor.md):
  the shared Rubin’s-rules pooling and replicate-weight machinery,
  exported for reuse. Inference uses a Rubin *t* reference, not the
  normal, which correctly widens intervals for the small number of
  plausible values typical in LSA.

### Infrastructure

- Shared S3 class `lsastrat_estimate` with
  [`coef()`](https://rdrr.io/r/stats/coef.html),
  [`confint()`](https://rdrr.io/r/stats/confint.html),
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html),
  [`print()`](https://rdrr.io/r/base/print.html)/[`summary()`](https://rdrr.io/r/base/summary.html),
  plus [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods
  for the gradient and segregation profile.
- Bundled simulated data set `pisa_mini` for examples, tests and the
  vignette.
- Note: only the segregation indices receive finite-sample bias
  correction; the gradient slope/strength and IOp are not subject to the
  same small-cell upward bias.
