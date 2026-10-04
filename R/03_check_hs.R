# STEP 3: automatic checks + one summary table for the figures.
# Rscript R/03_check_hs.R
source("R/helpers.R")
root <- "results/raw/hs/algorithms"
dirs <- list.dirs(root, recursive = FALSE)
read_run <- function(d) {
  j <- jsonlite::read_json(file.path(d, "run.json"))
  s <- j$settings; cn <- j$counters
  data.frame(
    run = basename(d), variant = s$variant, algorithm = s$algorithm, measure = s$measure,
    rep = as.integer(s$rep), min_size = s$min_size, log = isTRUE(s$log),
    time_search_s = j$time_search_s, time_call_s = j$time_call_s,
    time_warmup_s = j$time_warmup_s, time_process_s = j$time_process_s,
    n_selectors = if (is.null(cn$n_selectors)) NA else cn$n_selectors,
    n_evaluated = if (is.null(cn$n_evaluated)) NA else cn$n_evaluated,
    n_below_30 = if (is.null(cn$n_below_30)) NA else cn$n_below_30,
    n_below_min_size = if (is.null(cn$n_below_min_size)) NA else cn$n_below_min_size,
    n_fit = if (is.null(cn$n_fit)) NA else cn$n_fit,
    git_commit = j$env$git$commit, lavaan = j$env$lavaan, pysubgroup = j$env$pysubgroup
  )
}
runs <- do.call(rbind, lapply(dirs, read_run))
write.csv(runs, "results/hs_runs.csv", row.names = FALSE)
topk <- function(name) read.csv(file.path(root, name, "topk.csv"), colClasses = c(subgroup = "character"))
nm <- function(variant, alg, measure = "lrt", log = 0, rep = 1, min = 50)
  sprintf("%s_%s_%s_min%d_log%d_rep%d", variant, alg, measure, min, log, rep)

checks <- list()
chk <- function(name, res) checks[[name]] <<- data.frame(
  check = name, ok = res$ok, problems = paste(res$problems, collapse = "; "),
  note = paste(res$note, collapse = "; "))

# 1. differential test: your DFS == original DFS, bit for bit, same order
ref <- topk(nm("original", "DFS"))
r <- compare_topk(topk(nm("bep", "DFS")), ref, tol = 0)
r$ok <- r$ok && identical(topk(nm("bep", "DFS"))$subgroup, ref$subgroup)
chk("bep DFS == original DFS (exact, same order)", r)
# 2. determinism across repetitions
for (alg in c("DFS", "Apriori", "BestFirst", "Beam")) {
  chk(sprintf("%s rep1 == rep2 == rep3 (exact)", alg),
      { a <- compare_topk(topk(nm("bep", alg, rep = 1)), topk(nm("bep", alg, rep = 2)), tol = 0)
        b <- compare_topk(topk(nm("bep", alg, rep = 1)), topk(nm("bep", alg, rep = 3)), tol = 0)
        list(ok = a$ok && b$ok, problems = c(a$problems, b$problems), note = NULL) })
}
# 3. the exhaustive algorithms must find the same top-10 (ties may be reordered)
for (alg in c("Apriori", "BestFirst")) {
  chk(sprintf("%s == DFS (tie-aware)", alg), compare_topk(topk(nm("bep", alg)), ref, tol = 0))
}
# 4. logging must not change the result
for (alg in c("DFS", "Apriori", "BestFirst", "Beam")) {
  chk(sprintf("%s with log == without log", alg),
      compare_topk(topk(nm("bep", alg, log = 1)), topk(nm("bep", alg)), tol = 0))
}
# 5. the exhaustive algorithms do the same number of model fits
f <- runs[runs$variant == "bep" & runs$measure == "lrt" & runs$min_size == 50 &
          runs$algorithm %in% c("DFS", "Apriori", "BestFirst"), ]
chk("DFS, Apriori, BestFirst: same number of fits",
    list(ok = length(unique(f$n_fit)) == 1,
         problems = if (length(unique(f$n_fit)) > 1) paste("fits:", paste(unique(f$n_fit), collapse = ",")) else NULL))
# Beam is heuristic: report, do not fail
b <- compare_topk(topk(nm("bep", "Beam")), ref, tol = 0)
checks[["Beam vs DFS (information only)"]] <- data.frame(
  check = "Beam vs DFS (information only)", ok = NA,
  problems = paste(b$problems, collapse = "; "), note = paste(b$note, collapse = "; "))

res <- do.call(rbind, checks)
write.csv(res, "results/hs_checks.csv", row.names = FALSE)
print(res[, c("check", "ok")], row.names = FALSE)
if (any(res$ok %in% FALSE)) stop("SOME CHECKS FAILED - see results/hs_checks.csv")
cat("\nALL CHECKS PASSED\n")
