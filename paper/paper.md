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

Existing R tools occupy adjacent niches but leave this gap (Table 1).
`EdSurvey` [@edsurvey], `intsvy` [@intsvy] and OECD's `Rrepest` [@rrepest]
pool plausible values and replicate weights correctly, but expose fixed menus
of generic estimators (means, correlations, regressions, two-group gap
tests): the gradient's strength and curvature, every segregation index, and
the opportunity decomposition must still be derived by hand, and `intsvy`
reports estimates and standard errors without degrees of freedom, so the
small-$m$ imputation uncertainty never reaches the reference distribution.
`BIFIEsurvey` [@bifiesurvey] goes furthest: `BIFIE.by` applies a user-written
statistic with full plausible-value and replicate inference. Two limits
remain. First, the user must then implement the index and decomposition
mathematics themselves -- precisely the error-prone step a domain package
should remove. Second, and structurally, a replicate-weight loop cannot
estimate the finite-sample bias of segregation indices at all: bias
estimation requires re-sampling students within schools, a different
resampling scheme from re-weighting by design replicates, which is why
`lsastrat` nests a two-stage clustered bootstrap inside the Rubin pooling.
The `segregation` package [@elbers2023] implements the index family with a
bootstrap bias correction, but for residential and occupational data: it has
no plausible values and no design weights, so its correction cannot be
combined with LSA inference. `lsastrat` is, to our knowledge, the first package
to emit all three quantity families as labelled outputs with LSA-appropriate
inference.

: Capabilities of related packages. PV = plausible values, RW = replicate
weights. []{#tbl:compare}

| Capability                                          | intsvy | EdSurvey | BIFIEsurvey | segregation | lsastrat |
|:----------------------------------------------------|:------:|:--------:|:-----------:|:-----------:|:--------:|
| PV pooling + RW variance (generic estimators)       | yes    | yes      | yes         | no          | yes      |
| Gradient (slope, strength, curvature) as output     | no     | no       | no          | --          | yes      |
| School segregation indices (D, S, Hutchens, H, M)   | no     | no       | no          | yes         | yes      |
| Segregation bias correction nested in PV pooling    | no     | no       | no          | no PV/RW    | yes      |
| IOp (Ferreira--Gignoux) + Shapley decomposition     | no     | no       | no          | no          | yes      |
| Oaxaca--Blinder gap with PV/RW inference            | no     | no       | no          | no          | yes      |
| Specification-curve multiverse over PVs/weights     | no     | no       | no          | no          | yes      |
| Arbitrary model fitter on PV outcomes               | OLS/logit | selected models | user function | --   | any fitter |

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

Around these core estimators the package adds the operations comparative
stratification research repeatedly needs: decompositions of the quantities
(between- and within-school variance, a Shapley decomposition of the inequality
of opportunity into individual circumstances, and Oaxaca-Blinder achievement-gap
decomposition), a wrapper that runs any estimator across countries or subgroups
into one comparable table, and a plausible-value/replicate-weight aware
specification-curve ("multiverse") engine for assessing how robust a finding is
to defensible analytic choices. All results share one class with `coef`,
`confint`, base-graphics and \pkg{ggplot2} `autoplot` methods.

For the working researcher this collapses a substantial amount of error-prone
boilerplate. A design-correct ESCS gradient for one country implies 810
weighted regressions (10 plausible values $\times$ 81 weights) pooled with
Rubin's rules; existing packages automate the regression but leave the
gradient, the indices, their pooling and the small-$m$ degrees of freedom to
the analyst. In `lsastrat` each quantity is one call, a cross-country
comparison is one `lsa_by()` call, and `tidy()` methods feed tables and
figures directly.

The estimators are validated at two levels. The test suite cross-validates
against established implementations: the gradient reproduces
`intsvy::pisa.reg.pv`, the segregation indices match the `segregation`
package, and the relative inequality of opportunity matches a weighted
regression $R^2$. A reproducible script (`data-raw/validate_pisa2022.R`)
repeats these checks on the official PISA 2022 public-use microdata for six
education systems: gradient slopes, standard errors and explained variance
agree with `intsvy` to better than 0.01 score points, Theil's $H$ agrees with
`segregation` to within $10^{-6}$, and the estimated between-school variance
shares recover the familiar contrast between comprehensive and tracked systems
(0.12 in Finland vs 0.47 in Germany). A bundled, fully simulated data set
(`pisa_mini`) keeps every example and test reproducible without access to
restricted microdata.

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
