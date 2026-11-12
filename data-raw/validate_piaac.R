# Real-data check of lsastrat on PIAAC Cycle 1 public-use files.
#
# PIAAC is an adult survey. It has ten plausible values per domain and 80
# replicate weights, and the replication method differs by country (the
# variable VEMETHOD names it). This script shows that the same lsastrat calls
# that serve PISA, TIMSS and PIRLS also serve PIAAC.
#
# Data: the OECD public-use CSV files, one per country, for example
#   prgdeup1.csv (Germany, JK1) and prgitap1.csv (Italy, JK2).
# The OECD terms do not allow redistribution, so the files are not shipped.
#
# Check: the national mean in numeracy and literacy, with its standard error,
# against the means the OECD published for Cycle 1 (OECD Skills Outlook 2013).
#   Germany: numeracy 271.7 (1.0), literacy 269.8 (0.9)
#   Italy:   numeracy 247.1 (1.1), literacy 250.5 (1.1)
#
# Usage: set `dir` below, then  Rscript data-raw/validate_piaac.R

library(lsastrat)

dir <- "../../data/raw/piaac"  # adjust path
files <- c(Germany = "prgdeup1.csv", Italy = "prgitap1.csv")

published <- list(
  Germany = c(NUM = 271.7, LIT = 269.8),
  Italy   = c(NUM = 247.1, LIT = 250.5)
)

keep <- c(paste0("PVNUM", 1:10), paste0("PVLIT", 1:10),
          "SPFWT0", paste0("SPFWT", 1:80), "VEMETHOD")

ok <- TRUE
for (country in names(files)) {
  path <- file.path(dir, files[[country]])
  header <- names(utils::read.csv(path, nrows = 1))
  classes <- ifelse(header %in% keep, NA, "NULL")
  d <- utils::read.csv(path, colClasses = classes,
                       na.strings = c("", "NA", "."))
  for (v in setdiff(names(d), "VEMETHOD")) {
    d[[v]] <- suppressWarnings(as.numeric(d[[v]]))
  }
  d <- d[is.finite(d$SPFWT0) & d$SPFWT0 > 0 & is.finite(d$PVNUM1), ]
  method <- unique(d$VEMETHOD)
  stopifnot(length(method) == 1L, method %in% c("JK1", "JK2", "BRR"))
  design <- lsa_design(weight = "SPFWT0", repweights = paste0("SPFWT", 1:80),
                       rep_method = method)

  message(country, ": n = ", nrow(d), ", replication method ", method)
  for (domain in c("NUM", "LIT")) {
    fit <- lsa_model(d, ~ 1, paste0("PV", domain, 1:10), design = design)
    est <- fit$coefficients[1, "estimate"]
    se <- fit$coefficients[1, "se"]
    target <- published[[country]][[domain]]
    hit <- abs(est - target) < 0.05
    ok <- ok && hit
    message(sprintf("  mean %s: %.1f (SE %.2f)   published %.1f   %s",
                    domain, est, se, target, if (hit) "ok" else "MISMATCH"))
  }
}

if (!ok) stop("At least one PIAAC mean differs from the published value.")
message("All PIAAC means match the published values.")
