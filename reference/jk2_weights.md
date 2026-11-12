# Build paired-jackknife (JK2) replicate weights for TIMSS and PIRLS

The IEA studies (TIMSS, PIRLS, ICCS, ICILS) do not ship replicate
weights. They ship the final weight together with a jackknife zone
(`JKZONE`) and a within-zone replicate indicator (`JKREP`, coded 0 or
1). `jk2_weights()` builds one replicate weight per zone from these
three columns, so that the data can be passed to any estimator with
`rep_method = "JK2"`.

## Usage

``` r
jk2_weights(
  data,
  weight = "TOTWGT",
  zone = "JKZONE",
  rep = "JKREP",
  prefix = "JKW"
)
```

## Arguments

- data:

  A data frame of student-level records.

- weight:

  Name of the final weight column (default `"TOTWGT"`).

- zone:

  Name of the jackknife zone column (default `"JKZONE"`).

- rep:

  Name of the within-zone replicate indicator, coded 0 or 1 (default
  `"JKREP"`).

- prefix:

  Prefix of the new columns (default `"JKW"`), which are named
  `prefix1`, `prefix2`, ... in the order of the sorted zone values.

## Value

`data` with one added replicate-weight column per zone. The names of the
new columns are stored in the attribute `"repweights"`.

## Details

For the replicate of zone \\h\\, the weight of every student in that
zone is multiplied by \\2 \times\\ `JKREP`: one half of the zone gets
twice its weight and the other half gets zero. Students in all other
zones keep their weight. With these weights the sampling variance is
\\\sum_h (\hat\theta_h - \hat\theta)^2\\, which is the `"JK2"` factor of
[`rep_factor()`](https://kevinschoenholzer.com/lsastrat/reference/rep_factor.md).

This is the construction with one replicate per zone (75 replicates for
75 zones). From TIMSS 2015 and PIRLS 2016 on, the IEA reports use two
replicates per zone and halve the sum. Both are estimators of the same
sampling variance, but they do not give identical numbers, so standard
errors from these weights can differ slightly from the published ones
for those cycles.

## References

Foy, P. & LaRoche, S. (2020). Estimating standard errors in the TIMSS
2019 results. In M. O. Martin, M. von Davier & I. V. S. Mullis (Eds.),
*Methods and Procedures: TIMSS 2019 Technical Report*. TIMSS & PIRLS
International Study Center.

## Examples

``` r
# a toy sample: 4 zones, 2 schools per zone, 3 students per school
d <- data.frame(
  JKZONE = rep(1:4, each = 6),
  JKREP  = rep(rep(0:1, each = 3), times = 4),
  TOTWGT = 1,
  score  = c(480, 510, 495, 530, 500, 520, 470, 505, 490, 515, 525, 500,
             540, 495, 510, 485, 500, 530, 505, 515, 490, 520, 480, 510)
)
d <- jk2_weights(d)
reps <- attr(d, "repweights")
lsa_model(d, ~ 1, "score", weight = "TOTWGT", repweights = reps,
          rep_method = "JK2")
#> Model: stats::lm(<PV> ~ 1)
#>   1 plausible value(s)  |  n = 24
#>   Variance: JK2, 4 replicate weights (+ PV imputation); t reference
#> 
#> 
#>             Estimate Std.Error     t  df p
#> (Intercept)      505      4.32 116.9 Inf 0
#> 
#> fitter = stats::lm
```
