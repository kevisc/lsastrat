# Methods for lsastrat estimate objects

Every estimator
([`social_gradient()`](https://kevinschoenholzer.com/lsastrat/reference/social_gradient.md),
[`segregation_index()`](https://kevinschoenholzer.com/lsastrat/reference/segregation_index.md),
[`ieop()`](https://kevinschoenholzer.com/lsastrat/reference/ieop.md),
[`variance_decomposition()`](https://kevinschoenholzer.com/lsastrat/reference/variance_decomposition.md),
[`ieop_decompose()`](https://kevinschoenholzer.com/lsastrat/reference/ieop_decompose.md),
[`oaxaca_gap()`](https://kevinschoenholzer.com/lsastrat/reference/oaxaca_gap.md)
and
[`lsa_model()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_model.md))
returns an object of class `"lsastrat_estimate"` with a pooled
`coefficients` data frame (columns `estimate`, `se`, `statistic`, `df`,
`p`, `ci_lo`, `ci_hi`). These methods provide a uniform interface.

## Usage

``` r
# S3 method for class 'lsastrat_estimate'
print(x, digits = 3, ...)

# S3 method for class 'lsastrat_estimate'
summary(object, ...)

# S3 method for class 'lsastrat_estimate'
coef(object, ...)

# S3 method for class 'lsastrat_estimate'
confint(object, parm, level = 0.95, ...)

# S3 method for class 'lsastrat_estimate'
as.data.frame(x, ...)
```

## Arguments

- x, object:

  An `"lsastrat_estimate"` object.

- digits:

  Number of digits for `print`.

- ...:

  Unused.

- parm:

  Optional subset of terms (rows) for `confint`.

- level:

  Confidence level for `confint`.

## Value

`coef` a named numeric vector; `confint` a matrix; `as.data.frame` a
data frame with a `term` column; `print`/`summary` the object invisibly.
