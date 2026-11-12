# Run an estimator across groups (e.g. countries)

Applies any lsastrat estimator
([`social_gradient()`](https://kevinschoenholzer.com/lsastrat/reference/social_gradient.md),
[`segregation_index()`](https://kevinschoenholzer.com/lsastrat/reference/segregation_index.md),
[`ieop()`](https://kevinschoenholzer.com/lsastrat/reference/ieop.md),
[`variance_decomposition()`](https://kevinschoenholzer.com/lsastrat/reference/variance_decomposition.md))
separately within each level of a grouping variable and stacks the
pooled coefficients into one tidy, comparable table. This is the
workhorse for comparative large-scale assessment research: one call
returns the gradient (or any other quantity) for every country, with
confidence intervals, ready to plot or tabulate.

## Usage

``` r
lsa_by(data, by, estimator, ..., .progress = FALSE)
```

## Arguments

- data:

  A data frame of student-level records.

- by:

  Name of the grouping column (e.g. a country identifier).

- estimator:

  The estimator to apply: a function such as `social_gradient`, or its
  name as a string.

- ...:

  Arguments passed on to `estimator` (everything except `data`).

- .progress:

  Logical; message each group as it is processed.

## Value

An object of class `"lsastrat_by"`: a list with `results` (a data frame
with a `group` column followed by `term` and the pooled coefficient
columns) plus metadata. Groups for which the estimator fails are dropped
with a warning.

## See also

[`plot.lsastrat_by()`](https://kevinschoenholzer.com/lsastrat/reference/plot.lsastrat_by.md)
for forest/caterpillar plots.

## Examples

``` r
data(pisa_mini)
# gradient by immigrant background (any grouping column works)
lsa_by(pisa_mini, by = "IMMIG", estimator = social_gradient,
       achievement = paste0("PV", 1:10, "MATH"), escs = "ESCS",
       weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
#> `social_gradient` by IMMIG  (3 groups)
#> 
#>       group      term estimate     se statistic       df     p   ci_lo  ci_hi
#>      native     slope   41.867  2.070    20.224  580.355 0.000  37.801 45.933
#>      native  strength   20.192  1.934    10.438  346.181 0.000  16.388 23.997
#>      native curvature    0.752  1.920     0.392  242.884 0.696  -3.031  4.534
#>  second_gen     slope   39.234  3.548    11.058  792.323 0.000  32.269 46.198
#>  second_gen  strength   17.931  2.935     6.108  425.972 0.000  12.161 23.700
#>  second_gen curvature    0.560  2.792     0.201 1125.479 0.841  -4.919  6.039
#>   first_gen     slope   32.697 11.252     2.906  338.768 0.004  10.566 54.829
#>   first_gen  strength   13.126  9.079     1.446  258.647 0.149  -4.752 31.003
#>   first_gen curvature    7.279  8.914     0.817  600.676 0.414 -10.227 24.785
```
