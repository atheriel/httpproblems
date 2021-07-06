# httpproblems 1.0.1.9000

# httpproblems 1.0.1

* Removes the `LazyData` field from the `DESCRIPTION` file, which was generating
  a NOTE in CRAN's automated checking.

# httpproblems 1.0.0

* Initial release. **httpproblems** provides tools for emitting the "Problem
  Details" structure defined in [RFC 7807](https://tools.ietf.org/html/rfc7807).
  It is intended to help R users report errors from HTTP APIs in a consistent,
  standard way.
  
* Provides `http_problem()` for creating the Problem Details structure, plus
  several helper functions for HTTP 400 Bad Request, 404 Not Found, 401
  Unauthorized, 403 Forbidden, 409 Conflict, and 500 Internal Server Error.

* Provides `stop_for_*()` variants that signal a custom condition for these
  problems.

* Provides `http_problem_types()` for listing built-in type and title entries.
