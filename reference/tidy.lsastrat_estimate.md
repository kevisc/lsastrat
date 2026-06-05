# Tidy an lsastrat estimate

[`generics::tidy()`](https://generics.r-lib.org/reference/tidy.html) and
[`generics::glance()`](https://generics.r-lib.org/reference/glance.html)
methods for `"lsastrat_estimate"` objects, returning the broom-style
tidy data frame of coefficients and a one-row model summary. This lets
lsastrat results flow into the broom/tidyverse ecosystem (tables, plots,
`dplyr`).

## Usage

``` r
tidy(x, ...)

glance(x, ...)

# S3 method for class 'lsastrat_estimate'
tidy(x, ...)

# S3 method for class 'lsastrat_estimate'
glance(x, ...)
```

## Arguments

- x:

  An `"lsastrat_estimate"` object.

- ...:

  Unused.

## Value

`tidy()` a data frame with columns `term`, `estimate`, `std.error`,
`statistic`, `df`, `p.value`, `conf.low`, `conf.high`; `glance()` a
one-row data frame of estimator metadata.

## Examples

``` r
data(pisa_mini)
g <- social_gradient(pisa_mini, paste0("PV", 1:10, "MATH"), "ESCS",
                     "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
generics::tidy(g)
#>        term  estimate std.error  statistic       df      p.value  conf.low
#> 1     slope 41.357302  1.830573 22.5925470 399.3701 2.112631e-73 37.758539
#> 2  strength 20.188700  1.799350 11.2199971 389.1354 1.679262e-25 16.651036
#> 3 curvature  1.025083  1.596808  0.6419579 406.6947 5.212622e-01 -2.113944
#>   conf.high
#> 1 44.956065
#> 2 23.726363
#> 3  4.164111
generics::glance(g)
#>         estimator n_pv nobs design_based
#> 1 social_gradient   10 2048         TRUE
```
