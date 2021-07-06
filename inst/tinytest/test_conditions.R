library(tinytest)
library(httpproblems)

expect_http_problem <- function(x, status = 500L) {
  expect_inherits(x, "http_problem")
  expect_true(is.character(x$type))
  expect_true(is.character(x$title))
  expect_equal(x$status, status)
}

expect_match <- function(x, regexp) {
  expect_true(grepl(regexp, x))
}

# Bundled expectations for error structures.
expect_http_error <- function(expr, status = 500L) {
  x <- tryCatch(expr, error = function(e) e)
  expect_inherits(x, "error")
  expect_inherits(x, "http_problem_error")
  expect_http_problem(x$body, status)
  expect_equal(x$status, status)
  expect_match(x$message, sprintf("HTTP %d", status))
  expect_match(x$message, x$body$title)
  if (!is.null(x$body$detail)) {
    expect_match(x$message, x$body$detail)
  }
  x
}

# Test that http_problem conditions work as expected.
out <- expect_http_error(stop_for_http_problem())
expect_null(out$body$detail)
expect_null(out$body$instance)
out <- expect_http_error(
  stop_for_http_problem(details = "Unknown", instance = "/widgets/101")
)
expect_true(is.character(out$body$detail))
expect_true(is.character(out$body$instance))

# Test that http_problem condition helpers work as expected.
expect_http_error(stop_for_bad_request(), 400L)
expect_http_error(stop_for_unauthorized(), 401L)
expect_http_error(stop_for_forbidden(), 403L)
expect_http_error(stop_for_not_found(), 404L)
expect_http_error(stop_for_conflict(), 409L)
expect_http_error(stop_for_internal_server_error(), 500L)
