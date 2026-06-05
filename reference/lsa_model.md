# Fit any model to plausible-value outcomes with replicate-weight inference

A general estimation engine: fit an arbitrary model (linear, generalised
linear, multilevel, ...) to a plausible-value outcome on each plausible
value and each replicate weight, and pool the coefficients with Rubin's
rules and replicate-weight variance. This lifts the package beyond the
built-in estimators – and beyond the OLS-only support of `intsvy` and
similar – to *any* model whose fitter accepts `formula`, `data` and
`weights`.

## Usage

``` r
lsa_model(
  data,
  formula,
  achievement,
  fitter = stats::lm,
  coefs = stats::coef,
  weight = NULL,
  repweights = NULL,
  rep_method = c("BRR", "JK2", "JK1"),
  fay = 0.5,
  design = NULL,
  level = 0.95,
  ...
)
```

## Arguments

- data:

  A data frame of student-level records.

- formula:

  A one-sided formula of the predictor/structure, e.g. `~ ESCS + IMMIG`
  or, for a multilevel model, `~ ESCS + (1 | school_id)`. The outcome is
  filled in from `achievement` for each plausible value.

- achievement:

  Character vector of achievement plausible-value columns (the outcome
  set). A single column is allowed.

- fitter:

  The model-fitting function (default
  [stats::lm](https://rdrr.io/r/stats/lm.html)); e.g.
  [`stats::glm`](https://rdrr.io/r/stats/glm.html), `lme4::lmer`. Must
  accept `formula`, `data` and `weights`.

- coefs:

  A function extracting a **named numeric vector** of the parameters to
  pool from a fitted model (default
  [stats::coef](https://rdrr.io/r/stats/coef.html); use `lme4::fixef`
  for `lme4::lmer`).

- weight, repweights, rep_method, fay, design:

  Weighting/replication specification, exactly as in the other
  estimators (see
  [`social_gradient()`](https://kevisc.github.io/lsastrat/reference/social_gradient.md)
  and
  [`lsa_design()`](https://kevisc.github.io/lsastrat/reference/lsa_design.md)).

- level:

  Confidence level for the stored interval (default `0.95`).

- ...:

  Further arguments passed to `fitter` (e.g. `family = binomial()` for a
  logistic model).

## Value

An object of class `"lsa_model"` / `"lsastrat_estimate"` with one row
per model coefficient (see
[lsastrat_estimate](https://kevisc.github.io/lsastrat/reference/lsastrat_estimate.md)
for methods).

## Details

Standard errors are design-based: each coefficient's sampling variance
comes from refitting on the replicate weights, and the spread across
plausible values adds the imputation component (Rubin's rules). With
multilevel fitters this means many model fits (replicates x plausible
values); use a modest number of replicates while prototyping. For
weighted logistic models prefer `family = quasibinomial()` over
[`binomial()`](https://rdrr.io/r/stats/family.html) to avoid the
"non-integer \#successes" warning that survey weights trigger.

## Examples

``` r
data(pisa_mini)
des <- lsa_design(weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
# a multiple regression on a PV outcome
lsa_model(pisa_mini, ~ ESCS + IMMIG, achievement = paste0("PV", 1:10, "MATH"),
          design = des)
#> Model: stats::lm(<PV> ~ ESCS + IMMIG)
#>   10 plausible value(s)  |  n = 2048
#>   Variance: BRR, 64 replicate weights (+ PV imputation); t reference
#> 
#> 
#>                 Estimate Std.Error      t     df       p
#> (Intercept)      496.490     2.220 223.66 4968.3 0.0e+00
#> ESCS              40.679     1.871  21.74  382.1 8.5e-69
#> IMMIGsecond_gen   -9.843     4.308  -2.28  231.0 2.3e-02
#> IMMIGfirst_gen    -4.038     9.319  -0.43  469.4 6.6e-01
#> 
#> fitter = stats::lm
```
