#' @keywords internal
#'
clean_up_python <- function() {
    cleaning <- '
for element in dir():
    if element[0:2] != "__":
        del globals()[element]
del  element

import gc
gc.collect()'
    py_run_string(cleaning)
}

#' Checks whether python and module pysubgroup are installed.
#' @param ask Logical. Default is FALSE. Indicates whether user is asked whether
#' pysubgroup should be installed if it is not available.
#' @export
#' @importFrom reticulate py_available py_install import_main import py_run_string
subgroupsem_ready <- function(ask=FALSE) {
    if (!py_available(initialize = T)) {
        return("No python version could be found. Please install python version.")
    }
    
    installed <- tryCatch({
        py_main <- import_main()
        py_main$pkg_resources <- import("pkg_resources")
        py_run_string("from importlib import reload")
        py_run_string("reload(pkg_resources)")
        py_main$pkg_resources$get_distribution("pysubgroup")$version == "0.7.8"
    }, error = function(e) {
        FALSE
    })
    
    if (!installed && ask) {
        if (readline(prompt="Python module 'pysubgroup' not installed. Do you want to install now? (y/n) ") == tolower("y")) {
            cat("Installing pysubgroup...\n")
            py_install("pysubgroup==0.7.8", pip = T)
            cat("Installing pysubgroup... Done\n")
            return(TRUE)
        } else {
            return("Python module 'pysubgroup' not installed")
        }
    } else if (!installed) {
        return("Python module 'pysubgroup' not installed")
    }
    
    TRUE
}

# #' @keywords internal
# #' @importFrom reticulate py_run_string
# attach_reticulate <- function() {

#     ## try to load reticulate
#     tryCatch(
#         {
#             detach_reticulate()

#             load_reticulate()

#             activate_condaenv()

#             install_py_module(modulename = "numpy")

#             install_py_module(modulename = paste0(
#                 "pysubgroup",
#                 if (!is.null(.pkgglobalenv$pysubgroup_version)) {
#                     paste0("==", .pkgglobalenv$pysubgroup_version)
#                 } else {
#                     ""
#                 }
#             ))

#             message("Importing python modules...")
#             reticulate::py_run_string("import pysubgroup as ps")
#             reticulate::py_run_string("from timeit import default_timer as timer")

#             message("Sourcing additional python classes...")
#             reticulate::py_run_string(get_py_classes())

#             message("Library reticulate successfully attached! Yaaay :-)")
#             .pkgglobalenv$reticulate_loaded <- TRUE

#             return(list(status = TRUE, message = ""))
#         },
#         error = function(e) {
#             detach_reticulate()

#             return(list(status = FALSE, message = e))
#         }
#     )
# }

# #' @keywords internal
# #' @importFrom reticulate conda_create use_condaenv conda_list
# activate_condaenv <- function() {
#     message(paste0(
#         "Activating conda environment ",
#         .pkgglobalenv$envname,
#         "..."
#     ))
#     if (!(.pkgglobalenv$envname %in% reticulate::conda_list()$name)) {
#         message(
#             "conda environment r-reticulate not found, creating environment..."
#         )
#         reticulate::conda_create(.pkgglobalenv$envname,
#             conda = .pkgglobalenv$conda_path
#         )
#     }
#     reticulate::use_condaenv(.pkgglobalenv$envname,
#         conda = .pkgglobalenv$conda_path,
#         required = TRUE
#     )
# }

# #' @keywords internal
# load_reticulate <- function() {
#     if (!is_reticulate_attached()) {
#         message("Attaching library reticulate...")
#         requireNamespace("reticulate")
#     }
# }

# #' @export
# init_reticulate <- function() {
#     if (!(status <- attach_reticulate())$status) {
#         message(paste0(
#             "\nRSubgroup error:\n",
#             "reticulate could not be initialized with error: \n",
#             "    ", status$message, "\n\n",
#             "Did you properly install Anaconda? You may want to change the conda path using init_reticulate()."
#         ))
#     }
# }

# #' @export
# repair_reticulate <- function() {
#     remove_condaenv()

#     detach_reticulate()

#     init_reticulate()
# }

# #' @keywords internal
# is_reticulate_attached <- function() {
#     return("reticulate" %in% (.packages()))
# }

# #' @keywords internal
# detach_reticulate <- function() {
#     if (is_reticulate_attached()) {
#         message("Detaching library reticulate...")
#         detach("package:reticulate", unload = TRUE)
#     }
#     .pkgglobalenv$reticulate_loaded <- FALSE
# }

# #' @export
# remove_condaenv <- function() {
#     is_attached <- is_reticulate_attached()

#     load_reticulate()

#     message(paste0("Removing conda environment ", .pkgglobalenv$envname, "..."))
#     conda_remove(.pkgglobalenv$envname,
#         conda = .pkgglobalenv$conda_path
#     )

#     if (!is_attached) {
#         detach_reticulate()
#     }
# }

# #' @export
# #' @importFrom reticulate py_module_available conda_install
# install_py_module <- function(modulename) {
#     if (!reticulate::py_module_available(modulename)) {
#         message(paste0(
#             "Python module ",
#             modulename,
#             " missing, installing..."
#         ))

#         reticulate::conda_install(
#             envname = .pkgglobalenv$envname,
#             modulename,
#             pip = TRUE,
#             pip_ignore_installed = TRUE,
#             conda = .pkgglobalenv$conda_path
#         )
#     }
# }

# #' @export
# config_rsubgroup <- function(py_path,
#                              conda_path,
#                              envname,
#                              reload = FALSE) {
#     if (!missing(py_path)) {
#         .pkgglobalenv$py_path <- py_path
#     }

#     if (!missing(conda_path)) {
#         .pkgglobalenv$conda_path <- conda_path
#     }

#     if (!missing(envname)) {
#         .pkgglobalenv$envname <- envname
#     }

#     if (reload) {
#         init_reticulate()
#     }
# }

# #' @export
# get_rsubgroup_config <- function() {
#     return(list(
#         reticulate_loaded = .pkgglobalenv$reticulate_loaded,
#         py_path = .pkgglobalenv$py_path,
#         conda_path = .pkgglobalenv$conda_path,
#         envname = .pkgglobalenv$envname
#     ))
# }
