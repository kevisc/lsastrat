# Plot a socio-economic achievement gradient

Draws the weighted, SES-binned achievement means with the fitted
gradient line overlaid (and the quadratic curve when curvature was
estimated). Uses base graphics only.

## Usage

``` r
# S3 method for class 'social_gradient'
plot(x, ...)
```

## Arguments

- x:

  A `"social_gradient"` object.

- ...:

  Passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

`x`, invisibly.
