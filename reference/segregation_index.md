# School segregation indices for large-scale assessment data

Computes the family of segregation indices used in educational
stratification research – measuring how unevenly student groups are
distributed across schools (or any nesting unit) – with survey-weighted
counts, plausible-value pooling for achievement-based groups, and a
choice of variance estimator: replicate weights or a clustered bootstrap
with finite-sample bias correction.

## Usage

``` r
segregation_index(
  data,
  unit,
  group = NULL,
  achievement = NULL,
  cutoff = NULL,
  indices = c("D", "S", "isolation", "Hutchens", "H", "M"),
  minority = NULL,
  weight = NULL,
  repweights = NULL,
  rep_method = c("BRR", "JK2", "JK1"),
  fay = 0.5,
  design = NULL,
  variance = c("replicate", "bootstrap", "none"),
  n_boot = 200L,
  debias = TRUE,
  boot_cluster = NULL,
  boot_seed = NULL,
  level = 0.95
)
```

## Arguments

- data:

  A data frame of student-level records.

- unit:

  Name of the school / nesting-unit identifier column.

- group:

  Name of a categorical group-membership column. Mutually exclusive with
  `achievement`/`cutoff`.

- achievement:

  Character vector of plausible-value column names, used with `cutoff`
  to define an achievement-based (academic) group.

- cutoff:

  Numeric threshold; students with achievement `< cutoff` form the
  `"below"` group.

- indices:

  Which indices to return. Any of `"D"` (dissimilarity), `"S"` (Gorard's
  segregation index), `"isolation"` (minority isolation), `"Hutchens"`
  (square-root index), `"H"` (Theil's information / entropy index) and
  `"M"` (mutual information). `H` and `M` support more than two groups;
  `D`, `S`, `isolation` and `Hutchens` compare the `minority` group to
  the rest.

- minority:

  Which group level is the minority for the binary indices. Defaults to
  the least frequent (weighted) level.

- weight:

  Name of the final student weight column. If `NULL`, equal weights are
  used (with a message).

- repweights:

  Optional character vector of replicate-weight columns (used when
  `variance = "replicate"`).

- rep_method, fay:

  Replication design and Fay factor; see
  [`rep_factor()`](https://kevinschoenholzer.com/lsastrat/reference/rep_factor.md).

- design:

  Optional
  [`lsa_design()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_design.md)
  bundling `weight`, `repweights`, `rep_method` and `fay`; when supplied
  it overrides those arguments.

- variance:

  Variance estimator: `"replicate"` (default when `repweights` are
  supplied), `"bootstrap"` (default otherwise), or `"none"` (point
  estimates only).

- n_boot:

  Number of bootstrap resamples (default 200).

- debias:

  Logical; apply bootstrap bias correction under
  `variance = "bootstrap"` (default `TRUE`).

- boot_cluster:

  Name of the column defining the stage-one bootstrap clusters (the
  primary sampling units); defaults to `unit`.

- boot_seed:

  Optional integer seed for reproducible bootstrap draws (the global RNG
  state is restored on exit).

- level:

  Confidence level for the stored interval (default `0.95`).

## Value

An object of class `"segregation"` / `"lsastrat_estimate"` (see
[lsastrat_estimate](https://kevinschoenholzer.com/lsastrat/reference/lsastrat_estimate.md)
for methods): a `coefficients` data frame (one row per index) plus
metadata.

## Details

Two ways to define the group:

- **Social segregation:** pass a categorical `group` column (e.g. an
  immigrant-background flag, or a disadvantaged/advantaged ESCS split).

- **Academic segregation:** pass `achievement` (a vector of
  plausible-value columns) together with `cutoff`; students scoring
  below the cutoff form the minority group, and the index is pooled
  across plausible values.

## Variance and bias

The entropy and dissimilarity indices (M, H, D, Gorard's S, Hutchens)
are positively biased in finite samples, and large-scale assessments –
with tens of students sampled per school across many schools – are the
worst case. With `variance = "bootstrap"` a two-stage clustered
bootstrap is used: stage one resamples whole clusters (the design level,
giving a design-correct sampling variance) and stage two resamples
students within each drawn cluster (the within-school fluctuation that
drives the finite-sample bias). The bootstrap bias estimate is then
subtracted when `debias = TRUE` (Elbers, 2023). With
`variance = "replicate"` the supplied replicate weights give the
sampling variance but no bias correction is applied; the point estimates
are then the (upward-biased) plug-in values, so bootstrap variance is
recommended when bias is a concern.

## References

Gorard, S. & Taylor, C. (2002). What is segregation? *Sociology*, 36(4).
Hutchens, R. (2004). One measure of segregation. *International Economic
Review*, 45(2). Mora, R. & Ruiz-Castillo, J. (2011). Entropy-based
segregation indices. *Sociological Methodology*, 41(1). Elbers, B.
(2023). A method for studying differences in segregation. *Sociological
Methods & Research* (R package segregation).

## Examples

``` r
data(pisa_mini)
# social segregation by immigrant background, bootstrap bias-corrected
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
