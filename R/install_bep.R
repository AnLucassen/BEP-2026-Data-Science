# Re-run after EVERY change in pkg/subgroupsem:  Rscript R/install_bep.R
dir.create("lib/bep", recursive = TRUE, showWarnings = FALSE)
install.packages("pkg/subgroupsem", repos = NULL, type = "source", lib = "lib/bep")
