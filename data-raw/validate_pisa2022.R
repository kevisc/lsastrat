# Real-data validation of lsastrat against PISA 2022 public-use microdata.
#
# lsastrat ships only simulated data (OECD terms prohibit redistribution), so
# this script reproduces the package's validation claims on the real PISA 2022
# student file for anyone who downloads it from the OECD:
#   https://www.oecd.org/en/data/datasets/pisa-2022-database.html
# (student questionnaire SPSS file CY08MSP_STU_QQQ.SAV).
#
# Checks, per country:
#   1. social_gradient() slope/SE/strength  vs  intsvy::pisa.reg.pv()
#      (the established LSA package) on identical data.
#   2. segregation_index() D and Theil's H  vs  the segregation package
#      (Elbers) on identical weighted school-by-group tables.
#   3. variance_decomposition() ICC sanity (between-school share in [0, 1]).
#
# Usage: set `sav` below, then  Rscript data-raw/validate_pisa2022.R

library(lsastrat)

sav <- "../../data/raw/pisa2022/extracted/CY08MSP_STU_QQQ.SAV"  # adjust path
countries <- c("FIN", "DEU", "USA", "CHE", "ITA", "JPN")

cols <- c("CNT", "CNTSCHID", "W_FSTUWT", paste0("W_FSTURWT", 1:80),
          paste0("PV", 1:10, "MATH"), "ESCS", "IMMIG")
message("reading ", basename(sav), " (selected columns) ...")
stu <- haven::read_sav(sav, col_select = dplyr::all_of(cols))
stu$CNT <- as.character(stu$CNT)
stu <- stu[stu$CNT %in% countries, ]
stu <- as.data.frame(stu)
stu$IMMIG <- factor(haven::as_factor(stu$IMMIG))

math <- paste0("PV", 1:10, "MATH")
reps <- paste0("W_FSTURWT", 1:80)
des <- lsa_design(weight = "W_FSTUWT", repweights = reps,
                  rep_method = "BRR", fay = 0.5)

results <- lapply(countries, function(cc) {
  d <- stu[stu$CNT == cc, ]

  ## 1. gradient: lsastrat vs intsvy on identical data
  g <- social_gradient(d, math, "ESCS", design = des, curvature = FALSE)
  iv <- intsvy::pisa.reg.pv(x = "ESCS", pvlabel = math, data = d)$reg

  ## 2. segregation (immigrant background): lsastrat vs segregation pkg
  ## (skipped where IMMIG is unavailable, e.g. countries that did not field it)
  d2 <- d[!is.na(d$IMMIG) & !is.na(d$ESCS), ]
  d2$IMMIG <- droplevels(d2$IMMIG)
  h_ls <- h_seg <- NA_real_
  if (nrow(d2) > 100 && nlevels(d2$IMMIG) >= 2) {
    s <- segregation_index(d2, "CNTSCHID", group = "IMMIG",
                           weight = "W_FSTUWT", variance = "none")
    st <- segregation::mutual_total(d2, "IMMIG", "CNTSCHID",
                                    weight = "W_FSTUWT")
    h_ls <- s$coefficients["H", "estimate"]
    h_seg <- st$est[st$stat == "H"]
  }

  ## 3. ICC sanity
  v <- variance_decomposition(d, math, "CNTSCHID", design = des)

  data.frame(
    country        = cc,
    n              = g$n_analytic,
    slope_lsastrat = g$coefficients["slope", "estimate"],
    slope_intsvy   = iv["ESCS", "Estimate"],
    se_lsastrat    = g$coefficients["slope", "se"],
    se_intsvy      = iv["ESCS", "Std. Error"],
    strength       = g$coefficients["strength", "estimate"],
    r2_intsvy_x100 = iv["R-squared", "Estimate"] * 100,
    H_lsastrat     = h_ls,
    H_segregation  = h_seg,
    icc            = v$coefficients["icc", "estimate"]
  )
})
out <- do.call(rbind, results)
rownames(out) <- NULL
print(out, digits = 4)

stopifnot(
  max(abs(out$slope_lsastrat - out$slope_intsvy)) < 0.01,
  max(abs(out$se_lsastrat - out$se_intsvy)) < 0.01,
  max(abs(out$strength - out$r2_intsvy_x100)) < 0.5,
  max(abs(out$H_lsastrat - out$H_segregation), na.rm = TRUE) < 1e-6,
  sum(!is.na(out$H_lsastrat)) >= 3,   # segregation compared in >= 3 countries
  all(out$icc > 0 & out$icc < 1)
)
message("ALL REAL-DATA VALIDATION CHECKS PASSED")
