#' @export
#' @title Subgroup discovery algorithms for use with structural equation models
#' @description This function is the main function of the package and can be
#' flexibly used to interface the python module pysubgroup for efficiently
#' finding subgroups in structural equation models estimated by the R package
#' lavaan.
#' @param f_fit Function to be fitted. Must take at least two arguments.
#' \code{f_fit} has the signature \code{function(group, dat, ...)}. \code{group}
#' is a numeric vector. The length of this vector equals the rows in the data
#' frame \code{dat} and is to be interpreted as an additional column indicating
#' the group assignment. \code{f_fit} returns the interestingness measure.
#' Returned values should be greater than \code{min_quality} in case of sucess
#' and smaller in case of failure (e.g., non-convergence, error).
#' @param dat A data frame.
#' @param columns Column names of the provided data frame which are to be
#' analysed. Columns must have ordinal or nominal scale.
#' @param ignore Optional argument. If \code{columns = NULL}, \code{ignore} will
#' be used to select every column that is not in ignore.
#' @param algorithm A character specifying the subgroup discovery algorithm to
#' use. An exhaustive depth-first search is provided with 'SimpleDFS' (default)
#' . A heuristic (non-exhaustive) Beam search is provided with 'Beam', but not
#' yet implemented.
#' @param max_n_subgroups Maximum number of subgroups. Default is 10.
#' @param search_depth Maximum number of attribute combinations. Default is 3.
#' @param min_quality Minimum value of interestingness measure. Values below
#' will not be considered. Default is 0.
#' @param min_subgroup_size Minimum size of a subgroup. Subgroups with sizes
#' below will not be considered. The absolute minimum is set to 50 units, which
#' can not be lowered. If NULL (default) the absolute minimum is applied.
#' @param na_rm Boolean. Default is FALSE. If set to TRUE, cases with NA values
#' on any column will be set to FALSE in the \code{sg} vector. If set to FALSE,
#' the regarding in the \code{sg} vector will be also \code{NA}.
#' @param weighting_attr This option is \emph{deprecated}.
#' @param generalization_aware This option is \emph{deprecated}.
#' @param bw Integer for beam width. Only used if algorithm is Beam search.
#' Defaults to \code{max_n_subgroups}.
#' @param verbose Logical. Get some information, what is going on. Defaults
#' to \code{FALSE}.
#' @param ... Additional arguments to be passed to \code{f_fit}. Currently,
#' not well implemented.
#' @return List containing the time consumed and the groups.
#' @examples
#' if (FALSE) {
#'     model <- "
#'      eta1 =~ NA*x1 + x2 + x3
#'      eta2 =~ NA*x4 + x5 + x6
#'      eta3 =~ NA*x7 + x8 + x9
#'
#'      eta1 ~~ 1*eta1
#'      eta2 ~~ 1*eta2
#'      eta3 ~~ 1*eta3
#'
#'      eta1 + eta2 + eta3 ~ 0*1
#'      "
#'
#'     f_fit <- function(sg, dat) {
#'         # Add subgroup to dataset (from logical to numeric)
#'         sg <- as.numeric(sg)
#'         dat$subgroup <- sg
#'
#'         # if all participants in subgroup return -1
#'         if (all(sg == 1)) {
#'             rval <- 0
#'             return(rval)
#'         }
#'         rval <- tryCatch(
#'             {
#'                 # Fit Model
#'                 fit <- sem(model, data = dat, group = "subgroup")
#'                 stopifnot(lavInspect(fit, "post.check"))
#'
#'                 # Compute interestingness measure
#'                 tmp <- partable(fit)
#'                 lam1 <- tmp$est[
#'                     tmp$lhs == "eta1" &
#'                         tmp$op == "=~" & tmp$group == 1
#'                 ]
#'                 lam2 <- tmp$est[
#'                     tmp$lhs == "eta1" &
#'                         tmp$op == "=~" &
#'                         tmp$group == 2
#'                 ]
#'                 difflam <- abs(lam2 - lam1)
#'                 rval <- sum(sg, na.rm = T)^0.5 * sum(difflam)
#'             },
#'             error = function(e) -1
#'         )
#'
#'         if (!is.numeric(rval) | length(rval) > 1) {
#'             rval <- -1
#'         }
#'
#'         return(rval)
#'     }
#'
#'     m1 <- subgroupsem(
#'         f_fit = f_fit,
#'         dat = HolzingerSwineford1939,
#'         columns = c("sex", "school", "grade")
#'     )
#'     summary(m1)
#' }
#' @importFrom reticulate import_main import py_run_string
#' @import lavaan
subgroupsem <- function(f_fit,
                        dat,
                        columns = names(dat),
                        ignore = NULL,
                        algorithm = "SimpleDFS",
                        max_n_subgroups = 10L,
                        search_depth = 3L,
                        min_quality = 0,
                        min_subgroup_size = NULL,
                        weighting_attr = NULL,
                        generalization_aware = FALSE,
                        na_rm = FALSE,
                        bw = NULL,
                        verbose = FALSE,
                        ...) {

    # Some lines to check, whether reticulate / Python is set up correctly...
    if (!((status <- subgroupsem_ready(ask = T)) == TRUE)) {
        stop(status)
    }

    obj <- new("subgroupsem")
    obj@call <- match.call()

    # Some checks due to the refactoring arguments may be deprecated
    # Weighting attribute was never implemented and is currently not planned
    if (!is.null(weighting_attr)) {
        warning(
            paste(
                "subgroupsem warning:",
                "Option 'weighting_attr' is deprecated and will not be used."
            )
        )
    }

    # Generalization awareness was implemented before,
    # but not sure whether it is useful
    if (generalization_aware) {
        warning(
            paste(
                "subgroupsem warning:",
                "Option 'generalization_aware' is deprecated and will not be used."
            )
        )
    }

    # Import Python environment, pysubgroup module, and semtarget class
    py_main <- import_main()
    py_main$ps <- import("pysubgroup")
    py_run_string(get_py_classes())

    ## push data and f_fit function to python
    py_main$data <- dat

    ## TODO: maybe it would be easier to extend the class Conjunction
    ## for the complement...
    ## get matrix of NAs
    if (!is.null(ignore)) {
        columns <- columns[!(columns %in% ignore)]
    }
    has_na <- sapply(columns, function(column) is.na(dat[, column]))

    subsem_county <- 1L
    f_fit_internal <- function(sg, selectors = NULL) {
        # Empty selectors are transfered as empty list...
        if (is.list(selectors)) selectors <- unlist(selectors)
        ## if selectors for subgroup is not NULL
        if (!na_rm && !is.null(selectors)) {
            ## if case has NA in one of the selectors, insert NA
            has_na_selectors <- apply(has_na[, selectors, drop = F], 1, any)
            sg <- ifelse(has_na_selectors, NA, sg)
        }

        # Check if subgroup is big enough, else return -1
        if (!is.null(min_subgroup_size)) {
            if (sum(sg, na.rm = TRUE) < min_subgroup_size) {
                return(-1)
            }
        }

        if (verbose) {
            if (subsem_county > 1L) {
                cat("\r")
            } else {
                cat("\n")
            }
            msg <- paste(
                "Inspecting group",
                subsem_county,
                "combination of",
                paste(selectors, collapse = " AND ")
            )
            cat(msg)
            subsem_county <<- subsem_county + 1L
        }

        ## pass sg and dat to user specified function
        return(f_fit(sg, dat))
    }
    py_main$f_fit <- f_fit_internal

    # RUN PYSUBGROUP ROUTINE
    # 1. Define target class
    py_main$target <- py_main$SEMTarget()

    # 2. Define selector variables, i.e. variables named in columns
    # and not excluded through ignore
    ignore_names <- names(dat)[!(names(dat) %in% columns)]
    py_main$searchspace <- py_main$ps$create_selectors(
        dat,
        ignore = ignore_names
    )

    # 3. Specify the subgroup discovery task by passing all required
    # arguments to the respective Python function
    py_main$task <- py_main$ps$SubgroupDiscoveryTask(
        py_main$data,
        py_main$target,
        py_main$searchspace,
        qf = py_main$SEM_QF(),
        result_set_size = max_n_subgroups,
        depth = search_depth,
        min_quality = min_quality,
        constraints = NULL
    )

    # 4. Specify and run the search algorithm
    # only DFS implemented at the moment
    # Beam search should follow shortly
    # Double beam search, perhaps?
    start <- Sys.time()
    if (algorithm == "SimpleDFS" | algorithm == "DFS") {
        py_run_string("result = ps.SimpleDFS().execute(task)")
    } else if (algorithm == "Beam") {
        if (is.null(bw)) {
            py_main$bw <- as.integer(max_n_subgroups)
        } else {
            py_main$bw <- as.integer(bw)
        }
        py_run_string("result = ps.BeamSearch(beam_width=bw).execute(task)")
    } else {
        warning(
            paste(
                "subgroupsem warning:",
                "Currently only depth-first-search (DFS) and beam search are available as algorithms."
            )
        )
    }
    end <- Sys.time()

    # Import results
    obj@time_elapsed <- end - start
    obj@summary_statistics <- py_main$result$to_dataframe()

    # At last try to remove everything on the Python site from memory
    clean_up_python()

    return(obj)
}