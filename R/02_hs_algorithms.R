# STEP 2: run all four algorithms (your version) on Holzinger-Swineford.
# Rscript R/02_hs_algorithms.R
source("R/config.R")
out_root <- "results/raw/hs/algorithms"

runs <- list()
add <- function(...) runs[[length(runs) + 1L]] <<- list(...)
# (1) timing runs: no logging, N_REPETITIONS each, order shuffled per repetition
for (rep in seq_len(N_REPETITIONS)) {
  block <- list()
  for (alg in ALGORITHMS) block[[alg]] <- list(variant = "bep", algorithm = alg, measure = "lrt", rep = rep, log = 0)
  block[["orig"]] <- list(variant = "original", algorithm = "DFS", measure = "lrt", rep = rep, log = 0)
  block[["wald"]] <- list(variant = "bep", algorithm = "DFS", measure = "wald", rep = rep, log = 0)
  set.seed(SEED_RUN_ORDER + rep)          # reproducible, but not always the same order
  for (b in block[sample(length(block))]) do.call(add, b)
}
# (2) one logged run per algorithm (per-candidate log, for counts and figures)
for (alg in ALGORITHMS) add(variant = "bep", algorithm = alg, measure = "lrt", rep = 1, log = 1)
# (3) logged DFS run with the hard minimum of 30 rows (shows the cost of small groups)
add(variant = "bep", algorithm = "DFS", measure = "lrt", rep = 1, log = 1, min_size = 30)

for (r in runs) {
  ms <- if (is.null(r$min_size)) HS$min_subgroup_size else r$min_size
  name <- sprintf("%s_%s_%s_min%d_log%d_rep%d", r$variant, r$algorithm, r$measure, ms, r$log, r$rep)
  out <- file.path(out_root, name)
  status <- system2(RSCRIPT, c("R/run_one.R", paste0("variant=", r$variant),
                                 paste0("algorithm=", r$algorithm), paste0("measure=", r$measure),
                                 paste0("rep=", r$rep), paste0("log=", r$log),
                                 paste0("min_size=", ms), paste0("out=", out)))
  if (status != 0) stop("run failed: ", name)
}
cat("\nAll runs done. Next: Rscript R/03_check_hs.R\n")
