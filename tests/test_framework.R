library(testthat)
for (f in list.files(file.path("..", "R"), full.names = TRUE)) source(f)

d <- load_colon()

test_that("the analysis data and reference findings match the design", {
  expect_equal(dim(d), c(888L, 15L))
  expect_equal(as.vector(table(d$rx)), c(305L, 294L, 289L))
  f <- findings(d)
  expect_equal(round(exp(f$est), 2), c(0.59, 0.68, 0.96, 2.56))
  expect_equal(round(f$est / f$se, 2), c(-4.32, -3.16, -0.36, 9.24))
})

test_that("the original data follow both structural rules and repair leaves them alone", {
  expect_equal(unname(violations(d)), c(0, 0))
  expect_identical(repair(d), d)
})

test_that("repair enforces both rules", {
  s <- d[1:3, ]
  s$rec_time <- c(500L, 100L, 900L)
  s$os_time <- c(400L, 300L, 1000L)
  s$rec_status <- factor(c("1", "1", "0"), levels = c("0", "1"))
  expect_equal(unname(violations(s)), c(1 / 3, 1 / 3))
  r <- repair(s)
  expect_equal(r$rec_time, c(400L, 100L, 1000L))
  expect_equal(unname(violations(r)), c(0, 0))
})

test_that("distances are zero for an identical copy", {
  expect_equal(tvd(d$rx, d$rx), 0)
  expect_equal(ecdf_dist(d$age, d$age), 0)
  expect_equal(km_dist(d, d, "os_time", "os_status"), 0)
  expect_equal(cor_diff(d, d), 0)
  expect_equal(exact_share(d, d), 1)
  expect_equal(dcr_median(d[1:50, ], d), 0)
})

test_that("KM distance sees a shifted curve", {
  s <- d
  s$os_time <- pmax(1L, s$os_time %/% 2L)
  expect_gt(km_dist(s, d, "os_time", "os_status"), 0.1)
})

test_that("generators are reproducible and return valid data", {
  expect_identical(gen_bootstrap(d, 1), gen_bootstrap(d, 1))
  b <- gen_bn(d, 3)
  expect_identical(b, gen_bn(d, 3))
  expect_equal(names(b), VARS)
  expect_false(anyNA(b))
  expect_true(all(b$age >= min(d$age) & b$age <= max(d$age)))
  expect_true(all(b$os_time >= min(d$os_time) & b$os_time <= max(d$os_time)))
})

test_that("a missing arm gives NA, not an error", {
  s <- d[d$rx != "Lev", ]
  f <- findings(s)
  expect_true(is.na(f$est[f$finding == "F3"]))
  expect_false(is.na(f$est[f$finding == "F1"]))
})
