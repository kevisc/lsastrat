# Bundle a survey design for reuse

A lightweight container for the weighting/replication arguments shared
by every estimator, so they need not be repeated on each call. Pass the
result as `design =` to any estimator, to
[`lsa_model()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_model.md),
or to
[`lsa_multiverse()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_multiverse.md).

## Usage

``` r
lsa_design(weight = NULL, repweights = NULL, rep_method = "BRR", fay = 0.5)
```

## Arguments

- weight:

  Name of the final student weight column.

- repweights:

  Optional character vector of replicate-weight columns.

- rep_method:

  Replication design: `"BRR"` (PISA), `"JK2"` (TIMSS, PIRLS) or `"JK1"`.
  PIAAC names the method of each country in the variable `VEMETHOD`.

- fay:

  Fay factor for BRR; see
  [`rep_factor()`](https://kevinschoenholzer.com/lsastrat/reference/rep_factor.md).

## Value

An object of class `"lsa_design"`.

## Examples

``` r
lsa_design(weight = "W_FSTUWT", repweights = paste0("W_FSTURWT", 1:64))
#> $weight
#> [1] "W_FSTUWT"
#> 
#> $repweights
#>  [1] "W_FSTURWT1"  "W_FSTURWT2"  "W_FSTURWT3"  "W_FSTURWT4"  "W_FSTURWT5" 
#>  [6] "W_FSTURWT6"  "W_FSTURWT7"  "W_FSTURWT8"  "W_FSTURWT9"  "W_FSTURWT10"
#> [11] "W_FSTURWT11" "W_FSTURWT12" "W_FSTURWT13" "W_FSTURWT14" "W_FSTURWT15"
#> [16] "W_FSTURWT16" "W_FSTURWT17" "W_FSTURWT18" "W_FSTURWT19" "W_FSTURWT20"
#> [21] "W_FSTURWT21" "W_FSTURWT22" "W_FSTURWT23" "W_FSTURWT24" "W_FSTURWT25"
#> [26] "W_FSTURWT26" "W_FSTURWT27" "W_FSTURWT28" "W_FSTURWT29" "W_FSTURWT30"
#> [31] "W_FSTURWT31" "W_FSTURWT32" "W_FSTURWT33" "W_FSTURWT34" "W_FSTURWT35"
#> [36] "W_FSTURWT36" "W_FSTURWT37" "W_FSTURWT38" "W_FSTURWT39" "W_FSTURWT40"
#> [41] "W_FSTURWT41" "W_FSTURWT42" "W_FSTURWT43" "W_FSTURWT44" "W_FSTURWT45"
#> [46] "W_FSTURWT46" "W_FSTURWT47" "W_FSTURWT48" "W_FSTURWT49" "W_FSTURWT50"
#> [51] "W_FSTURWT51" "W_FSTURWT52" "W_FSTURWT53" "W_FSTURWT54" "W_FSTURWT55"
#> [56] "W_FSTURWT56" "W_FSTURWT57" "W_FSTURWT58" "W_FSTURWT59" "W_FSTURWT60"
#> [61] "W_FSTURWT61" "W_FSTURWT62" "W_FSTURWT63" "W_FSTURWT64"
#> 
#> $rep_method
#> [1] "BRR"
#> 
#> $fay
#> [1] 0.5
#> 
#> attr(,"class")
#> [1] "lsa_design"
```
