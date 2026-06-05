# Plot a cross-cycle trend

Plots the estimate at each cycle with confidence bars (the baseline
cycle's own SE, and the link-error-inflated change SE for later cycles).

## Usage

``` r
# S3 method for class 'lsa_trend'
plot(x, ...)
```

## Arguments

- x:

  An `"lsa_trend"` object.

- ...:

  Passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

`x`, invisibly.
