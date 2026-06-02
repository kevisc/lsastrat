---
title: "lsastrat: Stratification and inequality metrics for large-scale assessment data in R"
tags:
  - R
  - education
  - large-scale assessment
  - PISA
  - social stratification
  - educational inequality
  - survey statistics
  - plausible values
authors:
  - name: Kevin Schoenholzer
    orcid: 0000-0001-9892-5869
    affiliation: 1
affiliations:
  - name: Institute for Information and Communication Policy (IICP), Università della Svizzera italiana, Lugano, Switzerland
    index: 1
date: 1 June 2026
bibliography: paper.bib
---

# Summary

International large-scale assessments (LSAs) such as the Programme for
International Student Assessment (PISA), the Trends in International Mathematics
and Science Study (TIMSS) and the Progress in International Reading Literacy
Study (PIRLS) are a primary evidence base for research on educational
inequality and social stratification. Their analysis is complicated by two
features: achievement is reported as a set of *plausible values* (multiple
imputations of a latent proficiency) rather than a single score, and the
complex sampling design requires variance to be estimated from *replicate
weights* rather than naïve formulae. `lsastrat` is an R [@rcore] package that
computes the stratification and inequality quantities educational researchers
report — the socio-economic achievement gradient, school segregation indices,
and the inequality of educational opportunity — as first-class, correctly
pooled and design-based estimates, on a single shared variance engine.

# Statement of need

The methodological contribution of `lsastrat` is to package, with correct
plausible-value pooling and replicate-weight variance, three families of
stratification quantities that researchers currently re-derive by hand from
generic regression output:

1. **The socio-economic achievement gradient** [@oecd2023pisa]: the slope of
   achievement on the index of economic, social and cultural status, its
   strength (the percentage of variance explained, $R^2 \times 100$), and its
   curvature.
2. **School segregation indices**: the dissimilarity index, Gorard's
   segregation index [@gorard2002], the isolation index, the Hutchens
   square-root index [@hutchens2004], and the entropy-based Theil's $H$ and
   mutual information $M$ [@mora2011], for either social grouping or
   achievement-based ("academic") grouping pooled across plausible values.
3. **Inequality of educational opportunity** [@ferreira2014]: the share of
   achievement variance attributable to pre-determined circumstances, with the
   variance used as the inequality index because it is ordinally invariant
   under the affine standardisation of test scores.

Existing R tools occupy adjacent niches but leave this gap. `EdSurvey`
[@edsurvey], `intsvy` [@intsvy], `BIFIEsurvey` [@bifiesurvey] and OECD's
`Rrepest` [@rrepest] correctly handle plausible values and replicate weights,
but expose only generic estimators (means, regressions, correlations,
gap tests); the gradient, segregation and opportunity measures must be
assembled by the analyst. The `segregation` package [@elbers2023] implements
the index family and a finite-sample bias correction, but for residential and
occupational data: it has no plausible-value pooling and no survey
replicate-weight machinery. `lsastrat` is, to our knowledge, the first package
to emit all three quantity families as labelled outputs with LSA-appropriate
inference.

Two design choices target methodological correctness. First, pooled inference
uses a Rubin $t$ reference with Barnard–Rubin degrees of freedom
[@rubin1987; @barnard1999] rather than the normal; with the 5–10 plausible
values typical of LSAs this materially widens confidence intervals that a
normal reference understates. Second, the entropy and dissimilarity segregation
indices are positively biased when schools are small — the standard LSA case of
a few dozen sampled students per school — so `lsastrat` offers a two-stage
clustered bootstrap that resamples schools (for a design-correct sampling
variance) and students within them (to estimate and remove the finite-sample
bias) [@elbers2023]. The bias correction is applied only to the segregation
indices, which are subject to this small-cell bias; the gradient and the
opportunity decomposition are not.

The estimators are cross-validated against established implementations: the
socio-economic gradient reproduces `intsvy::pisa.reg.pv`, the dissimilarity and
Theil's $H$ indices match the `segregation` package, and the relative
inequality of opportunity matches a weighted regression $R^2$. A bundled,
fully simulated data set (`pisa_mini`) makes every example and the test suite
reproducible without access to restricted assessment microdata.

# Example

```r
library(lsastrat)
data(pisa_mini)
reps <- paste0("W_FSTURWT", 1:64)

# socio-economic gradient (slope, strength, curvature)
social_gradient(pisa_mini, paste0("PV", 1:10, "MATH"), "ESCS",
                weight = "W_FSTUWT", repweights = reps)

# bias-corrected school segregation by immigrant background
segregation_index(pisa_mini, unit = "school_id", group = "IMMIG",
                  weight = "W_FSTUWT", variance = "bootstrap")

# inequality of educational opportunity
ieop(pisa_mini, paste0("PV", 1:10, "MATH"),
     circumstances = c("IMMIG", "parental_edu", "books"),
     weight = "W_FSTUWT", repweights = reps)
```

Each call returns an object with a common interface (`coef`, `confint`,
`as.data.frame`, `plot`), pooling over plausible values and propagating both the
sampling and the imputation components of variance.

# Acknowledgements

This research was supported by Università della Svizzera italiana (USI Lugano)
and by the Swiss National Science Foundation under grant 205177. We thank the
maintainers of `intsvy` and `segregation`, against which `lsastrat` is
cross-validated.

# References
