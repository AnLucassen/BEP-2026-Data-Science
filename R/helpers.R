source("R/config.R")

# ---- loading one of the two installed versions of subgroupsem ---------------
# "original" = upstream commit, "bep" = pkg/subgroupsem (your changes).
# Only ONE of them can be loaded per R process, so every run is its own process.
load_subgroupsem <- function(variant = c("bep", "original")) {
  variant <- match.arg(variant)
  lib <- file.path("lib", variant)
  if (!dir.exists(file.path(lib, "subgroupsem"))) {
    stop("subgroupsem '", variant, "' not installed - run R/00_install.R")
  }
  suppressPackageStartupMessages({
    library(lavaan)
    library(subgroupsem, lib.loc = lib)
  })
  invisible(variant)
}

# ---- data --------------------------------------------------------------------
hs_data <- function() {
  dat <- lavaan::HolzingerSwineford1939
  # IMPORTANT: 'grade' is an integer column with one NA. reticulate sends an
  # R integer NA to Python as -2147483648, which pysubgroup then treats as a
  # real value (selector grade == -2147483648). It is harmless here (1 row,
  # below the minimum size), so it is kept to reproduce the original exactly,
  # but for your own data convert covariates with NAs to double or factor.
  dat
}

# ---- run metadata ------------------------------------------------------------
git_commit <- function() {
  out <- tryCatch(system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE),
                  error = function(e) NA_character_)
  dirty <- tryCatch(length(system2("git", c("status", "--porcelain"), stdout = TRUE)) > 0,
                    error = function(e) NA)
  list(commit = if (length(out)) out[1] else NA_character_, uncommitted_changes = dirty)
}

run_info <- function() {
  py <- reticulate::py_config()
  ps_version <- tryCatch(
    reticulate::py_eval("__import__('importlib.metadata').metadata.version('pysubgroup')"),
    error = function(e) NA_character_)
  list(
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    git = git_commit(),
    machine = list(
      os = paste(Sys.info()[["sysname"]], Sys.info()[["release"]]),
      node = Sys.info()[["nodename"]],
      cores = parallel::detectCores()
    ),
    R = R.version.string,
    lavaan = as.character(packageVersion("lavaan")),
    reticulate = as.character(packageVersion("reticulate")),
    subgroupsem = as.character(packageVersion("subgroupsem")),
    python = py$version_string,
    pysubgroup = ps_version
  )
}

# ---- writing results with full precision -------------------------------------
# write.csv() keeps only 15 significant digits; for "exactly equal" checks
# we need all 17, so numbers are written as text.
write_precise_csv <- function(df, path) {
  df[] <- lapply(df, function(col) if (is.numeric(col)) sprintf("%.17g", col) else col)
  utils::write.csv(df, path, row.names = FALSE)
}

# ---- tie-aware comparison of two top-k lists ---------------------------------
# Subgroups with equal quality (e.g. a subgroup and its complement under the
# likelihood-ratio measure) may come out in any order, and at the last place
# of the list a tie decides WHICH subgroup is kept. So: compare the qualities
# rank by rank, and the descriptions as sets within each tie group.
compare_topk <- function(a, b, tol = 0, key = "subgroup") {
  msgs <- character(0)
  if (nrow(a) != nrow(b)) msgs <- c(msgs, sprintf("different length: %d vs %d", nrow(a), nrow(b)))
  k <- min(nrow(a), nrow(b))
  qa <- as.numeric(a$quality[seq_len(k)]); qb <- as.numeric(b$quality[seq_len(k)])
  rel <- abs(qa - qb) / pmax(abs(qa), 1e-12)
  if (any(rel > tol)) {
    msgs <- c(msgs, sprintf("quality differs at rank(s) %s (max rel. diff %.3g)",
                            paste(which(rel > tol), collapse = ","), max(rel)))
  }
  boundary_note <- NULL
  if (!is.null(key) && key %in% names(a) && key %in% names(b)) {
    grp <- cumsum(c(TRUE, diff(qa) < -max(tol, 1e-9) * abs(qa[-1])))  # tie groups
    for (g in unique(grp)) {
      idx <- which(grp == g)
      sa <- sort(as.character(a[[key]][idx])); sb <- sort(as.character(b[[key]][idx]))
      if (!identical(sa, sb)) {
        if (max(idx) == k) {
          boundary_note <- "different subgroup(s) in a tie at the last rank (allowed)"
        } else {
          msgs <- c(msgs, sprintf("different %s in tie group at ranks %s",
                                  key, paste(idx, collapse = ",")))
        }
      }
    }
  }
  list(ok = length(msgs) == 0, problems = msgs, note = boundary_note)
}
