#' @export
#' @title User-level function with user-defined interestingness measure
#' @description todo
#' @param model a lavaan model syntax (a character vector)
#' @param data a data frame
#' @param qf a lavaan syntax-based computation of the interestingness measure,
#' where the interestingness measure has to be named *subsem_qf*. Can also
#' be included directly in the model syntax (then, here NULL, as is default)
#' @param predictors a character vector of variable names, which are used as
#' covariates/predictors in the subgroup discovery (variables in data)
#' @param group An additional group variable for subgroup discovery in
#' multigroup models.
#' @param subsem_options A list of additional options passed to the subgroupsem
#' main function
#' @param lavaan_options A list of additional options passed to the lavaan
#' main function
#' @return List containing the time consumed and the groups.
#' @importFrom lavaan sem
#' @importFrom lavaan partable
#' @importFrom lavaan lavInspect
#' @examples
#' # Define lavaan model
#' model <- "
#' eta1 =~ NA*x1 + c(la21,la22)*x2 + x3
#' eta2 =~ NA*x4 + c(la51,la52)*x5 + x6
#' eta3 =~ NA*x7 + c(la81,la82)*x8 + x9
#'
#' eta1 ~~ 1*eta1
#' eta2 ~~ 1*eta2
#' eta3 ~~ 1*eta3
#'
#' eta1 + eta2 + eta3 ~ 0*1
#'
#' subsem_qf := abs(la21 - la22)
#' "
#'
#' # Pass model, data and names of predictors to function
#' m1 <- subsem(
#'   model = model,
#'   data = lavaan::HolzingerSwineford1939,
#'   qf = NULL,
#'   predictors = c("sex", "school", "grade")
#' )
#' summary(m1)
subsem <- function(model,
                   data,
                   qf = NULL,
                   predictors = NULL,
                   group = NULL,
                   subsem_options = list(),
                   lavaan_options = list()) {
  stopifnot(
    "subsem_options must be specified as list." = is.list(subsem_options)
  )

  # if (!((status <- subgroupsem_ready(ask = T)) == TRUE)) {
  #   stop(status)
  # }

  # Extract covariates names
  predictors <- subsem_get_predictor_names(model, data, predictors)

  if (!is.null(group)) {
    groupvar <- as.factor(unlist(data[group]))
  }

  if (!is.null(qf)) {
    model <- paste0(model, "\n", qf)
  }

  f_fit <- function(sg, dat) {
    # Add subgroup to dataset (from logical to numeric)
    sg <- as.numeric(sg)

    # if all participants in subgroup return 0
    if (all(sg == 1, na.rm = TRUE)) {
      rval <- 0
      return(rval)
    }

    # single-group or multi-group model?
    if (is.null(group)) {
      dat$subgroup <- sg
    } else {
      dat$subgroup <- apply(cbind(groupvar, sg), 1, paste, collapse = "")
      dat$subgroup[apply(cbind(groupvar, sg), 1, anyNA)] <- NA

      # re-order, so that order of groups is always clearly determined
      dat <- dat[order(dat$subgroup), ]
    }

    rval <- tryCatch(
      {
        # Fit Model
        default_args <- list(
          model = model,
          data = dat,
          group = "subgroup"
        )
        fit <- do.call(
          "sem",
          c(default_args, lavaan_options)
        )

        stopifnot(lavInspect(fit, "post.check"))
        stopifnot(lavInspect(fit, "converged"))
        # Extract interestingness measure
        pt <- partable(fit)

        rval <- pt$est[pt$label == "subsem_qf"]
      },
      error = function(e) -1
    )


    if (!is.numeric(rval) | length(rval) > 1) {
      rval <- -1
    }

    return(rval)
  }

  # Search for subgroups
  cat("Searching for subgroups...")
  default_args <- list(
    f_fit = f_fit,
    dat = data,
    columns = predictors
  )
  task <- do.call(
    "subgroupsem",
    c(default_args, subsem_options)
  )

  cat("Done.\n")
  return(task)
}



#' @export
#' @title User-level function for Wald-test based SubgroupSEM
#' @description todo
#' @param model a lavaan model syntax (a character vector)
#' @param data a data frame
#' @param constraints a lavaan syntax-based constraint of parameters for the
#' Wald test. (a character vector)
#' @param predictors a character vector of variable names, which are used as
#' covariates/predictors in the subgroup discovery (variables in data)
#' @param group An additional group variable for subgroup discovery in
#' multigroup models.
#' @param subsem_options A list of additional options passed to the subgroupsem
#' main function
#' @param lavaan_options A list of additional options passed to the lavaan
#' main function
#' @return List containing the time consumed and the groups.
#' @importFrom lavaan sem
#' @importFrom lavaan lavInspect
#' @importFrom lavaan lavTestWald
#' @examples
#' # Define lavaan model
#' model <- "
#' eta1 =~ NA*x1 + c(la21,la22)*x2 + x3
#' eta2 =~ NA*x4 + c(la51,la52)*x5 + x6
#' eta3 =~ NA*x7 + c(la81,la82)*x8 + x9
#'
#' eta1 ~~ 1*eta1
#' eta2 ~~ 1*eta2
#' eta3 ~~ 1*eta3
#'
#' eta1 + eta2 + eta3 ~ 0*1
#' "
#'
#' con <- "
#' la21 == la22
#' la51 == la52
#' la81 == la82
#' "
#'
#' # Pass model, data and names of predictors to function
#' m1 <- subsem_wald(
#'   model = model,
#'   data = lavaan::HolzingerSwineford1939,
#'   constraints = con,
#'   predictors = c("sex", "school", "grade")
#' )
#' summary(m1)
subsem_wald <- function(model,
                        data,
                        constraints,
                        predictors = NULL,
                        group = NULL,
                        subsem_options = list(),
                        lavaan_options = list()) {

  # Extract covariates names
  predictors <- subsem_get_predictor_names(model, data, predictors)

  if (!is.null(group)) {
    groupvar <- as.factor(unlist(data[group]))
  }

  f_fit <- function(sg, dat) {
    # Add subgroup to dataset (from logical to numeric)
    sg <- as.numeric(sg)

    # if all participants in subgroup return 0
    if (all(sg == 1, na.rm = TRUE)) {
      rval <- 0
      return(rval)
    }

    # single-group or multi-group model?
    if (is.null(group)) {
      dat$subgroup <- sg
    } else {
      dat$subgroup <- apply(cbind(groupvar, sg), 1, paste, collapse = "")
      dat$subgroup[apply(cbind(groupvar, sg), 1, anyNA)] <- NA

      # re-order, so that order of groups is always clearly determined
      dat <- dat[order(dat$subgroup), ]
    }

    rval <- tryCatch(
      {
        # Fit Model
        default_args <- list(
          model = model,
          data = dat,
          group = "subgroup"
        )
        fit <- do.call(
          "sem",
          c(default_args, lavaan_options)
        )

        stopifnot(lavInspect(fit, "post.check"))
        # Compute interestingness measure
        lavwald <- lavTestWald(fit, constraints)
        rval <- lavwald$stat
      },
      error = function(e) -1
    )

    if (!is.numeric(rval) | length(rval) > 1) {
      rval <- -1
    }
    return(rval)
  }

  # Search for subgroups
  cat("Searching for subgroups...")
  default_args <- list(
    f_fit = f_fit,
    dat = data,
    columns = predictors
  )
  task <- do.call(
    "subgroupsem",
    c(default_args, subsem_options)
  )


  cat("Done.\n")
  return(task)
}


#' @export
#' @title User-level function for LRT-based SubgroupSEM
#' @description todo
#' @param model a lavaan model syntax (a character vector)
#' @param data a data frame
#' @param predictors a character vector of variable names, which are used as
#' covariates/predictors in the subgroup discovery (variables in data)
#' @param group An additional group variable for subgroup discovery in
#' multigroup models.
#' @param subsem_options A list of additional options passed to the subgroupsem
#' main function
#' @param lavaan_options A list of additional options passed to the lavaan
#' main function
#' @importFrom lavaan sem
#' @importFrom lavaan lavInspect
#' @importFrom lavaan lavaanify
#' @examples
#' # Define lavaan model
#' model <- "
#' eta1 =~ NA*x1 + x2 + x3
#' eta2 =~ NA*x4 + x5 + x6
#' eta3 =~ NA*x7 + x8 + x9
#'
#' eta1 ~~ 1*eta1
#' eta2 ~~ 1*eta2
#' eta3 ~~ 1*eta3
#'
#' eta1 + eta2 + eta3 ~ 0*1
#' "
#'
#' # Pass model, data and names of predictors to function
#' m1 <- subsem_lrt(
#'   model = model,
#'   data = lavaan::HolzingerSwineford1939,
#'   predictors = c("sex", "school", "grade")
#' )
#' summary(m1)
subsem_lrt <- function(model,
                       data,
                       predictors = NULL,
                       group = NULL,
                       subsem_options = list(),
                       lavaan_options = list()) {

  # Extract covariates names
  predictors <- subsem_get_predictor_names(model, data, predictors)

  if (!is.null(group)) {
    groupvar <- as.factor(unlist(data[group]))
    ngroups <- length(levels(groupvar)) * 2L
    basemod <- get_multi_group_partable(model, ngroups)
  } else {
    ngroups <- 2L
    basemod <- get_single_group_partable(model)
  }


  baseline_args <- list(
    model = basemod,
    data = data,
    se = "none",
    group = group
  )
  baselinefit <- do.call(
    "sem",
    c(baseline_args, lavaan_options)
  )

  # Interestingness Measure in Baseline Fit
  basefit <- lavInspect(baselinefit, "fit")
  basefitlog <- -2 * basefit["logl"]

  f_fit <- function(sg, dat) {
    # Add subgroup to dataset (from logical to numeric)
    sg <- as.numeric(sg)

    # if all participants in subgroup return -1
    if (all(sg == 1, na.rm = TRUE)) {
      rval <- 0
      return(rval)
    }

    # single-group or multi-group model?
    if (is.null(group)) {
      dat$subgroup <- sg
    } else {
      dat$subgroup <- apply(cbind(groupvar, sg), 1, paste, collapse = "")
      dat$subgroup[apply(cbind(groupvar, sg), 1, anyNA)] <- NA
    }

    rval <- tryCatch(
      {
        # Fit Model
        default_args <- list(
          model = model,
          data = dat,
          group = "subgroup",
          se = "none"
        )
        fit <- do.call(
          "sem",
          c(default_args, lavaan_options)
        )
        stopifnot(lavInspect(fit, "post.check"))

        # Compute interestingness measure
        tmp <- lavInspect(fit, "fit")
        rval <- abs(-2 * tmp["logl"] - basefitlog)
      },
      error = function(e) -1
    )

    if (!is.numeric(rval) | length(rval) > 1) {
      rval <- -1
    }

    return(rval)
  }

  # Search for subgroups
  cat("Searching for subgroups...")

  default_args <- list(
    f_fit = f_fit,
    dat = data,
    columns = predictors
  )
  task <- do.call(
    "subgroupsem",
    c(default_args, subsem_options)
  )

  cat("Done.\n")
  return(task)
}

#' @noRd
#' @keywords internal
#' @importFrom lavaan lavNames
#' @importFrom lavaan lavaanify
subsem_get_predictor_names <- function(model, data, predictors) {
  if (is.null(predictors)) {
    predictors <- names(data)[
      !names(data) %in% lavNames(lavaanify(model, ngroups = 2L))
    ]
  } else if (is.character(predictors)) {
    predictors <- predictors
  } else {
    stop("You have not correctly specified the predictor variables.")
  }
  return(predictors)
}

#' @noRd
#' @keywords internal
#' @importFrom lavaan lavaanify
get_single_group_partable <- function(model) {
  pt <- lavaanify(
    model = model, ngroups = 2L,
    # default options for sem/cfa call
    int.ov.free = TRUE,
    int.lv.free = FALSE,
    auto.fix.first = TRUE,
    auto.fix.single = TRUE,
    auto.var = TRUE,
    auto.cov.lv.x = TRUE,
    auto.cov.y = TRUE,
    auto.th = TRUE,
    auto.delta = TRUE,
    auto.efa = TRUE,
    meanstructure = TRUE
  )
  model_single_group <- pt[pt$group == 1, ]
  return(model_single_group)
}

#' @noRd
#' @keywords internal
#' @importFrom lavaan lavaanify
get_multi_group_partable <- function(model, ngroups) {
  pt <- lavaanify(
    model = model, ngroups = ngroups,
    # default options for sem/cfa call
    int.ov.free = TRUE,
    int.lv.free = FALSE,
    auto.fix.first = TRUE,
    auto.fix.single = TRUE,
    auto.var = TRUE,
    auto.cov.lv.x = TRUE,
    auto.cov.y = TRUE,
    auto.th = TRUE,
    auto.delta = TRUE,
    auto.efa = TRUE,
    meanstructure = TRUE
  )
  model_multi_group <- pt[pt$group %in% c(1:(ngroups / 2)), ]
  return(model_multi_group)
}