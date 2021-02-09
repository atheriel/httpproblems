expect_http_problem <- function(x, status = 500L) {
  testthat::expect_s3_class(x, "http_problem")
  testthat::expect_true(is.character(x$type))
  testthat::expect_true(is.character(x$title))
  testthat::expect_equal(x$status, status)
}

expect_http_error <- function(expr, status = 500L) {
  x <- tryCatch(expr, error = function(e) e)
  testthat::expect_s3_class(x, "error")
  testthat::expect_s3_class(x, "http_problem_error")
  expect_http_problem(x$body, status)
  testthat::expect_equal(x$status, status)
  testthat::expect_match(x$message, sprintf("HTTP %d", status))
  testthat::expect_match(x$message, x$body$title)
  if (!is.null(x$body$detail)) {
    testthat::expect_match(x$message, x$body$detail)
  }
  x
}

testthat::test_that("http_problem structures work as expected", {
  out <- http_problem()
  expect_http_problem(out)
  testthat::expect_true(is.null(out$detail))
  testthat::expect_true(is.null(out$instance))
})

testthat::test_that("http_problems with optional fields work as expected", {
  out <- http_problem(details = "Unknown", instance = "/widgets/101")
  testthat::expect_true(is.character(out$detail))
  testthat::expect_true(is.character(out$instance))
})

testthat::test_that("http_problem structures can be extended", {
  out <- http_problem(random_code = 46L)
  expect_http_problem(out)
  testthat::expect_equal(out$random_code, 46L)
})

testthat::test_that("http_problem conditions work as expected", {
  out <- expect_http_error(stop_for_http_problem())
  testthat::expect_true(is.null(out$body$detail))
  testthat::expect_true(is.null(out$body$instance))
  out <- expect_http_error(
    stop_for_http_problem(details = "Unknown", instance = "/widgets/101")
  )
  testthat::expect_true(is.character(out$body$detail))
  testthat::expect_true(is.character(out$body$instance))
})

testthat::test_that("http_problem helpers work as expected", {
  expect_http_problem(bad_request(), 400L)
  expect_http_problem(unauthorized(), 401L)
  expect_http_problem(forbidden(), 403L)
  expect_http_problem(not_found(), 404L)
  expect_http_problem(conflict(), 409L)
  expect_http_problem(internal_server_error(), 500L)

  expect_http_error(stop_for_bad_request(), 400L)
  expect_http_error(stop_for_unauthorized(), 401L)
  expect_http_error(stop_for_forbidden(), 403L)
  expect_http_error(stop_for_not_found(), 404L)
  expect_http_error(stop_for_conflict(), 409L)
  expect_http_error(stop_for_internal_server_error(), 500L)
})
