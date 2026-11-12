# Package index

## Estimators

First-class stratification and inequality quantities.

- [`social_gradient()`](https://kevinschoenholzer.com/lsastrat/reference/social_gradient.md)
  : Socio-economic achievement gradient
- [`segregation_index()`](https://kevinschoenholzer.com/lsastrat/reference/segregation_index.md)
  : School segregation indices for large-scale assessment data
- [`ieop()`](https://kevinschoenholzer.com/lsastrat/reference/ieop.md) :
  Inequality of educational opportunity (Ferreira-Gignoux)
- [`variance_decomposition()`](https://kevinschoenholzer.com/lsastrat/reference/variance_decomposition.md)
  : Between- and within-school variance decomposition

## General modelling

Fit arbitrary models, and compare across cycles.

- [`lsa_model()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_model.md)
  : Fit any model to plausible-value outcomes with replicate-weight
  inference
- [`lsa_trend()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_trend.md)
  : Trend across assessment cycles with linking error

## Decompositions

Attributing inequality to its sources.

- [`ieop_decompose()`](https://kevinschoenholzer.com/lsastrat/reference/ieop_decompose.md)
  : Shapley decomposition of inequality of educational opportunity
- [`oaxaca_gap()`](https://kevinschoenholzer.com/lsastrat/reference/oaxaca_gap.md)
  : Oaxaca-Blinder decomposition of an achievement gap

## Comparison and multiverse

Comparative and robustness analysis.

- [`lsa_by()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_by.md)
  : Run an estimator across groups (e.g. countries)
- [`equity_scatter()`](https://kevinschoenholzer.com/lsastrat/reference/equity_scatter.md)
  : Quality-equity scatter across groups
- [`lsa_multiverse()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_multiverse.md)
  : Plausible-value / weight-aware multiverse (specification-curve)
  analysis
- [`lsa_design()`](https://kevinschoenholzer.com/lsastrat/reference/lsa_design.md)
  : Bundle a survey design for reuse

## Variance engine

The shared plausible-value pooling and replicate-weight machinery.

- [`pool_pv()`](https://kevinschoenholzer.com/lsastrat/reference/pool_pv.md)
  : Pool point estimates and variances across plausible values (Rubin's
  rules)
- [`rep_factor()`](https://kevinschoenholzer.com/lsastrat/reference/rep_factor.md)
  : Replicate-weight variance factors
- [`jk2_weights()`](https://kevinschoenholzer.com/lsastrat/reference/jk2_weights.md)
  : Build paired-jackknife (JK2) replicate weights for TIMSS and PIRLS

## Methods

Accessors and plots for fitted objects.

- [`print(`*`<lsastrat_estimate>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/lsastrat_estimate.md)
  [`summary(`*`<lsastrat_estimate>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/lsastrat_estimate.md)
  [`coef(`*`<lsastrat_estimate>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/lsastrat_estimate.md)
  [`confint(`*`<lsastrat_estimate>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/lsastrat_estimate.md)
  [`as.data.frame(`*`<lsastrat_estimate>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/lsastrat_estimate.md)
  : Methods for lsastrat estimate objects
- [`tidy()`](https://kevinschoenholzer.com/lsastrat/reference/tidy.lsastrat_estimate.md)
  [`glance()`](https://kevinschoenholzer.com/lsastrat/reference/tidy.lsastrat_estimate.md)
  : Tidy an lsastrat estimate
- [`autoplot(`*`<lsastrat_estimate>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/autoplot.lsastrat.md)
  [`autoplot(`*`<social_gradient>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/autoplot.lsastrat.md)
  [`autoplot(`*`<lsastrat_by>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/autoplot.lsastrat.md)
  [`autoplot(`*`<equity_scatter>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/autoplot.lsastrat.md)
  [`autoplot(`*`<lsa_multiverse>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/autoplot.lsastrat.md)
  : ggplot2 autoplot methods
- [`plot(`*`<social_gradient>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/plot.social_gradient.md)
  : Plot a socio-economic achievement gradient
- [`plot(`*`<segregation>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/plot.segregation.md)
  : Plot a school segregation profile
- [`plot(`*`<lsastrat_by>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/plot.lsastrat_by.md)
  : Forest / caterpillar plot of an estimate across groups
- [`plot(`*`<equity_scatter>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/plot.equity_scatter.md)
  : Plot a quality-equity scatter
- [`plot(`*`<lsa_multiverse>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/plot.lsa_multiverse.md)
  : Specification-curve plot
- [`plot(`*`<lsa_trend>`*`)`](https://kevinschoenholzer.com/lsastrat/reference/plot.lsa_trend.md)
  : Plot a cross-cycle trend

## Data

- [`pisa_mini`](https://kevinschoenholzer.com/lsastrat/reference/pisa_mini.md)
  : Simulated PISA-like assessment data
