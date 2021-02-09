
<!-- README.md is generated from README.Rmd. Please edit that file -->

# httpproblems

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/httpproblems)](https://CRAN.R-project.org/package=httpproblems)
[![R-CMD-check](https://github.com/atheriel/httpproblems/workflows/R-CMD-check/badge.svg)](https://github.com/atheriel/httpproblems/actions)
<!-- badges: end -->

This R package is an answer to the question “how can I report errors
from my R API in a standard, consistent way?”

Specifically, it implements the “Problem Details” specification from
[RFC 7807](https://tools.ietf.org/html/rfc7807), which is an emerging
standard for errors supported by many other languages and tools.

Although **httpproblems** orginated for use with
[Plumber](https://www.rplumber.io) (see below), it has no dependencies
of its own and can be used with any R web framework.

## Installation

You can install the latest release of **httpproblems** from
[CRAN](https://CRAN.R-project.org):

``` r
install.packages("httpproblems")
```

or the development version from GitHub with

``` r
# install.packages("remotes")
remotes::install_github("atheriel/httpproblems")
```

## Usage

**httpproblems** provides helpers to create a few common HTTP errors:

  - `bad_request()`
  - `not_found()`
  - `unauthorized()`
  - `forbidden()`
  - `conflict()`
  - `internal_server_error()`

as well as a generic `http_problem()` that can be used with any valid
status code.

These functions return a normal list with elements [in line with the
standard](https://tools.ietf.org/html/rfc7807#section-3.1):

``` r
library(httpproblems)

body <- bad_request("Parameter 'id' must be a number.")
str(body)
#> List of 4
#>  $ type  : chr "https://tools.ietf.org/html/rfc7231#section-6.5.1"
#>  $ title : chr "Bad Request"
#>  $ status: int 400
#>  $ detail: chr "Parameter 'id' must be a number."
#>  - attr(*, "class")= chr [1:2] "http_problem" "list"
```

This object could be returned by an endpoint as normal after
serialization to e.g. JSON.

In addition to these basic methods, **httpproblems** also has a set of
`stop_for_http_problem()` functions:

  - `stop_for_bad_request()`
  - `stop_for_not_found()`
  - `stop_for_unauthorized()`
  - `stop_for_forbidden()`
  - `stop_for_conflict()`
  - `stop_for_internal_server_error()`

These leverage R’s extensible condition system to issue custom errors
for these problems:

``` r
stop_for_bad_request("Parameter 'id' must be a number.")
#> Error: Bad Request (HTTP 400). Parameter 'id' must be a number.

# What does the error actually contain?
tryCatch(
  stop_for_bad_request("Parameter 'id' must be a number."),
  error = function(e) {
    str(e)
  }
)
#> List of 3
#>  $ message: chr "Bad Request (HTTP 400). Parameter 'id' must be a number."
#>  $ status : int 400
#>  $ body   :List of 4
#>   ..$ type  : chr "https://tools.ietf.org/html/rfc7231#section-6.5.1"
#>   ..$ title : chr "Bad Request"
#>   ..$ status: int 400
#>   ..$ detail: chr "Parameter 'id' must be a number."
#>   ..- attr(*, "class")= chr [1:2] "http_problem" "list"
#>  - attr(*, "class")= chr [1:4] "http_problem_error" "http_error" "error" "condition"
```

Typically, web frameworks allow you to control how uncaught errors are
reported – which can be combined with these helpers to ensure that all
API errors have a consistent format for your users.

### Use with Plumber

Plumber allows users to control how errors are handled (via
`pr_set_error()`), which we can employ to produce a Problem Details
structure for both expected *and* unexpected errors:

``` r
library(plumber)

pr() %>%
  pr_get("/bad", function(req, res) {
    stop_for_bad_request("The 'id' parameter must be a number.")
  }) %>%
  pr_get("/bug", function(req, res) {
    stop("Another R error.")
  }) %>%
  pr_set_error(function(req, res, err) {
    # Force "unboxed" JSON and the Content-Type from RFC 7807.
    res$serializer <- serializer_unboxed_json(
      type = "application/problem+json"
    )
    # If we have an http_problem_error, use its status and body
    # fields. Otherwise, issue a 500 Internal Server Error.
    if (inherits(err, "http_problem_error")) {
      res$status <- err$status
      return(err$body)
    }
    if (isTRUE(req$pr$getDebug())) {
      internal_server_error(detail = err$message)
    } else {
      internal_server_error()
    }
  }) %>%
  pr_run(port = 4444)
```

Users interacting with this API will see the following:

``` shell
$ curl -vs localhost:4444/bad
> GET /bad HTTP/1.1
> Host: localhost:4444
> User-Agent: curl/7.58.0
> Accept: */*
> 
< HTTP/1.1 400 Bad Request
< Date: Tue, 09 Feb 2021 15:19:33 GMT
< Content-Type: application/problem+json
< Content-Length: 160
< 
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.1",
  "title": "Bad Request",
  "status": 400,
  "detail": "The 'id' parameter must be a number."
}
$ curl -vs localhost:4444/bug
> GET /bug HTTP/1.1
> Host: localhost:4444
> User-Agent: curl/7.58.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< Date: Tue, 09 Feb 2021 15:19:59 GMT
< Content-Type: application/problem+json
< Content-Length: 150
< 
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.6.1",
  "title": "Internal Server Error",
  "status": 500,
  "detail": "Another R error."
}
```

## License

Copyright 2021 Aaron Jacobs

Licensed under the Apache License, Version 2.0 (the “License”); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an “AS IS” BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
