# STEP 1: does the ORIGINAL subgroupsem reproduce the published numbers?
# Rscript R/01_hs_reproduce.R
source("R/config.R")
out_root <- "results/raw/hs/reproduce"
run <- function(measure, rep) {
  out <- file.path(out_root, sprintf("original_DFS_%s_rep%d", measure, rep))
  status <- system2(RSCRIPT, c("R/run_one.R", "variant=original", "algorithm=DFS",
                                 paste0("measure=", measure), paste0("rep=", rep),
                                 paste0("out=", out)))
  if (status != 0) stop("run failed: ", out)
  read.csv(file.path(out, "topk.csv"), colClasses = c(subgroup = "character"))
}
source("R/helpers.R")
ref <- read.csv("reference/hs_reference.csv")
rows <- list()
for (measure in c("lrt", "wald")) {
  r1 <- run(measure, 1); r2 <- run(measure, 2)
  r <- ref[ref$measure == measure, ]
  # (a) same as the reference values (5 decimals in the reference -> tol 1e-6 rel.)
  cmp_ref <- compare_topk(r1, r, tol = 1e-6, key = "size_sg")
  # (b) deterministic: two runs in two processes give bit-identical output
  cmp_det <- compare_topk(r1, r2, tol = 0)
  rows[[measure]] <- data.frame(
    measure = measure,
    matches_reference = cmp_ref$ok,
    deterministic = cmp_det$ok && identical(r1$subgroup, r2$subgroup),
    problems = paste(c(cmp_ref$problems, cmp_det$problems), collapse = "; "),
    note = paste(c(cmp_ref$note), collapse = "; ")
  )
  r1$measure <- measure
  write_precise_csv(r1, sprintf("results/hs_reproduced_%s.csv", measure))
}
res <- do.call(rbind, rows)
write.csv(res, "results/hs_reproduction_check.csv", row.names = FALSE)
print(res)
if (!all(res$matches_reference & res$deterministic)) {
  stop("REPRODUCTION FAILED - fix this before measuring anything")
}
cat("\nREPRODUCTION OK\n")
