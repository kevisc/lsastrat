# Inequality of educational opportunity (Ferreira-Gignoux)

Computes the Ferreira-Gignoux (2014) measure of inequality of
educational opportunity (IOp): the share of achievement inequality
attributable to pre-determined *circumstances* (family background,
gender, migration status, and similar variables outside the student's
control). It is the \\R^2\\ of a regression of achievement on the
circumstance vector, using the **variance** as the inequality index.

## Usage

``` r
ieop(
  data,
  achievement,
  circumstances,
  weight = NULL,
  repweights = NULL,
  rep_method = c("BRR", "JK2", "JK1"),
  fay = 0.5,
  design = NULL,
  statistics = c("iop", "iop_adj", "explained_var", "total_var"),
  level = 0.95
)
```

## Arguments

- data:

  A data frame of student-level records.

- achievement:

  Character vector of achievement plausible-value columns.

- circumstances:

  Character vector of circumstance columns (the vector \\C\\).
  Character/factor columns are treated as categorical; numeric columns
  enter linearly. The canonical PISA application (Ferreira &
  Gignoux, 2014) uses gender, parental education and occupation, books
  and household possessions, language at home and migration status.

- weight:

  Name of the final student weight column. If `NULL`, equal weights are
  used (with a message).

- repweights:

  Optional character vector of replicate-weight columns.

- rep_method, fay:

  Replication design and Fay factor; see
  [`rep_factor()`](https://kevinschoenholzer.com/lsastrat/reference/rep_factor.md).

- design:

  Optional
  [`lsa_design()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_design.md)
  bundling `weight`, `repweights`, `rep_method` and `fay`; when supplied
  it overrides those arguments.

- statistics:

  Which quantities to return: `"iop"` (relative IOp = raw \\R^2\\),
  `"iop_adj"` (df-adjusted relative IOp), `"explained_var"` (absolute
  IOp) and `"total_var"` (total achievement variance).

- level:

  Confidence level for the stored interval (default `0.95`).

## Value

An object of class `"ieop"` / `"lsastrat_estimate"` (see
[lsastrat_estimate](https://kevinschoenholzer.com/lsastrat/reference/lsastrat_estimate.md)
for methods).

## Details

Following Ferreira & Gignoux, the variance is the inequality measure of
choice because, unlike the Gini coefficient or the mean log deviation,
it is ordinally invariant under the affine standardisation that
assessment scores undergo. The relative IOp is \$\$IOp =
\mathrm{Var}(\hat y) / \mathrm{Var}(y) = R^2,\$\$ the ratio of
circumstance-predicted ("smoothed") achievement variance to total
achievement variance. The absolute IOp is \\\mathrm{Var}(\hat y)\\ in
squared score points.

## Overfitting and the adjusted measure

The raw \\R^2\\ is an **upper bound**: it is mechanically inflated when
the circumstance vector expands into many dummy columns (Ferreira &
Gignoux, 2014). `ieop()` therefore also reports `iop_adj`, a
degrees-of-freedom adjusted relative IOp, \$\$1 - (1 -
R^2)\\\frac{n\_\mathrm{eff} - 1}{n\_\mathrm{eff} - k},\$\$ where
\\n\_\mathrm{eff}\\ is Kish's weighted effective sample size and \\k\\
the number of estimated parameters, and warns when \\k\\ is large
relative to \\n\_\mathrm{eff}\\. Cross-fitted / sample-split IOp is
planned for a future release.

Achievement is supplied as plausible values and pooled with Rubin's
rules; standard errors are design-based when replicate weights are
given.

## References

Ferreira, F. H. G. & Gignoux, J. (2014). The measurement of educational
inequality: Achievement and opportunity. *World Bank Economic Review*,
28(2), 210-246.

## Examples

``` r
data(pisa_mini)
ieop(pisa_mini,
     achievement = paste0("PV", 1:10, "MATH"),
     circumstances = c("IMMIG", "parental_edu", "books"),
     weight = "W_FSTUWT",
     repweights = paste0("W_FSTURWT", 1:64))
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
