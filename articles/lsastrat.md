# Getting started with lsastrat

``` r

library(lsastrat)
data(pisa_mini)
```

## What lsastrat does

`lsastrat` turns large-scale assessment (LSA) data — PISA, TIMSS, PIRLS
— into the stratification and inequality quantities that education
researchers report, and returns them as first-class objects. It handles
the two features that make LSA data awkward:

- **Plausible values (PVs).** Achievement is reported as several imputed
  draws, not a single score. Every estimator is computed on each PV and
  the results are combined with Rubin’s (1987) rules, so the measurement
  uncertainty enters the standard error.
- **Replicate weights.** Complex sampling means the variance must be
  estimated from replicate weights (BRR/Fay for PISA; JK2 for
  TIMSS/PIRLS) or, for the segregation indices, a clustered bootstrap.

Inference uses a *t* reference with Rubin degrees of freedom (not the
normal), which matters because LSA studies provide only 5 or 10
plausible values.

All examples use `pisa_mini`, a **fully simulated** PISA-like data set
bundled with the package (it is *not* real PISA data). It has 10
plausible values each for mathematics and reading
(`PV1MATH`…`PV10MATH`), a final weight (`W_FSTUWT`), 64 Fay BRR
replicate weights (`W_FSTURWT1`…`W_FSTURWT64`), and background
variables.

``` r

reps <- paste0("W_FSTURWT", 1:64)
math <- paste0("PV", 1:10, "MATH")
```

## The socio-economic gradient

[`social_gradient()`](https://kevisc.github.io/lsastrat/reference/social_gradient.md)
follows the OECD definition: the **slope** is the score-point change per
one unit of the socio-economic index (ESCS), the **strength** is the
percentage of achievement variance it explains (R² × 100), and
**curvature** is an optional quadratic term.

``` r

g <- social_gradient(pisa_mini, achievement = math, escs = "ESCS",
                     weight = "W_FSTUWT", repweights = reps)
g
#> Socio-economic achievement gradient
#>   SES index: ESCS   |   10 plausible value(s)   |   n = 2048
#>   Variance:  BRR, 64 replicate weights (+ PV imputation); t reference
#> 
#> 
#>           Estimate Std.Error     t    df       p
#> slope       41.357     1.831 22.59 399.4 2.1e-73
#> strength    20.189     1.799 11.22 389.1 1.7e-25
#> curvature    1.025     1.597  0.64 406.7 5.2e-01
#> 
#> slope = score points per 1 unit of ESCS; strength = % variance explained (R^2 x 100)
```

The result behaves like a model object:

``` r

coef(g)
#>     slope  strength curvature 
#> 41.357302 20.188700  1.025083
confint(g)
#>               2.5 %    97.5 %
#> slope     37.758539 44.956065
#> strength  16.651036 23.726363
#> curvature -2.113944  4.164111
```

``` r

plot(g)
```

![](lsastrat_files/figure-html/gradient-plot-1.png)

## School segregation

[`segregation_index()`](https://kevisc.github.io/lsastrat/reference/segregation_index.md)
reports the family of indices used in stratification research. Pass a
categorical `group` for **social** segregation:

``` r

segregation_index(pisa_mini, unit = "school_id", group = "IMMIG",
                  weight = "W_FSTUWT", variance = "bootstrap",
                  n_boot = 99, boot_seed = 1)
#> Segregation indices (social segregation)
#>   unit: school_id  |  128 units  |  3 group(s)  |  minority: first_gen
#>   Variance: clustered bootstrap (B=99, cluster=school_id), bias-corrected
#> 
#> 
#>           Estimate Std.Error     t  df       p
#> D            0.578     0.037 15.45 Inf 7.8e-54
#> S            0.554     0.040 13.83 Inf 1.7e-43
#> isolation    0.097     0.027  3.55 Inf 3.8e-04
#> Hutchens     0.362     0.036  9.97 Inf 2.2e-23
#> H            0.095     0.017  5.50 Inf 3.9e-08
#> M            0.074     0.016  4.59 Inf 4.3e-06
```

The entropy and dissimilarity indices are upward-biased when schools are
small — exactly the LSA case. With `variance = "bootstrap"` a two-stage
clustered bootstrap estimates and removes that bias (`debias = TRUE`)
and gives a design-correct standard error. With replicate weights you
can instead use them directly (no bias correction):

``` r

segregation_index(pisa_mini, unit = "school_id", group = "IMMIG",
                  weight = "W_FSTUWT", repweights = reps,
                  indices = c("D", "H", "M"))
#> Segregation indices (social segregation)
#>   unit: school_id  |  128 units  |  3 group(s)  |  minority: first_gen
#>   Variance: BRR, 64 replicate weights; t reference
#> 
#> 
#>   Estimate Std.Error     t  df       p
#> D    0.658     0.040 16.47 Inf 6.2e-61
#> H    0.157     0.012 13.12 Inf 2.5e-39
#> M    0.122     0.011 11.39 Inf 4.8e-30
```

For **academic** segregation, define the group by an achievement
threshold; the index is then pooled across plausible values:

``` r

segregation_index(pisa_mini, unit = "school_id", achievement = math,
                  cutoff = 480, indices = c("D", "H"),
                  variance = "bootstrap", n_boot = 99, boot_seed = 1)
#> No `weight` supplied; using equal weights.
#> Segregation indices (academic segregation)
#>   unit: school_id  |  128 units  |  2 group(s)  |  minority: below
#>   Variance: clustered bootstrap (B=99, cluster=school_id), bias-corrected (+ PV imputation)
#> 
#> 
#>   Estimate Std.Error    t    df       p
#> D    0.218     0.026 8.39 109.0 1.9e-13
#> H    0.052     0.019 2.83 475.3 4.9e-03
```

## Inequality of educational opportunity

[`ieop()`](https://kevisc.github.io/lsastrat/reference/ieop.md)
implements the Ferreira–Gignoux (2014) decomposition: the share of
achievement variance explained by pre-determined **circumstances**.

``` r

ieop(pisa_mini, achievement = math,
     circumstances = c("IMMIG", "parental_edu", "books"),
     weight = "W_FSTUWT", repweights = reps)
#> Inequality of educational opportunity (Ferreira-Gignoux)
#>   10 plausible value(s)  |  n = 2048  |  3 circumstance(s): IMMIG, parental_edu, books
#>   Variance: BRR, 64 replicate weights (+ PV imputation); t reference
#> 
#> 
#>               Estimate Std.Error     t     df        p
#> iop              0.209     0.018 11.79  612.6  4.6e-29
#> iop_adj          0.206     0.018 11.58  610.7  3.7e-28
#> explained_var 1518.225   143.167 10.60 1204.1  3.5e-25
#> total_var     7253.731   228.176 31.79  517.7 8.7e-124
#> 
#> iop = share of achievement variance explained by circumstances (raw R^2, upper bound); iop_adj = df-adjusted
```

The raw `iop` is the regression R² and is an **upper bound** — it
inflates as the circumstance set grows. `iop_adj` is the
degrees-of-freedom adjusted version; prefer it, and treat `iop` as the
ceiling. `explained_var` is the absolute inequality of opportunity
(variance of predicted scores) and `total_var` the total achievement
variance.

## Where it fits

`lsastrat` complements rather than replaces general LSA packages such as
`EdSurvey`, `intsvy`, `BIFIEsurvey`, `RALSA` and OECD’s `Rrepest`, which
provide the generic estimators but leave these stratification quantities
to be assembled by hand. The estimators are cross-validated against
[`intsvy::pisa.reg.pv()`](https://rdrr.io/pkg/intsvy/man/pisa.reg.pv.html),
the `segregation` package, and a weighted regression R². \`\`\`
