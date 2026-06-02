# Quality-equity scatter across groups

Computes, for each group (typically a country), mean achievement and the
socio-economic gradient, and draws the OECD-style "quality vs equity"
scatter: mean performance on one axis against the strength of the
socio-economic gradient (the percentage of variance ESCS explains) on
the other. Reference lines at the across-group averages split the plot
into the familiar quadrants (high quality / high equity, and so on).

## Usage

``` r
equity_scatter(
  data,
  by,
  achievement,
  escs = "ESCS",
  weight = NULL,
  repweights = NULL,
  rep_method = c("BRR", "JK2", "JK1"),
  fay = 0.5
)
```

## Arguments

- data:

  A data frame of student-level records.

- by:

  Name of the grouping column (e.g. country).

- achievement:

  Character vector of achievement plausible-value columns.

- escs:

  Name of the socio-economic index column (default `"ESCS"`).

- weight:

  Name of the final student weight column.

- repweights, rep_method, fay:

  Replicate-weight specification passed to
  [`social_gradient()`](https://kevisc.github.io/lsastrat/reference/social_gradient.md).

## Value

An object of class `"equity_scatter"`: a list with `data` (a data frame
of `group`, `mean`, `slope`, `strength`) plus metadata. Plot it with
[`plot.equity_scatter()`](https://kevisc.github.io/lsastrat/reference/plot.equity_scatter.md).

## Examples

``` r
data(pisa_mini)
es <- equity_scatter(pisa_mini, by = "IMMIG",
                     achievement = paste0("PV", 1:10, "MATH"),
                     escs = "ESCS", weight = "W_FSTUWT")
es
#> Quality-equity summary by IMMIG
#> 
#>       group   mean slope strength
#>      native 501.13 41.87    20.19
#>  second_gen 480.25 39.23    17.93
#>   first_gen 469.13 32.70    13.13
```
