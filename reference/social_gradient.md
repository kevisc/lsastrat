# Socio-economic achievement gradient

Computes the socio-economic gradient of achievement from large-scale
assessment data, following the OECD PISA definition: the **slope** is
the score-point change in achievement per one-unit change in the
socio-economic index (e.g. ESCS), and the **strength** is the percentage
of achievement variance explained by socio-economic status (\\R^2 \times
100\\). Optionally the quadratic **curvature** term is also reported.

## Usage

``` r
social_gradient(
  data,
  achievement,
  escs = "ESCS",
  weight = NULL,
  repweights = NULL,
  rep_method = c("BRR", "JK2", "JK1"),
  fay = 0.5,
  design = NULL,
  curvature = TRUE,
  level = 0.95
)
```

## Arguments

- data:

  A data frame of student-level records.

- achievement:

  Character vector of column names holding the achievement plausible
  values (e.g. `paste0("PV", 1:10, "MATH")`). A single column is allowed
  but then no imputation variance is estimated.

- escs:

  Name of the socio-economic index column (default `"ESCS"`).

- weight:

  Name of the final student weight column. If `NULL`, all cases are
  weighted equally (with a message).

- repweights:

  Optional character vector of replicate-weight column names. When
  supplied, standard errors are design-based; when `NULL`, a model-based
  (independence) standard error is returned with a warning.

- rep_method:

  Replication design: `"BRR"` (PISA default), `"JK2"` (TIMSS/PIRLS) or
  `"JK1"`. Used only when `repweights` is supplied.

- fay:

  Fay adjustment for BRR (PISA uses 0.5); see
  [`rep_factor()`](https://kevisc.github.io/lsastrat/reference/rep_factor.md).

- design:

  Optional
  [`lsa_design()`](https://kevisc.github.io/lsastrat/reference/lsa_design.md)
  bundling `weight`, `repweights`, `rep_method` and `fay`; when supplied
  it overrides those arguments.

- curvature:

  Logical; if `TRUE` (default) also fit a quadratic model and report the
  curvature (ESCS-squared) coefficient.

- level:

  Confidence level for the stored interval (default `0.95`).

## Value

An object of class `"social_gradient"` / `"lsastrat_estimate"` (see
[lsastrat_estimate](https://kevisc.github.io/lsastrat/reference/lsastrat_estimate.md)
for methods): a list with a `coefficients` data frame (rows `slope`,
`strength`, and optionally `curvature`) plus metadata.

## Details

Achievement is supplied as a set of plausible values (PVs); estimates
are pooled across PVs with Rubin's rules, and the sampling variance is
obtained from replicate weights when supplied (see
[`pool_pv()`](https://kevisc.github.io/lsastrat/reference/pool_pv.md)
and
[`rep_factor()`](https://kevisc.github.io/lsastrat/reference/rep_factor.md)).
Inference uses a \\t\\ reference (see
[`pool_pv()`](https://kevisc.github.io/lsastrat/reference/pool_pv.md)
for the degrees of freedom).

## References

OECD (2023). *PISA 2022 Results (Volume I)*, Annex A3 (socio-economic
gradient: slope and strength = \\R^2 \times 100\\).

## Examples

``` r
data(pisa_mini)
social_gradient(
  pisa_mini,
  achievement = paste0("PV", 1:10, "MATH"),
  escs = "ESCS",
  weight = "W_FSTUWT",
  repweights = paste0("W_FSTURWT", 1:64)
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
