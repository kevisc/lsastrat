# One parametric PISA-format simulator for the "recovers a known DGP" tests.
# (Realistic worked examples use the bundled pisa_mini data set instead.)
sim_lsa <- function(n = 3000, slope = 40, sd = 80, n_pv = 5, n_rep = 20,
                    seed = 1, n_schools = 60) {
  set.seed(seed)
  school <- sample(n_schools, n, replace = TRUE)
  escs <- rnorm(n)
  truth <- 500 + slope * escs
  pv <- replicate(n_pv, truth + rnorm(n, sd = sd))
  colnames(pv) <- paste0("PV", seq_len(n_pv), "MATH")
  w <- runif(n, 0.5, 2)
  rw <- replicate(n_rep, w * ifelse(runif(n) < 0.5, 1.5, 0.5))
  colnames(rw) <- paste0("W_FSTR", seq_len(n_rep))
  data.frame(school, ESCS = escs, pv, W_FSTUWT = w, rw, check.names = FALSE)
}

ach5 <- function() paste0("PV", 1:5, "MATH")
reps_of <- function(d) grep("^W_FSTR[0-9]", names(d), value = TRUE)
