source("renv/activate.R")
# Runs automatically when R starts in this folder (Rscript, RStudio or VS Code).
if (file.exists("renv/activate.R")) source("renv/activate.R")

local({
  # 1. Which Python should reticulate use?
  #    a) RETICULATE_PYTHON from the file .Renviron (machine-specific, not in git)
  #    b) a .venv folder in the project
  #    c) a conda environment called "bep" in a standard Anaconda/Miniconda place
  if (!nzchar(Sys.getenv("RETICULATE_PYTHON"))) {
    home <- Sys.getenv(if (.Platform$OS.type == "windows") "USERPROFILE" else "HOME")
    exe <- if (.Platform$OS.type == "windows") "python.exe" else "bin/python"
    candidates <- c(
      file.path(getwd(), if (.Platform$OS.type == "windows") ".venv/Scripts/python.exe" else ".venv/bin/python"),
      file.path(home, c("anaconda3", "miniconda3", "AppData/Local/anaconda3",
                        "AppData/Local/miniconda3"), "envs", "bep", exe),
      file.path("C:/ProgramData", c("anaconda3", "miniconda3"), "envs", "bep", exe)
    )
    found <- candidates[file.exists(candidates)]
    if (length(found)) {
      # no normalizePath(): on macOS/Linux it would follow the venv symlink out of the venv
      Sys.setenv(RETICULATE_PYTHON = found[1])
    } else {
      message("[BEP] No Python found. Put RETICULATE_PYTHON=... in .Renviron (see README).")
    }
  }
  # 2. Reproducibility and stable timings. Must be set before Python starts.
  Sys.setenv(
    PYTHONHASHSEED = "0",          # deterministic hashing of Python objects
    OMP_NUM_THREADS = "1",         # no hidden multithreading in BLAS/LAPACK,
    OPENBLAS_NUM_THREADS = "1",    # so one run = one core and timings
    MKL_NUM_THREADS = "1"          # are comparable between runs
  )
})
