# Trend across assessment cycles with linking error

Compares a quantity (a gradient slope, a mean, a segregation index, ...)
across two or more assessment cycles and reports the change from the
baseline cycle, propagating the **linking (equating) error** into the
standard error of each change. Comparing scores across PISA/TIMSS cycles
carries an extra uncertainty from re-equating the scale; the variance of
a cross-cycle difference is \$\$\mathrm{Var}(\Delta) = SE_1^2 + SE_2^2 +
\mathrm{linkerror}^2.\$\$

## Usage

``` r
lsa_trend(cycles, term = NULL, link_error = 0, level = 0.95)
```

## Arguments

- cycles:

  A **named** list of fitted estimate objects (class
  `"lsastrat_estimate"`), one per cycle, in chronological order; the
  names are the cycle labels (e.g. `"2012"`, `"2018"`, `"2022"`). The
  first cycle is the baseline.

- term:

  Which term (coefficient row) to track; defaults to the first.

- link_error:

  The linking error to add to each change's standard error: a single
  value applied to every cycle-vs-baseline comparison, or a vector of
  length `length(cycles) - 1`. Defaults to `0` (no link error).

- level:

  Confidence level for the change intervals (default `0.95`).

## Value

An object of class `"lsa_trend"`: a list with a `coefficients` data
frame (one row per cycle: `estimate`, `se`, and – for non-baseline
cycles – `change`, `change_se`, `statistic`, `p`, `ci_lo`, `ci_hi` of
the change from baseline) plus metadata. Cross-cycle change tests use a
normal reference.

## Details

The link error applies only to quantities expressed on the **achievement
scale** (means, score-point gradient slopes). For scale-free quantities
(correlations, the gradient *strength* / \\R^2\\, segregation indices,
inequality-of-opportunity shares) set `link_error = 0`.

## References

OECD (2023). *PISA 2022 Technical Report*, chapter on linking error and
trends.

## Examples

``` r
data(pisa_mini)
des <- lsa_design(weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
math <- paste0("PV", 1:10, "MATH")
# two illustrative "cycles" (here, two halves of the simulated data)
h <- nrow(pisa_mini) %/% 2
c1 <- social_gradient(pisa_mini[1:h, ], math, "ESCS", design = des)
c2 <- social_gradient(pisa_mini[-(1:h), ], math, "ESCS", design = des)
lsa_trend(list("2018" = c1, "2022" = c2), term = "slope", link_error = 3.5)
#> Trend in `slope` (social_gradient) across 2 cycles; baseline = 2018
#>   linking error: 3.5 (added to each change SE)
#> 
#>  cycle estimate    se change change.se    z    p
#>   2018   41.308 2.874  0.000        NA   NA   NA
#>   2022   41.454 2.426  0.146     5.137 0.03 0.98
#> 
#> change = estimate - baseline; SE includes the linking error
```
