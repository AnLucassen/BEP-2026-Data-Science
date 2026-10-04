# ONE run = one fresh R process. Called by the driver scripts, e.g.
#   Rscript R/run_one.R variant=bep algorithm=Apriori measure=lrt rep=1 out=results/raw/hs/x
# Arguments (key=value): variant (bep|original), algorithm, measure (lrt|wald),
#   min_size, depth, bw, rep, log (0|1), out (output folder)
t_process_start <- proc.time()[["elapsed"]]
source("R/helpers.R")

args <- list(variant = "bep", algorithm = "DFS", measure = "lrt",
             min_size = HS$min_subgroup_size, depth = HS$depth, bw = HS$beam_width,
             rep = 1L, log = 0L, out = "results/raw/hs/tmp")
for (a in commandArgs(trailingOnly = TRUE)) {
  kv <- strsplit(a, "=", fixed = TRUE)[[1]]
  args[[kv[1]]] <- kv[2]
}
min_size <- as.integer(args$min_size); depth <- as.integer(args$depth)
bw <- as.integer(args$bw); keep_log <- as.integer(args$log) == 1L
dir.create(args$out, recursive = TRUE, showWarnings = FALSE)

load_subgroupsem(args$variant)
dat <- hs_data()

# ---- warm-up (not timed) -----------------------------------------------------
# Everything that happens only once per process: starting Python, importing
# pysubgroup, loading lavaan's internals. Without this, the first run of a
# session looks slower for reasons that have nothing to do with the algorithm.
t_w0 <- proc.time()[["elapsed"]]
stopifnot(isTRUE(subgroupsem_ready()))
invisible(reticulate::import("pysubgroup"))
warm <- dat; warm$g <- as.integer(warm$school == "Pasteur")
invisible(lavaan::sem(HS$model, data = warm, group = "g", se = "none", warn = FALSE))
t_warmup <- proc.time()[["elapsed"]] - t_w0

# ---- the timed search ------------------------------------------------------------
subsem_options <- list(algorithm = args$algorithm, search_depth = depth,
                       max_n_subgroups = HS$result_size,
                       min_subgroup_size = min_size, bw = bw)
if (args$variant == "bep") subsem_options$keep_log <- keep_log
if (args$variant == "original" && !(args$algorithm %in% c("DFS", "SimpleDFS", "Beam"))) {
  stop("the original subgroupsem only has DFS and Beam")
}

t0 <- proc.time()[["elapsed"]]
m <- suppressWarnings(
  if (args$measure == "lrt") {
    subsem_lrt(model = HS$model, data = dat, predictors = HS$predictors,
               subsem_options = subsem_options, lavaan_options = list(warn = FALSE))
  } else {
    subsem_wald(model = HS$model_wald, data = dat, constraints = HS$wald_constraints,
                predictors = HS$predictors,
                subsem_options = subsem_options, lavaan_options = list(warn = FALSE))
  }
)
t_call <- proc.time()[["elapsed"]] - t0      # includes the one-group (baseline) fit

# ---- save --------------------------------------------------------------------
topk <- m@summary_statistics
topk$subgroup <- vapply(topk$subgroup, as.character, "")
topk <- data.frame(rank = seq_len(nrow(topk)), subgroup = topk$subgroup,
                   quality = topk$quality, size_sg = topk$size_sg)
write_precise_csv(topk, file.path(args$out, "topk.csv"))

counters <- if (methods::.hasSlot(m, "counters")) m@counters else list()
if (keep_log && methods::.hasSlot(m, "log") && nrow(m@log) > 0) {
  write_precise_csv(m@log, file.path(args$out, "log.csv"))
}
info <- list(
  settings = c(args[c("variant", "algorithm", "measure", "rep")],
               list(min_size = min_size, depth = depth, bw = bw, log = keep_log)),
  time_search_s = as.numeric(m@time_elapsed, units = "secs"),
  time_call_s = t_call,
  time_warmup_s = t_warmup,
  time_process_s = proc.time()[["elapsed"]] - t_process_start,
  counters = counters,
  env = run_info()
)
jsonlite::write_json(info, file.path(args$out, "run.json"),
                     auto_unbox = TRUE, pretty = TRUE, digits = NA)
cat(sprintf("[%s %s %s rep %s] search %.2f s, fits %s\n", args$variant, args$algorithm,
            args$measure, args$rep, info$time_search_s,
            if (is.null(counters$n_fit)) "?" else counters$n_fit))
