# lsastrat 0.0.0.9000

* Initial scaffold.
* `social_gradient()`: socio-economic achievement gradient (slope, strength
  = R-squared x 100, and optional curvature) with plausible-value pooling
  (Rubin's rules) and replicate-weight variance estimation (BRR/Fay, JK2, JK1).
  Cross-validated against `intsvy::pisa.reg.pv`.
* `segregation_index()`: school segregation indices (Dissimilarity D, Gorard's
  S, isolation, Hutchens square-root, Theil's H, mutual information M) for
  social or achievement-based (PV-pooled) grouping, sharing the same
  replicate-weight variance engine. D and H cross-validated against the
  `segregation` package.
* `pool_pv()` / `rep_factor()`: the shared Rubin's-rules + replicate-weight
  variance engine, exposed for reuse.
