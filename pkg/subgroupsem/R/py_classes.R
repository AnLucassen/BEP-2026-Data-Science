#' @keywords internal
get_py_classes <- function(py_file = "sem_target.py") {
    py_string <- system.file("py_classes",
                             py_file,
                             package = "subgroupsem")
    py_string <- readLines(py_string)
    py_string <- paste0(py_string, collapse = "\n")
    return(py_string)
}
