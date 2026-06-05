# Oaxaca-Blinder decomposition of an achievement gap

Decomposes the mean achievement gap between two groups (for example
native vs immigrant-background students) into a part **explained** by
differences in characteristics (endowments/composition) and an
**unexplained** part due to differences in returns (structure). This is
the standard stratification tool for asking "how much of the gap is
because the groups differ in their resources, and how much remains after
accounting for them?".

## Usage

``` r
oaxaca_gap(
  data,
  achievement,
  group,
  predictors,
  groups = NULL,
  weight = NULL,
  repweights = NULL,
  rep_method = c("BRR", "JK2", "JK1"),
  fay = 0.5,
  design = NULL,
  type = c("twofold", "threefold"),
  level = 0.95
)
```

## Arguments

- data:

  A data frame of student-level records.

- achievement:

  Character vector of achievement plausible-value columns.

- group:

  Name of the two-group column.

- predictors:

  Character vector of explanatory variables.

- groups:

  Optional length-2 character vector `c(high, low)`; the gap is
  `mean(high) - mean(low)`. Defaults to the two levels present (the more
  advantaged, by mean achievement, is taken as `high`).

- weight:

  Name of the final student weight column. If `NULL`, equal weights are
  used (with a message).

- repweights:

  Optional character vector of replicate-weight columns.

- rep_method, fay:

  Replication design and Fay factor; see
  [`rep_factor()`](https://kevisc.github.io/lsastrat/reference/rep_factor.md).

- design:

  Optional
  [`lsa_design()`](https://kevisc.github.io/lsastrat/reference/lsa_design.md)
  bundling `weight`, `repweights`, `rep_method` and `fay`; when supplied
  it overrides those arguments.

- type:

  `"twofold"` (default) or `"threefold"`.

- level:

  Confidence level for the stored interval (default `0.95`).

## Value

An object of class `"oaxaca_gap"` / `"lsastrat_estimate"`.

## Details

The `"twofold"` form uses a pooled reference model (Neumark) and reports
`gap`, `explained` and `unexplained`. The `"threefold"` form reports
`gap`, `endowments`, `coefficients` and `interaction`. Estimates are
pooled over plausible values with replicate-weight standard errors (see
[`pool_pv()`](https://kevisc.github.io/lsastrat/reference/pool_pv.md)).

## References

Oaxaca, R. (1973). Male-female wage differentials in urban labor
markets. *International Economic Review*, 14(3), 693-709. Blinder, A. S.
(1973). Wage discrimination: reduced form and structural estimates.
*Journal of Human Resources*, 8(4), 436-455.

## Examples

``` r
data(pisa_mini)
# native vs first-generation immigrant gap, explained by ESCS, books, parental ed
d <- pisa_mini[pisa_mini$IMMIG %in% c("native", "first_gen"), ]
d$IMMIG <- factor(d$IMMIG)
oaxaca_gap(d, paste0("PV", 1:10, "MATH"), group = "IMMIG",
           predictors = c("ESCS", "books", "parental_edu"),
           weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
#> Oaxaca-Blinder gap decomposition (twofold)
#>   IMMIG: native - first_gen  |  10 plausible value(s)  |  n = 1421
#>   Variance: BRR, 64 replicate weights (+ PV imputation); t reference
#> 
#> 
#>             Estimate Std.Error    t       df       p
#> gap           32.004     9.690 3.30    627.4 1.0e-03
#> explained     29.250     5.364 5.45 134118.7 5.0e-08
#> unexplained    2.755     8.819 0.31    476.5 7.5e-01
#> 
#> gap = mean(native) - mean(first_gen); components sum to gap
```
