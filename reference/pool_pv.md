# Pool point estimates and variances across plausible values (Rubin's rules)

Combines per-plausible-value point estimates and their (design-based)
sampling variances into a single estimate, standard error, and
\\t\\-reference test following the multiple-imputation combining rules
of Rubin (1987).

## Usage

``` r
pool_pv(estimates, variances, level = 0.95)
```

## Arguments

- estimates:

  Numeric vector of per-PV point estimates (\\\hat\theta_p\\), length
  `m` = number of plausible values.

- variances:

  Numeric vector of per-PV *sampling* variances (\\U_p\\), same length.
  Pass zeros when no design-based variance is available (the result is
  then the imputation variance only). A non-finite entry propagates to
  an `NA` standard error rather than an error.

- level:

  Confidence level for the returned interval (default `0.95`).

## Value

A named list: `estimate`, `se`, `statistic` (estimate / se), `df` (Rubin
degrees of freedom), `p` (two-sided), `ci_lo`, `ci_hi`, `var_sampling`
(\\\bar U\\), `var_imputation` (the \\(1 + 1/m) B\\ term), and `m`.

## Details

With `m` plausible values the pooled estimate is the mean of the per-PV
estimates. The total variance is \$\$T = \bar U + (1 + 1/m) B,\$\$ where
\\\bar U\\ is the mean sampling variance (within-imputation) and \\B\\
is the between-PV variance (the imputation/measurement component).
Inference uses a \\t\\ reference with Rubin's degrees of freedom \$\$\nu
= (m - 1)\left(1 + \frac{\bar U}{(1 + 1/m) B}\right)^2,\$\$ which
correctly widens intervals when the imputation component is
non-negligible relative to the sampling component (the usual case for
the small number of plausible values, 5 or 10, in PISA/TIMSS/PIRLS).
When there is no imputation variance (a single plausible value) the
reference reduces to the normal (\\\nu = \infty\\); when there is no
sampling variance the reference is \\t\\ on \\m - 1\\ degrees of
freedom.

## References

Rubin, D. B. (1987). *Multiple Imputation for Nonresponse in Surveys*.
Wiley. Barnard, J. & Rubin, D. B. (1999). Small-sample degrees of
freedom with multiple imputation. *Biometrika*, 86(4), 948-955.

## Examples

``` r
# five plausible values, each with a sampling variance of 4
pool_pv(estimates = c(508, 511, 509, 513, 510), variances = rep(16, 5))
#> $estimate
#> [1] 510.2
#> 
#> $se
#> [1] 4.521062
#> 
#> $statistic
#> [1] 112.8496
#> 
#> $df
#> [1] 84.77266
#> 
#> $p
#> [1] 3.561279e-94
#> 
#> $ci_lo
#> [1] 501.2106
#> 
#> $ci_hi
#> [1] 519.1894
#> 
#> $var_sampling
#> [1] 16
#> 
#> $var_imputation
#> [1] 4.44
#> 
#> $m
#> [1] 5
#> 
```
