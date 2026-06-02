# Simulated PISA-like assessment data

A fully **simulated**, non-disclosive data set with the structure of a
single PISA education system, used throughout the examples, tests and
vignette. It is *not* real PISA data and must not be used for
substantive inference, but it reproduces the features the package is
built to handle: plausible values, a final weight,
balanced-repeated-replication replicate weights, a socio-economic
achievement gradient, between-school clustering of disadvantage, and
circumstance-driven inequality of opportunity.

## Usage

``` r
pisa_mini
```

## Format

A data frame with 2048 rows (students in 128 schools) and 91 columns:

- school_id:

  School identifier (128 schools).

- W_FSTUWT:

  Final student weight.

- W_FSTURWT1, W_FSTURWT2, W_FSTURWT3, W_FSTURWT4, W_FSTURWT5,
  W_FSTURWT6, W_FSTURWT7, W_FSTURWT8, W_FSTURWT9, W_FSTURWT10,
  W_FSTURWT11, W_FSTURWT12, W_FSTURWT13, W_FSTURWT14, W_FSTURWT15,
  W_FSTURWT16, W_FSTURWT17, W_FSTURWT18, W_FSTURWT19, W_FSTURWT20,
  W_FSTURWT21, W_FSTURWT22, W_FSTURWT23, W_FSTURWT24, W_FSTURWT25,
  W_FSTURWT26, W_FSTURWT27, W_FSTURWT28, W_FSTURWT29, W_FSTURWT30,
  W_FSTURWT31, W_FSTURWT32, W_FSTURWT33, W_FSTURWT34, W_FSTURWT35,
  W_FSTURWT36, W_FSTURWT37, W_FSTURWT38, W_FSTURWT39, W_FSTURWT40,
  W_FSTURWT41, W_FSTURWT42, W_FSTURWT43, W_FSTURWT44, W_FSTURWT45,
  W_FSTURWT46, W_FSTURWT47, W_FSTURWT48, W_FSTURWT49, W_FSTURWT50,
  W_FSTURWT51, W_FSTURWT52, W_FSTURWT53, W_FSTURWT54, W_FSTURWT55,
  W_FSTURWT56, W_FSTURWT57, W_FSTURWT58, W_FSTURWT59, W_FSTURWT60,
  W_FSTURWT61, W_FSTURWT62, W_FSTURWT63, W_FSTURWT64:

  64 Fay (k = 0.5) BRR replicate weights, built from an order-64
  Hadamard matrix over 64 variance zones.

- PV1MATH, PV2MATH, PV3MATH, PV4MATH, PV5MATH, PV6MATH, PV7MATH,
  PV8MATH, PV9MATH, PV10MATH:

  Ten plausible values for mathematics.

- PV1READ, PV2READ, PV3READ, PV4READ, PV5READ, PV6READ, PV7READ,
  PV8READ, PV9READ, PV10READ:

  Ten plausible values for reading.

- ESCS:

  Index of economic, social and cultural status (mean ~0).

- IMMIG:

  Immigration status: `native`, `second_gen`, `first_gen`.

- parental_edu:

  Highest parental education: `below_secondary`, `secondary`,
  `tertiary`.

- books:

  Books at home: `0-25`, `26-100`, `101-200`, `>200`.

- female:

  Indicator (1 = female).

## Source

Simulated by `data-raw/pisa_mini.R`.

## Details

Baked-in features (approximate): a socio-economic gradient of ~40 score
points per ESCS unit (strength ~23%), immigrant-background students
concentrated in lower-ESCS schools, and circumstances (migration,
parental education, books) explaining ~24% of mathematics variance.
Analyse it the way you would analyse PISA: pool over the plausible
values and use the replicate weights with `rep_method = "BRR"`,
`fay = 0.5`.

## Examples

``` r
data(pisa_mini)
str(pisa_mini[, 1:6])
#> 'data.frame':    2048 obs. of  6 variables:
#>  $ school_id : chr  "S001" "S001" "S001" "S001" ...
#>  $ W_FSTUWT  : num  12.1 18.1 12.1 11.1 17.9 ...
#>  $ W_FSTURWT1: num  18.2 27.2 18.2 16.6 26.8 ...
#>  $ W_FSTURWT2: num  18.2 27.2 18.2 16.6 26.8 ...
#>  $ W_FSTURWT3: num  18.2 27.2 18.2 16.6 26.8 ...
#>  $ W_FSTURWT4: num  18.2 27.2 18.2 16.6 26.8 ...
```
