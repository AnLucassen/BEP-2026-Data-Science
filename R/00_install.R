# ONE-TIME SETUP (run again only when you want to rebuild everything).
# Run from the project root:  Rscript R/00_install.R
source("R/config.R")

# 1. renv: a private R library for this project + a lockfile with exact versions
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}
if (!file.exists("renv/activate.R")) {
  renv::init(bare = TRUE, restart = FALSE)   # also edits .Rprofile (keeps our lines)
}
renv::activate()
# subgroupsem is installed separately (twice) below, so renv must not manage it
renv::settings$ignored.packages("subgroupsem")
renv::install(c("lavaan", "reticulate", "jsonlite"), prompt = FALSE)

# 2. The ORIGINAL subgroupsem, frozen at a fixed upstream commit -> lib/original
dir.create("lib/original", recursive = TRUE, showWarnings = FALSE)
tarball <- tempfile(fileext = ".tar.gz")
download.file(
  sprintf("https://github.com/langenberg/subgroupsem/archive/%s.tar.gz",
          UPSTREAM_SUBGROUPSEM_COMMIT),
  tarball, mode = "wb"
)
install.packages(tarball, repos = NULL, type = "source", lib = "lib/original")

# 3. YOUR version (pkg/subgroupsem) -> lib/bep
source("R/install_bep.R")

# 4. Record exact versions of all R packages
renv::snapshot(type = "all", prompt = FALSE)

# 5. Check that R finds the right Python and that pysubgroup is OK
print(reticulate::py_config())
library(subgroupsem, lib.loc = "lib/bep")
stopifnot("Python/pysubgroup not set up correctly" = isTRUE(subgroupsem_ready()))
cat("\nSetup finished. Next: Rscript R/01_hs_reproduce.R\n")
