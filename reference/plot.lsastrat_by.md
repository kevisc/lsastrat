# Forest / caterpillar plot of an estimate across groups

Plots the point estimate and confidence interval of one term across the
groups produced by
[`lsa_by()`](https://kevisc.github.io/lsastrat/reference/lsa_by.md),
sorted by estimate. A horizontal axis shows the quantity; each row is a
group.

## Usage

``` r
# S3 method for class 'lsastrat_by'
plot(x, term = NULL, sort = TRUE, ...)
```

## Arguments

- x:

  An `"lsastrat_by"` object.

- term:

  Which term (row name) to plot; defaults to the first term.

- sort:

  Logical; order groups by estimate (default `TRUE`).

- ...:

  Passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

`x`, invisibly.

## Examples

``` r
data(pisa_mini)
g <- lsa_by(pisa_mini, "IMMIG", social_gradient,
            achievement = paste0("PV", 1:10, "MATH"), escs = "ESCS",
            weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
plot(g, term = "slope")
```
