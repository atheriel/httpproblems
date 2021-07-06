# Copyright 2021 Aaron Jacobs
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Describe a Problem with an HTTP Request
#'
#' @description
#'
#' `http_problem()` creates the "Problem Details" structure defined in
#' [RFC 7807](https://tools.ietf.org/html/rfc7807), used for reporting errors
#' from HTTP APIs in a standard way.
#'
#' There are also helper methods for the most common HTTP problems:
#' HTTP 400 Bad Request, 404 Not Found, 401 Unauthorized, 403 Forbidden, 409
#' Conflict, and 500 Internal Server Error.
#'
#' @param detail A human-readable string giving more detail about the error,
#'   if possible.
#' @param status The HTTP status code appropriate for the response.
#' @param type A URL pointing to human-readable documentation for this type of
#'   problem. When `NULL`, the type is generated based on the status code; see
#'   [http_problem_types()] for a list of the defaults.
#' @param title A ["short, human-readable summary of the problem type"](https://tools.ietf.org/html/rfc7807#section-3.1).
#'   When `NULL`, the title is generated based on the status code; see
#'   [http_problem_types()] for a list of the defaults.
#' @param instance A URL that identifies the specific occurrence of the
#'   problem, if possible. When `NULL` this field is simply excluded.
#' @param ... Additional fields added to the problem as [Extension Members](https://tools.ietf.org/html/rfc7807#section-3.2).
#'
#' @return An object of class `"http_problem"`, which has fields corresponding
#'   to [an RFC 7807 Problem Details structure](https://tools.ietf.org/html/rfc7807#section-3.1).
#'
#' @examples
#' body <- bad_request("Parameter 'id' must be a number.")
#' str(body)
#' @seealso [stop_for_http_problem] for issuing R errors with these structures.
#' @export
http_problem <- function(detail = NULL, status = 500L, type = NULL,
                         title = NULL, instance = NULL, ...) {
  if (!is.null(detail) && !is.character(detail)) {
    stop(
      sprintf("'detail' must be a string or omitted, not '%s'.", detail),
      call. = FALSE
    )
  }
  if (!is.null(instance) && !is.character(instance)) {
    stop(
      sprintf("'instance' must be a string or omitted, not '%s'.", instance),
      call. = FALSE
    )
  }
  if (!is.numeric(status)) {
    stop("'status' must be an HTTP status code, not '%s'.", call. = FALSE)
  }
  status_index <- which(status == http_problem_codes$code)
  if (length(status_index) == 0) {
    # NOTE: It's possible that we could allow arbitrary codes and just set
    # "about:blank" as the type (which would be in line with the RFC), but it
    # seems more likely that an unknown code is a programmer error.
    stop(sprintf("Unsupported HTTP status code for reporting problems: '%s'.", status))
  }
  # When not present, use standard title/type fields based on the status code.
  if (is.null(title)) {
    title <- http_problem_codes$reason[status_index]
  }
  if (is.null(type)) {
    type <- http_problem_codes$url[status_index]
  }
  body <- list(type = type, title = title, status = as.integer(status), ...)
  # Only included optional fields if they are non-NULL.
  body$detail <- detail
  body$instance <- instance
  structure(body, class = c("http_problem", "list"))
}

#' @rdname http_problem
#' @export
bad_request <- function(detail = NULL, instance = NULL, ...) {
  http_problem(
    detail = detail, status = 400L, type = NULL, title = NULL,
    instance = instance, ...
  )
}

#' @rdname http_problem
#' @export
unauthorized <- function(detail = NULL, instance = NULL, ...) {
  http_problem(
    detail = detail, status = 401L, type = NULL, title = NULL,
    instance = instance, ...
  )
}

#' @rdname http_problem
#' @export
forbidden <- function(detail = NULL, instance = NULL, ...) {
  http_problem(
    detail = detail, status = 403L, type = NULL, title = NULL,
    instance = instance, ...
  )
}

#' @rdname http_problem
#' @export
not_found <- function(detail = NULL, instance = NULL, ...) {
  http_problem(
    detail = detail, status = 404L, type = NULL, title = NULL,
    instance = instance, ...
  )
}

#' @rdname http_problem
#' @export
conflict <- function(detail = NULL, instance = NULL, ...) {
  http_problem(
    detail = detail, status = 409L, type = NULL, title = NULL,
    instance = instance, ...
  )
}

#' @rdname http_problem
#' @export
internal_server_error <- function(detail = NULL, instance = NULL, ...) {
  http_problem(
    detail = detail, status = 500L, type = NULL, title = NULL,
    instance = instance, ...
  )
}

#' Signal an Error Caused by an HTTP Problem
#'
#' @description
#'
#' The various `stop_for_*()` functions leverage R's condition system to signal
#' an error with a custom type embedding the "Problem Details" structure
#' defined in [RFC 7807](https://tools.ietf.org/html/rfc7807).
#'
#' They can be used for reporting errors from HTTP APIs in a standard way.
#'
#' There are also helper methods for the most common HTTP problems:
#' HTTP 400 Bad Request, 404 Not Found, 401 Unauthorized, 403 Forbidden, 409
#' Conflict, and 500 Internal Server Error.
#'
#' @return These functions call `stop()` with a custom [condition] (with class
#'   `"http_problem_error"`), so they do not return a value.
#'
#' @examples
#' tryCatch(
#'   stop_for_bad_request("Parameter 'id' must be a number."),
#'   error = function(e) {
#'     str(e)
#'   }
#' )
#' @inheritParams http_problem
#' @seealso [http_problem] for creating the structure directly.
#' @export
stop_for_http_problem <- function(detail = NULL, status = 500L, type = NULL,
                                  title = NULL, instance = NULL, ...) {
  problem <- http_problem(
    detail = detail, status = status, type = NULL, title = NULL,
    instance = instance, ...
  )
  if (is.null(problem$detail)) {
    message <- sprintf("%s (HTTP %d).", problem$title, problem$status)
  } else {
    message <- sprintf(
      "%s (HTTP %d). %s", problem$title, problem$status, problem$detail
    )
  }
  cond <- structure(
    list(message = message, status = problem$status, body = problem),
    class = c("http_problem_error", "http_error", "error", "condition")
  )
  # NOTE: stop() will also call signalCondition().
  stop(cond)
}

#' @rdname stop_for_http_problem
#' @export
stop_for_bad_request <- function(detail = NULL, instance = NULL, ...) {
  stop_for_http_problem(
    detail = detail, status = 400L, type = NULL, title = NULL,
    instance = instance, ...
  )
}

#' @rdname stop_for_http_problem
#' @export
stop_for_unauthorized <- function(detail = NULL, instance = NULL, ...) {
  stop_for_http_problem(
    detail = detail, status = 401L, type = NULL, title = NULL,
    instance = instance, ...
  )
}

#' @rdname stop_for_http_problem
#' @export
stop_for_forbidden <- function(detail = NULL, instance = NULL, ...) {
  stop_for_http_problem(
    detail = detail, status = 403L, type = NULL, title = NULL,
    instance = instance, ...
  )
}

#' @rdname stop_for_http_problem
#' @export
stop_for_not_found <- function(detail = NULL, instance = NULL, ...) {
  stop_for_http_problem(
    detail = detail, status = 404L, type = NULL, title = NULL,
    instance = instance, ...
  )
}

#' @rdname stop_for_http_problem
#' @export
stop_for_conflict <- function(detail = NULL, instance = NULL, ...) {
  stop_for_http_problem(
    detail = detail, status = 409L, type = NULL, title = NULL,
    instance = instance, ...
  )
}

#' @rdname stop_for_http_problem
#' @export
stop_for_internal_server_error <- function(detail = NULL, instance = NULL,
                                           ...) {
  stop_for_http_problem(
    detail = detail, status = 500L, type = NULL, title = NULL,
    instance = instance, ...
  )
}

# Adapted from the table at https://tools.ietf.org/html/rfc7231#section-6.1
http_problem_codes <- data.frame(
  code = c(
    400L,
    401L,
    402L,
    403L,
    404L,
    405L,
    406L,
    407L,
    408L,
    409L,
    410L,
    411L,
    412L,
    413L,
    414L,
    415L,
    416L,
    417L,
    426L,
    500L,
    501L,
    502L,
    503L,
    504L,
    505L
  ),
  reason = c(
    "Bad Request",
    "Unauthorized",
    "Payment Required",
    "Forbidden",
    "Not Found",
    "Method Not Allowed",
    "Not Acceptable",
    "Proxy Authentication Required",
    "Request Timeout",
    "Conflict",
    "Gone",
    "Length Required",
    "Precondition Failed",
    "Payload Too Large",
    "URI Too Long",
    "Unsupported Media Type",
    "Range Not Satisfiable",
    "Expectation Failed",
    "Upgrade Required",
    "Internal Server Error",
    "Not Implemented",
    "Bad Gateway",
    "Service Unavailable",
    "Gateway Timeout",
    "HTTP Version Not Supported"
  ),
  url = c(
    "https://tools.ietf.org/html/rfc7231#section-6.5.1",
    "https://tools.ietf.org/html/rfc7235#section-3.1",
    "https://tools.ietf.org/html/rfc7231#section-6.5.2",
    "https://tools.ietf.org/html/rfc7231#section-6.5.3",
    "https://tools.ietf.org/html/rfc7231#section-6.5.4",
    "https://tools.ietf.org/html/rfc7231#section-6.5.5",
    "https://tools.ietf.org/html/rfc7231#section-6.5.6",
    "https://tools.ietf.org/html/rfc7235#section-3.2",
    "https://tools.ietf.org/html/rfc7231#section-6.5.7",
    "https://tools.ietf.org/html/rfc7231#section-6.5.8",
    "https://tools.ietf.org/html/rfc7231#section-6.5.9",
    "https://tools.ietf.org/html/rfc7231#section-6.5.10",
    "https://tools.ietf.org/html/rfc7232#section-4.2",
    "https://tools.ietf.org/html/rfc7231#section-6.5.11",
    "https://tools.ietf.org/html/rfc7231#section-6.5.12",
    "https://tools.ietf.org/html/rfc7231#section-6.5.13",
    "https://tools.ietf.org/html/rfc7233#section-4.4",
    "https://tools.ietf.org/html/rfc7231#section-6.5.14",
    "https://tools.ietf.org/html/rfc7231#section-6.5.15",
    "https://tools.ietf.org/html/rfc7231#section-6.6.1",
    "https://tools.ietf.org/html/rfc7231#section-6.6.2",
    "https://tools.ietf.org/html/rfc7231#section-6.6.3",
    "https://tools.ietf.org/html/rfc7231#section-6.6.4",
    "https://tools.ietf.org/html/rfc7231#section-6.6.5",
    "https://tools.ietf.org/html/rfc7231#section-6.6.6"
  ),
  stringsAsFactors = FALSE
)

#' List Built-In Problem Types
#'
#' Many APIs will not need to define custom problem "types", since HTTP status
#' codes [are usually illustrative enough](https://tools.ietf.org/html/rfc7807#section-4).
#' This function lists the default type and title information for a given
#' status code.
#'
#' @return A data frame of HTTP status codes and their default title & type.
#' @export
http_problem_types <- function() {
  # Reorder/rename the RFC table columns to make them look as they would in the
  # http_problem() output.
  out <- http_problem_codes[, c("code", "url", "reason")]
  names(out) <- c("status", "type", "title")
  out
}
