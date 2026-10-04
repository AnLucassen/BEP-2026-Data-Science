test_that("subsem example works", {
  # Define lavaan model
  model <- "
eta1 =~ NA*x1 + c(la21,la22)*x2 + x3
eta2 =~ NA*x4 + c(la51,la52)*x5 + x6
eta3 =~ NA*x7 + c(la81,la82)*x8 + x9
eta1 ~~ 1*eta1
eta2 ~~ 1*eta2
eta3 ~~ 1*eta3
eta1 + eta2 + eta3 ~ 0*1
subsem_qf := abs(la21 - la22)
"
  # Pass model, data and names of predictors to function
  m1 <- subsem(
    model = model,
    data = lavaan::HolzingerSwineford1939,
    qf = NULL,
    predictors = c("sex", "school", "grade"),
    lavaan_options = list(warn = FALSE),
    subsem_options = list(min_subgroup_size = 50L)
  )

  # Are the interestingness measures right?
  qf <- m1@summary_statistics$quality
  qf_comp <- c(
    0.28907714, 0.15964395,
    0.15964395, 0.14323220,
    0.14257161, 0.13856784,
    0.13763556, 0.13763556,
    0.09474523, 0.09368847
  )
  expect_equal(qf, qf_comp, tolerance = 1e-7)

  # Do the subgroup sizes match?
  size_sg <- m1@summary_statistics$size_sg
  size_sg_comp <- c(73, 156, 145, 83, 79, 82, 146, 155, 72, 74)
  expect_equal(size_sg, size_sg_comp)
})

test_that("subsem_wald_works", {
  # Define lavaan model
  model <- "
 eta1 =~ NA*x1 + c(la21,la22)*x2 + x3
 eta2 =~ NA*x4 + c(la51,la52)*x5 + x6
 eta3 =~ NA*x7 + c(la81,la82)*x8 + x9

 eta1 ~~ 1*eta1
 eta2 ~~ 1*eta2
 eta3 ~~ 1*eta3

 eta1 + eta2 + eta3 ~ 0*1
 "

  con <- "
 la21 == la22
 la51 == la52
 la81 == la82
 "

  # Pass model, data and names of predictors to function
  m1 <- subsem_wald(
    model = model,
    data = lavaan::HolzingerSwineford1939,
    constraints = con,
    predictors = c("sex", "school", "grade"),
    lavaan_options = list(warn = FALSE),
    subsem_options = list(min_subgroup_size = 50L)
  )

  # Are the interestingness measures right?
  qf <- m1@summary_statistics$quality
  qf_comp <- c(
    14.144601, 10.675162,
    8.542270,  8.542270,
    7.950840,  5.662999,
    5.265130,  4.604717,
    4.604717,  4.212558
  )
  expect_equal(qf, qf_comp, tolerance = 1e-5)

  # Do the subgroup sizes match?
  size_sg <- m1@summary_statistics$size_sg
  size_sg_comp <- c(72, 65, 155, 146, 83, 82, 72, 145, 156, 73)
  expect_equal(size_sg, size_sg_comp)
})

test_that("subsem_lrt_works", {
  # Define lavaan model
  model <- "
eta1 =~ NA*x1 + x2 + x3
eta2 =~ NA*x4 + x5 + x6
eta3 =~ NA*x7 + x8 + x9
eta1 ~~ 1*eta1
eta2 ~~ 1*eta2
eta3 ~~ 1*eta3
eta1 + eta2 + eta3 ~ 0*1
"
  # Pass model, data and names of predictors to function
  m1 <- subsem_lrt(
    model = model,
    data = lavaan::HolzingerSwineford1939,
    predictors = c("sex", "school", "grade"),
    lavaan_options = list(warn = FALSE),
    subsem_options = list(min_subgroup_size = 50L)
  )

  # Are the interestingness measures right?
  qf <- m1@summary_statistics$quality
  qf_comp <- c(
    111.09483, 111.09483,
    107.82037, 97.03249,
    97.03249, 94.98001,
    92.99673, 90.87883,
    89.37181, 80.94426
  )
  expect_equal(qf, qf_comp, tolerance = 1e-5)

  # Do the subgroup sizes match?
  size_sg <- m1@summary_statistics$size_sg
  size_sg_comp <- c(145, 156, 79, 157, 143, 65, 72, 78, 73, 74)
  expect_equal(size_sg, size_sg_comp)
})



test_that("passing_options_works", {
  # Define lavaan model
  model <- "
 eta1 =~ NA*x1 + c(la21,la22)*x2 + x3
 eta2 =~ NA*x4 + c(la51,la52)*x5 + x6
 eta3 =~ NA*x7 + c(la81,la82)*x8 + x9

 eta1 ~~ 1*eta1
 eta2 ~~ 1*eta2
 eta3 ~~ 1*eta3

 eta1 + eta2 + eta3 ~ 0*1
 "

  con <- "
 la21 == la22
 la51 == la52
 la81 == la82
 "

  # Pass model, data and names of predictors to function
  m1 <- subsem_wald(
    model = model,
    data = lavaan::HolzingerSwineford1939,
    constraints = con,
    predictors = c("sex", "school", "grade"),
    subsem_options = list(
      algorithm = "Beam",
      search_depth = 2L,
      max_n_subgroups = 5L,
      min_subgroup_size = 70L
    ),
    lavaan_options = list(missing = "fiml")
  )
  summary(m1)
  expect_equal(1, 1)
})




test_that("subsem_multigroup_lrt_works", {
  # Define lavaan model
  model <- "
eta1 =~ NA*x1 + x2 + x3
eta2 =~ NA*x4 + x5 + x6
eta3 =~ NA*x7 + x8 + x9
eta1 ~~ 1*eta1
eta2 ~~ 1*eta2
eta3 ~~ 1*eta3
eta1 + eta2 + eta3 ~ 0*1
"
  # Pass model, data and names of predictors to function
  m1 <- subsem_lrt(
    model = model,
    data = lavaan::HolzingerSwineford1939,
    predictors = c("school", "grade"),
    group = "sex",
    lavaan_options = list(warn = FALSE),
    subsem_options = list(min_subgroup_size = 50L)
  )

  # Are the interestingness measures right?
  qf <- m1@summary_statistics$quality
  qf_comp <- c(
    151.0604, 151.0604,
    127.1631
  )
  expect_equal(qf, qf_comp, tolerance = 1e-5)

  # Do the subgroup sizes match?
  size_sg <- m1@summary_statistics$size_sg
  size_sg_comp <- c(156, 145, 65)
  expect_equal(size_sg, size_sg_comp)
})