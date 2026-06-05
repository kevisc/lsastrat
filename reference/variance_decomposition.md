# Between- and within-school variance decomposition

Decomposes the variance of achievement into a **between-unit** (e.g.
between-school) and a **within-unit** component, and reports the
intraclass correlation `icc` – the share of achievement variance that
lies between schools. This is a foundational stratification quantity: a
high between-school share signals a strongly differentiated, segregated
system. OECD reports it as "between-school variance as a percentage of
total".

## Usage

``` r
variance_decomposition(
  data,
  achievement,
  unit,
  weight = NULL,
  repweights = NULL,
  rep_method = c("BRR", "JK2", "JK1"),
  fay = 0.5,
  design = NULL,
  statistics = c("icc", "var_between", "var_within", "var_total"),
  level = 0.95
)
```

## Arguments

- data:

  A data frame of student-level records.

- achievement:

  Character vector of achievement plausible-value columns.

- unit:

  Name of the school / nesting-unit identifier column.

- weight:

  Name of the final student weight column. If `NULL`, equal weights are
  used (with a message).

- repweights:

  Optional character vector of replicate-weight columns.

- rep_method, fay:

  Replication design and Fay factor; see
  [`rep_factor()`](https://kevisc.github.io/lsastrat/reference/rep_factor.md).

- design:

  Optional
  [`lsa_design()`](https://kevisc.github.io/lsastrat/reference/lsa_design.md)
  bundling `weight`, `repweights`, `rep_method` and `fay`; when supplied
  it overrides those arguments.

- statistics:

  Which quantities to return: `"icc"` (between-unit share),
  `"var_between"`, `"var_within"`, `"var_total"`.

- level:

  Confidence level for the stored interval (default `0.95`).

## Value

An object of class `"variance_decomposition"` / `"lsastrat_estimate"`
(see
[lsastrat_estimate](https://kevisc.github.io/lsastrat/reference/lsastrat_estimate.md)
for methods).

## Details

The decomposition is the design-based (weighted) analysis-of-variance
decomposition, `var_total = var_between + var_within`, pooled over
plausible values with Rubin's rules and with replicate-weight standard
errors when replicate weights are supplied (see
[`pool_pv()`](https://kevisc.github.io/lsastrat/reference/pool_pv.md)).

## Examples

``` r
data(pisa_mini)
variance_decomposition(pisa_mini, paste0("PV", 1:10, "MATH"),
                       unit = "school_id", weight = "W_FSTUWT",
                       repweights = paste0("W_FSTURWT", 1:64))
#> Between/within-unit variance decomposition
#>   unit: school_id  |  128 units  |  10 plausible value(s)  |  n = 2048
#>   Variance: BRR, 64 replicate weights (+ PV imputation); t reference
#> 
#> 
#>             Estimate Std.Error     t     df        p
#> icc            0.153     0.017  9.15 1259.2  2.3e-19
#> var_between 1110.411   133.168  8.34 1561.8  1.6e-16
#> var_within  6143.320   205.537 29.89  384.4 2.7e-102
#> var_total   7253.731   228.176 31.79  517.7 8.7e-124
#> 
#> icc = between-unit share of achievement variance
```
