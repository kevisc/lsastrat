# Contributing to lsastrat

Thanks for your interest in improving **lsastrat**. Contributions of all
kinds are welcome: bug reports, documentation fixes, methodological
discussion, and code.

## Reporting a bug or asking a question

- Search the [issue tracker](https://github.com/kevisc/lsastrat/issues)
  first.
- For a bug, please open an issue with a minimal **reprex** ([reprex
  package](https://reprex.tidyverse.org)) — a small, self-contained
  example (the bundled `pisa_mini` data set is ideal) that reproduces
  the problem, plus the output of
  [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html).
- For usage questions or methodological discussion, open a
  [Discussion](https://github.com/kevisc/lsastrat/discussions) or a
  question issue. Because the package implements specific
  survey-statistics methods, please point to the relevant formula or
  reference where you can.

## Contributing code

1.  Fork the repository and create a feature branch off `main`.

2.  Follow the existing style (roughly the tidyverse style guide:
    two-space indentation, `snake_case`, `<-` assignment). Keep
    functions small and documented with **roxygen2**.

3.  Add or update **testthat** tests for any change in behaviour. New
    estimators or variance code should include a test that recovers a
    known value or cross-validates against an established package where
    possible.

4.  Run the checks locally before opening a pull request:

    ``` r

    devtools::document()   # regenerate man/ and NAMESPACE
    devtools::test()       # run the test suite
    devtools::check()      # R CMD check
    ```

5.  Update `NEWS.md` with a bullet describing user-facing changes.

6.  Open a pull request describing the change and the motivation. Link
    any related issue.

## Methods changes

lsastrat aims to be methodologically defensible. If you change how a
quantity is estimated (pooling, variance, bias correction, a new index),
please include in the pull request: the reference it follows, and either
a simulation showing the estimator recovers the target or a cross-check
against another implementation.

## Code of conduct

Please note that this project is released with a [Contributor Code of
Conduct](https://kevisc.github.io/lsastrat/CODE_OF_CONDUCT.md). By
participating you agree to abide by its terms.
