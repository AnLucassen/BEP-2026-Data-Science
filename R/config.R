# Central place for everything that defines an experiment.
# Change values HERE, never inside the run scripts, and commit the change.

# Full path to Rscript of the R that is running now (on Windows R is often not on PATH)
RSCRIPT <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")

UPSTREAM_SUBGROUPSEM_COMMIT <- "5e02c6c98d0083eedac086a5f0078bc0f23ac25b"

# Seeds: one fixed base seed per simulated dataset, plus two extra seeds for
# the base design (Section 4.4). Not used by the Holzinger-Swineford runs,
# which contain no randomness at all, except for the run order below.
SEED_BASE        <- 20261005L
SEEDS_BASE_EXTRA <- c(20261006L, 20261007L)
SEED_RUN_ORDER   <- 4040L   # shuffles the order of runs within a repetition

N_REPETITIONS <- 3L
ALGORITHMS    <- c("DFS", "Apriori", "BestFirst", "Beam")

# Holzinger-Swineford setting used for the reproduction. min_subgroup_size = 50
# is the value of the reference values in subgroupsem's own test file.
HS <- list(
  predictors = c("sex", "school", "grade"),
  depth = 3L,
  result_size = 10L,
  min_subgroup_size = 50L,
  beam_width = 10L,
  model = "
    eta1 =~ NA*x1 + x2 + x3
    eta2 =~ NA*x4 + x5 + x6
    eta3 =~ NA*x7 + x8 + x9
    eta1 ~~ 1*eta1
    eta2 ~~ 1*eta2
    eta3 ~~ 1*eta3
    eta1 + eta2 + eta3 ~ 0*1
  ",
  # Wald measure: labelled loadings and the equality constraints to test
  model_wald = "
    eta1 =~ NA*x1 + c(la21,la22)*x2 + x3
    eta2 =~ NA*x4 + c(la51,la52)*x5 + x6
    eta3 =~ NA*x7 + c(la81,la82)*x8 + x9
    eta1 ~~ 1*eta1
    eta2 ~~ 1*eta2
    eta3 ~~ 1*eta3
    eta1 + eta2 + eta3 ~ 0*1
  ",
  wald_constraints = "
    la21 == la22
    la51 == la52
    la81 == la82
  "
)
