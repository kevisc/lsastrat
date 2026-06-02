# ggplot2 autoplot methods

`autoplot()` methods returning ggplot2 objects for lsastrat results: a
coefficient interval plot for any estimate, the gradient scatter, the
by-group forest plot, the quality-equity scatter, and the specification
curve. Requires ggplot2.

## Usage

``` r
# S3 method for class 'lsastrat_estimate'
autoplot(object, ...)

# S3 method for class 'social_gradient'
autoplot(object, ...)

# S3 method for class 'lsastrat_by'
autoplot(object, term = NULL, ...)

# S3 method for class 'equity_scatter'
autoplot(object, ...)

# S3 method for class 'lsa_multiverse'
autoplot(object, ...)
```

## Arguments

- object:

  An lsastrat result object.

- ...:

  Unused.

- term:

  For `lsastrat_by`, which term to plot (default: first).

## Value

A `ggplot` object.
