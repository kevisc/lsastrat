# Specification-curve plot

Draws the canonical two-panel specification curve: the sorted point
estimates with confidence intervals on top, and the active analytic
choice for each specification below.

## Usage

``` r
# S3 method for class 'lsa_multiverse'
plot(x, ...)
```

## Arguments

- x:

  An `"lsa_multiverse"` object.

- ...:

  Passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html) for
  the top panel.

## Value

`x`, invisibly.
