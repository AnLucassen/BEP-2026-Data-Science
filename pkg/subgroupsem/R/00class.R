#' subgroupsem object
#'
#' The overall object holding all relevant information
#'
#' @noRd
setClass(
    "subgroupsem",
    representation(
        call = "call",
        time_elapsed = "difftime",
        summary_statistics = "data.frame"
    )
)

#' @export
#' @noRd
setMethod(
    "summary", signature(object = "subgroupsem"),
    function(object) {
        object@summary_statistics$subgroup <- sapply(object@summary_statistics$subgroup, as.character)
        
        cat("General information:")
        cat("\n")

        cat("Elapsed time: ")
        cat(object@time_elapsed, attr(object@time_elapsed, "units"))
        cat("\n\n")

        cat("Summary of subgroup search:\n")
        print(object@summary_statistics)
    }
)

#' @export
#' @noRd
setMethod("plot", signature(x = "subgroupsem"), function(x) {
    object <- x
    n_sg <- nrow(object@summary_statistics)
    x <- 1:n_sg
    y <- object@summary_statistics$quality
    max_qf <- max(y)
    plot(
        x, y,
        xlab = "Subgroup index",
        ylab = "Interestingness measure",
        col = "black",
        type = "b",
        pch = 21,
        ylim = c(min(y), max(y)),
        main = "Interestingness of subgroups"
    )
})

# summary.subgroupsem <- function(object, ...) {
#     obj <- object
#     cat("General information:")
#     cat("\n")

#     cat("Elapsed time: ")
#     cat(obj$time_elapsed)
#     cat("\n\n")

#     cat("Summary of subgroup search:\n")
#     print(obj$summary_statistics)
# }

# plot.subgroupsem <- function(x, ...) {
#     obj <- x
#     n_sg <- nrow(obj$summary_statistics)
#     x <- 1:n_sg
#     y <- obj$summary_statistics$quality
#     max_qf <- max(y)
#     plot(
#         x, y,
#         xlab = "Subgroup index",
#         ylab = "Interestingness measure",
#         col = "black",
#         type = "b",
#         pch = 21,
#         ylim = c(min(y), max(y)),
#         main = "Interestingness of subgroups"
#     )
# }
