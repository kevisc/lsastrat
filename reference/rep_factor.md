# Replicate-weight variance factors

Returns the multiplier \\c\\ in the replicate-variance formula \\V = c
\sum_r (\hat\theta_r - \hat\theta_0)^2\\, for the common
large-scale-assessment replication designs.

## Usage

``` r
rep_factor(method = c("BRR", "JK2", "JK1"), n_rep, fay = 0.5)
```

## Arguments

- method:

  One of `"BRR"` (balanced repeated replication, the PISA default),
  `"JK2"` (paired jackknife, used by TIMSS/PIRLS), or `"JK1"`.

- n_rep:

  Number of replicate weights.

- fay:

  Fay's adjustment factor for BRR (PISA uses 0.5). Must lie in \\\[0,
  1)\\. Ignored for jackknife methods.

## Value

A single numeric multiplier.

## Details

- BRR/Fay: \\c = 1 / (R (1 - k)^2)\\, where `k` is `fay`. With `fay = 0`
  this is ordinary BRR (\\1/R\\); with `fay = 0.5` (PISA) it is \\4/R\\.

- JK2 (IEA paired-zone construction): \\c = 1\\.

- JK1 (single-stratum / equal-zone): \\c = (R - 1) / R\\.

## References

OECD (2009). *PISA Data Analysis Manual: SPSS and SAS, Second Edition*.
OECD Publishing. (Replicate-weight variance estimation.)

## Examples

``` r
rep_factor("BRR", n_rep = 80, fay = 0.5) # PISA: 1/20
#> [1] 0.05
rep_factor("JK2", n_rep = 75)            # TIMSS/PIRLS: 1
#> [1] 1
```
