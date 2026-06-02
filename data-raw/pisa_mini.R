# Generates data/pisa_mini.rda: a fully SIMULATED, non-disclosive PISA-like
# data set used in examples, tests and the vignette. It is NOT real PISA data.
#
# Design: 128 schools paired into 64 variance zones (2 schools/zone), ~16
# students each (~2048 students), one education system. Baked-in features:
#   * a socio-economic achievement gradient of ~35-40 score points per ESCS unit
#   * between-school clustering of disadvantage (social segregation)
#   * circumstances (migration, parental education, books) explaining ~25-30%
#     of achievement variance (non-trivial inequality of opportunity)
#   * 10 plausible values each for mathematics and reading
#   * a final student weight and 64 Fay (k = 0.5) balanced-repeated-replication
#     replicate weights built from an order-64 Sylvester Hadamard matrix.
#
# Re-run with: Rscript data-raw/pisa_mini.R

set.seed(20240601)

n_zones <- 64L
schools_per_zone <- 2L
n_schools <- n_zones * schools_per_zone          # 128
per_school <- 16L
N <- n_schools * per_school                       # 2048

## ---- school level ---------------------------------------------------------
school <- sprintf("S%03d", seq_len(n_schools))
school_escs <- rnorm(n_schools, 0, 0.55)          # between-school SES variation
zone <- rep(seq_len(n_zones), each = schools_per_zone)
half <- rep(c(1L, 2L), n_zones)                   # pseudo-unit within zone
# unequal school selection -> base weight inversely related to size proxy
school_base_w <- exp(rnorm(n_schools, 0, 0.3)) * 12

## ---- student level --------------------------------------------------------
sch <- rep(seq_len(n_schools), each = per_school)
escs <- school_escs[sch] + rnorm(N, 0, 0.70)      # ESCS index

# migration: low-SES schools concentrate immigrant-background students
p_imm <- plogis(-1.1 - 1.3 * school_escs[sch])
immig_code <- rbinom(N, 1, p_imm) + rbinom(N, 1, p_imm * 0.5)  # 0,1,2
IMMIG <- factor(c("native", "second_gen", "first_gen")[immig_code + 1L],
                levels = c("native", "second_gen", "first_gen"))

# parental education: increases with ESCS
pe_lin <- 0.9 * escs + rnorm(N, 0, 0.8)
parental_edu <- cut(pe_lin, breaks = quantile(pe_lin, c(0, .33, .66, 1)),
                    labels = c("below_secondary", "secondary", "tertiary"),
                    include.lowest = TRUE)

# books at home: increases with ESCS
bk_lin <- 0.8 * escs + rnorm(N, 0, 0.9)
books <- cut(bk_lin, breaks = quantile(bk_lin, c(0, .25, .6, .85, 1)),
             labels = c("0-25", "26-100", "101-200", ">200"),
             include.lowest = TRUE)

female <- rbinom(N, 1, 0.5)

## ---- latent achievement ---------------------------------------------------
# true score driven by ESCS and circumstances so all three estimators return
# non-degenerate values
imm_eff <- c(native = 0, second_gen = -10, first_gen = -18)[as.character(IMMIG)]
pe_eff  <- c(below_secondary = -15, secondary = 0, tertiary = 14)[as.character(parental_edu)]
bk_eff  <- c(`0-25` = -16, `26-100` = -3, `101-200` = 6, `>200` = 16)[as.character(books)]

true_math <- 500 + 24 * escs + imm_eff + pe_eff + bk_eff - 6 * female +
  rnorm(N, 0, 66)
true_read <- 500 + 22 * escs + imm_eff + pe_eff + 0.6 * bk_eff + 10 * female +
  rnorm(N, 0, 70)

# 10 plausible values each = true score + imputation/measurement noise
pv_math <- sapply(1:10, function(i) true_math + rnorm(N, 0, 30))
pv_read <- sapply(1:10, function(i) true_read + rnorm(N, 0, 32))
colnames(pv_math) <- paste0("PV", 1:10, "MATH")
colnames(pv_read) <- paste0("PV", 1:10, "READ")

## ---- final weight ---------------------------------------------------------
W_FSTUWT <- school_base_w[sch] * exp(rnorm(N, 0, 0.25))

## ---- Fay BRR replicate weights (order-64 Sylvester Hadamard) ---------------
hadamard <- function(k) {
  H <- matrix(1)
  for (i in seq_len(k)) H <- rbind(cbind(H, H), cbind(H, -H))
  H
}
Hmat <- hadamard(6L)                              # 64 x 64, entries +/-1
fay <- 0.5
repw <- matrix(0, N, n_zones)
for (r in seq_len(n_zones)) {
  sign_school <- Hmat[r, zone]                    # +/-1 per school
  up <- (sign_school > 0)
  # within a zone the two pseudo-units get opposite treatment
  fac_school <- ifelse(half == 1L,
                       ifelse(up, 2 - fay, fay),
                       ifelse(up, fay, 2 - fay))
  repw[, r] <- W_FSTUWT * fac_school[sch]
}
colnames(repw) <- paste0("W_FSTURWT", seq_len(n_zones))

pisa_mini <- data.frame(
  school_id = school[sch],
  W_FSTUWT = W_FSTUWT,
  repw,
  pv_math, pv_read,
  ESCS = escs,
  IMMIG = IMMIG,
  parental_edu = parental_edu,
  books = books,
  female = female,
  check.names = FALSE,
  stringsAsFactors = FALSE
)

## ---- sanity checks (printed) ----------------------------------------------
fit <- lm(rowMeans(pv_math) ~ escs, weights = W_FSTUWT)
cat(sprintf("n = %d, schools = %d, columns = %d\n", nrow(pisa_mini),
            n_schools, ncol(pisa_mini)))
cat(sprintf("gradient slope (math~escs) ~ %.1f pts/unit, R^2 ~ %.3f\n",
            coef(fit)[2], summary(fit)$r.squared))
fit_c <- lm(rowMeans(pv_math) ~ IMMIG + parental_edu + books, weights = W_FSTUWT)
cat(sprintf("circumstance R^2 (IOp upper bound) ~ %.3f\n",
            summary(fit_c)$r.squared))

save(pisa_mini, file = "data/pisa_mini.rda", compress = "xz")
cat("wrote data/pisa_mini.rda (", round(file.size("data/pisa_mini.rda")/1024), "KB)\n")
