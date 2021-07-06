library(tinytest)
library(httpproblems)

# Bundled expectations for a Problem Details structure.
expect_http_problem <- function(x, status = 500L) {
  expect_inherits(x, "http_problem")
  expect_true(is.character(x$type))
  expect_true(is.character(x$title))
  expect_equal(x$status, status)
}

# Test that http_problem structures work as expected.
out <- http_problem()
expect_http_problem(out)
expect_null(out$detail)
expect_null(out$instance)

# Test that http_problems with optional fields work as expected.
out <- http_problem(details = "Unknown", instance = "/widgets/101")
expect_true(is.character(out$detail))
expect_true(is.character(out$instance))

# Test that http_problem structures can be extended.
out <- http_problem(random_code = 46L)
expect_http_problem(out)
expect_equal(out$random_code, 46L)

# Test that http_problem helpers work as expected.
expect_http_problem(bad_request(), 400L)
expect_http_problem(unauthorized(), 401L)
expect_http_problem(forbidden(), 403L)
expect_http_problem(not_found(), 404L)
expect_http_problem(conflict(), 409L)
expect_http_problem(internal_server_error(), 500L)
