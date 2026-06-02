# Plot a quality-equity scatter

Plot a quality-equity scatter

## Usage

``` r
# S3 method for class 'equity_scatter'
plot(x, x_axis = c("strength", "slope"), ...)
```

## Arguments

- x:

  An `"equity_scatter"` object.

- x_axis:

  Which gradient measure on the x-axis: `"strength"` (default,
  percentage of variance explained) or `"slope"`.

- ...:

  Passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

`x`, invisibly.
