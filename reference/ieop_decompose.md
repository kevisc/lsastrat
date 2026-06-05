# Shapley decomposition of inequality of educational opportunity

Attributes the relative inequality of educational opportunity (the
circumstance \\R^2\\ from
[`ieop()`](https://kevisc.github.io/lsastrat/reference/ieop.md)) to each
individual circumstance using Shapley values: each circumstance's
contribution is its average marginal increase in \\R^2\\ over all
orderings of the circumstance set. The contributions are additive and
**sum to the total relative IOp**, so they answer "how much of the
inequality of opportunity is due to migration vs parental education vs
books?". Estimates are pooled across plausible values and, when
replicate weights are supplied, carry design-based standard errors.

## Usage

``` r
ieop_decompose(
  data,
  achievement,
  circumstances,
  weight = NULL,
  repweights = NULL,
  rep_method = c("BRR", "JK2", "JK1"),
  fay = 0.5,
  design = NULL,
  level = 0.95
)
```

## Arguments

- data:

  A data frame of student-level records.

- achievement:

  Character vector of achievement plausible-value columns.

- circumstances:

  Character vector of circumstance columns; each entry (a variable,
  including all of its dummy levels) is one Shapley "player".

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

- level:

  Confidence level for the stored interval (default `0.95`).

## Value

An object of class `"ieop_decompose"` / `"lsastrat_estimate"` with one
row per circumstance (the Shapley contribution to relative IOp).

## Details

Because the Shapley value requires fitting a regression for every subset
of circumstances (\\2^k\\), the number of circumstances is capped at 8.

## References

Shorrocks, A. F. (2013). Decomposition procedures for distributional
analysis: a unified framework based on the Shapley value. *Journal of
Economic Inequality*, 11, 99-126.

## Examples

``` r
data(pisa_mini)
ieop_decompose(pisa_mini, paste0("PV", 1:10, "MATH"),
               circumstances = c("IMMIG", "parental_edu", "books"),
               weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
#> Inequality of opportunity: Shapley decomposition
#>   10 plausible value(s)  |  n = 2048  |  3 circumstance(s)
#>   Variance: BRR, 64 replicate weights (+ PV imputation); t reference
#> 
#> 
#>              Estimate Std.Error    t    df       p
#> IMMIG           0.009     0.005 2.01 425.3 4.5e-02
#> parental_edu    0.106     0.013 7.86 263.8 9.8e-14
#> books           0.094     0.013 7.44 178.5 4.1e-12
#> 
#> Shapley contributions to relative IOp (R^2); they sum to the total
```
