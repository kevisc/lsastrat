# lsastrat

<!-- badges: start -->
<!-- badges: end -->

**Stratification and inequality metrics for large-scale assessment (LSA) data.**

`lsastrat` computes the educational-stratification quantities that PISA/TIMSS/PIRLS
researchers normally hand-assemble — and returns them as first-class objects, with
correct **plausible-value pooling** (Rubin's rules) and **replicate-weight variance**
(BRR/Fay, JK2, JK1).

General LSA packages (`EdSurvey`, `intsvy`, `BIFIEsurvey`, `RALSA`, OECD's `Rrepest`)
handle plausible values and replicate weights correctly but expose only generic
estimators (means, regression, correlation). None of them emits a socio-economic
*gradient*, school *segregation* indices, or an *inequality-of-opportunity*
decomposition as a labelled output. `lsastrat` fills that gap and is designed to sit
*on top of* those engines rather than replace them.

## Status

Early scaffold. Implemented:

- [x] `social_gradient()` — SES→achievement **slope**, **strength** (R² × 100,
  OECD definition) and **curvature**, PV-pooled and replicate-weighted.
  *Cross-validated against `intsvy::pisa.reg.pv`.*
- [x] `segregation_index()` — Dissimilarity **D**, **Gorard's S**, isolation,
  **Hutchens** square-root, **Theil's H** and mutual information **M**, for
  social *or* achievement-based (PV-pooled) grouping, with replicate-weight
  SEs. *D and H cross-validated against the `segregation` package.*
- [x] `pool_pv()` / `rep_factor()` — the shared Rubin's-rules + replicate-weight
  variance engine.

Planned:

- [ ] `ieop()` — Ferreira–Gignoux inequality of educational opportunity
  (achievement variance explained by circumstances).
- [ ] Bootstrap variance option for segregation indices.
- [ ] PV/weight-aware specification-curve / multiverse engine.

## Installation

```r
# install.packages("devtools")
devtools::install_local("lsastrat")
```

## Example

```r
library(lsastrat)

social_gradient(
  data        = pisa_subset,
  achievement = paste0("PV", 1:10, "MATH"),
  escs        = "ESCS",
  weight      = "W_FSTUWT",
  repweights  = paste0("W_FSTURWT", 1:80),
  rep_method  = "BRR", fay = 0.5
)
#> Socio-economic achievement gradient
#>   SES index: ESCS   |   10 plausible value(s)   |   n = ...
#>   Variance:  BRR, 80 replicate weights (+ PV imputation)
#>
#>          Estimate Std.Error     z  p
#> slope       ...       ...     ...  ...
#> strength    ...       ...     ...  ...
#> curvature   ...       ...     ...  ...
```

## License

MIT © 2026 Kevin Schoenholzer
