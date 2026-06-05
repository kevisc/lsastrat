
<!-- README.md is generated from README.Rmd. Please edit that file. -->

# lsastrat <img src="man/figures/logo.png" align="right" height="139" alt="lsastrat logo" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/kevisc/lsastrat/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/kevisc/lsastrat/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/kevisc/lsastrat/graph/badge.svg)](https://app.codecov.io/gh/kevisc/lsastrat)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License:
MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

**Stratification and inequality metrics for large-scale assessment (LSA)
data.**

`lsastrat` computes the educational-stratification quantities that
PISA/TIMSS/PIRLS researchers normally hand-assemble, and returns them as
first-class objects with correct **plausible-value pooling** (Rubin’s
rules) and **replicate-weight variance** (BRR/Fay, JK2, JK1):

- `social_gradient()` — the socio-economic achievement gradient (slope,
  strength = *R*² × 100, curvature).
- `segregation_index()` — school segregation indices (Dissimilarity,
  Gorard’s S, isolation, Hutchens, Theil’s H, mutual information) with a
  two-stage clustered bootstrap and **finite-sample bias correction**.
- `ieop()` — the Ferreira–Gignoux decomposition of inequality of
  educational opportunity.

It also **decomposes** these quantities (between/within-school variance,
Shapley decomposition of inequality of opportunity, Oaxaca–Blinder gap
decomposition), **compares** them across countries/subgroups
(`lsa_by()`, `equity_scatter()`), and runs PV/weight-aware
**specification-curve (multiverse)** analyses (`lsa_multiverse()`), with
base and `ggplot2` (`autoplot()`) graphics throughout. For models beyond
the built-in estimators, `lsa_model()` fits **any** model (`lm`, `glm`,
multilevel `lme4::lmer`) to plausible-value outcomes with
replicate-weight inference, and `lsa_trend()` compares a quantity across
assessment cycles with the linking error folded in.

General LSA packages (`EdSurvey`, `intsvy`, `BIFIEsurvey`, `RALSA`,
OECD’s `Rrepest`) handle plausible values and replicate weights but
expose only generic estimators (means, regression, correlation); none
emits these stratification quantities as labelled outputs. `lsastrat`
fills that gap and is designed to sit *alongside* those engines.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("kevisc/lsastrat")
```

## Example

All examples use the bundled, fully simulated `pisa_mini` data set.

``` r
library(lsastrat)
data(pisa_mini)

reps <- paste0("W_FSTURWT", 1:64)

social_gradient(
  pisa_mini,
  achievement = paste0("PV", 1:10, "MATH"),
  escs = "ESCS", weight = "W_FSTUWT", repweights = reps
)
#> Socio-economic achievement gradient
#>   SES index: ESCS   |   10 plausible value(s)   |   n = 2048
#>   Variance:  BRR, 64 replicate weights (+ PV imputation); t reference
#> 
#> 
#>           Estimate Std.Error     t    df       p
#> slope       41.357     1.831 22.59 399.4 2.1e-73
#> strength    20.189     1.799 11.22 389.1 1.7e-25
#> curvature    1.025     1.597  0.64 406.7 5.2e-01
#> 
#> slope = score points per 1 unit of ESCS; strength = % variance explained (R^2 x 100)
```

``` r
# social segregation by immigrant background, bias-corrected bootstrap variance
segregation_index(
  pisa_mini, unit = "school_id", group = "IMMIG", weight = "W_FSTUWT",
  variance = "bootstrap", n_boot = 199, boot_seed = 1
)
#> Segregation indices (social segregation)
#>   unit: school_id  |  128 units  |  3 group(s)  |  minority: first_gen
#>   Variance: clustered bootstrap (B=199, cluster=school_id), bias-corrected
#> 
#> 
#>           Estimate Std.Error     t  df       p
#> D            0.575     0.038 15.12 Inf 1.2e-51
#> S            0.550     0.041 13.41 Inf 5.1e-41
#> isolation    0.100     0.028  3.53 Inf 4.1e-04
#> Hutchens     0.359     0.037  9.70 Inf 3.0e-22
#> H            0.096     0.018  5.25 Inf 1.5e-07
#> M            0.075     0.017  4.49 Inf 7.1e-06
```

``` r
# inequality of opportunity attributable to circumstances
ieop(
  pisa_mini,
  achievement = paste0("PV", 1:10, "MATH"),
  circumstances = c("IMMIG", "parental_edu", "books"),
  weight = "W_FSTUWT", repweights = reps
)
#> Inequality of educational opportunity (Ferreira-Gignoux)
#>   10 plausible value(s)  |  n = 2048  |  3 circumstance(s): IMMIG, parental_edu, books
#>   Variance: BRR, 64 replicate weights (+ PV imputation); t reference
#> 
#> 
#>               Estimate Std.Error     t     df        p
#> iop              0.209     0.018 11.79  612.6  4.6e-29
#> iop_adj          0.206     0.018 11.58  610.7  3.7e-28
#> explained_var 1518.225   143.167 10.60 1204.1  3.5e-25
#> total_var     7253.731   228.176 31.79  517.7 8.7e-124
#> 
#> iop = share of achievement variance explained by circumstances (raw R^2, upper bound); iop_adj = df-adjusted
```

Every estimator returns an `lsastrat_estimate` object, so `coef()`,
`confint()`, `as.data.frame()` and `plot()` work uniformly.

## Validation

The estimators are cross-validated against established implementations:
`social_gradient()` reproduces `intsvy::pisa.reg.pv()`; the
Dissimilarity and Theil’s H indices match the `segregation` package; and
`ieop()` matches a weighted regression *R*².

## Citation

See `citation("lsastrat")`.

## Getting help & contributing

Please report bugs and ask questions on the [issue
tracker](https://github.com/kevisc/lsastrat/issues). See
[CONTRIBUTING](.github/CONTRIBUTING.md) and the [Code of
Conduct](.github/CODE_OF_CONDUCT.md).

## Roadmap

Cross-fitted (sample-split) inequality of opportunity and stratified
multiverse designs are planned for future releases.

## Funding

`lsastrat` was developed by Kevin Schoenholzer. This research was
supported by Università della Svizzera italiana (USI Lugano) and by the
Swiss National Science Foundation under grant 205177.

## License

MIT © Kevin Schoenholzer
