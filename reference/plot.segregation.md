# Plot a school segregation profile

Draws the sorted per-unit minority shares (the segregation profile) with
the overall minority share marked. A flat profile at the overall share
means no segregation; a steep one means strong segregation. Base
graphics only.

## Usage

``` r
# S3 method for class 'segregation'
plot(x, ...)
```

## Arguments

- x:

  A `"segregation"` object.

- ...:

  Passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

`x`, invisibly.
