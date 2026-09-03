#' Safely compute concept lattice with dimension and density guards
#'
#' A circuit breaker that prevents excessive compute on large, dense formal
#' contexts. Checks attribute count and matrix density against configurable
#' thresholds. If both exceed their respective limits, evaluation is aborted
#' with an informative error. Otherwise, computes both the concept lattice
#' and the implication set.
#'
#' @param fc An \code{fcaR::FormalContext} R6 object.
#' @param max_attributes Integer threshold for the number of attributes
#'   (columns). Default 50.
#' @param max_density Numeric threshold for matrix density (proportion of 1s).
#'   Default 0.85.
#'
#' @return The same \code{FormalContext} object, now with concepts and
#'   implications computed.
#'
#' @examples
#' \donttest{
#' library(fcaR)
#' I <- matrix(sample(0:1, 30, replace = TRUE), nrow = 5, ncol = 6)
#' fc <- FormalContext$new(I)
#' fc <- safe_compute_lattice(fc, max_attributes = 50, max_density = 0.85)
#' }
#'
#' @export
safe_compute_lattice <- function(fc, max_attributes = 50, max_density = 0.85) {
  safety <- check_lattice_safety(fc, max_attributes, max_density)

  if (!safety$safe) {
    stop(safety$reason, call. = FALSE)
  }

  fc$find_concepts(verbose = FALSE)
  fc$find_implications(verbose = FALSE)
  fc
}


#' Check whether a formal context is safe for lattice computation
#'
#' Evaluates the attribute count and density of a formal context against
#' configurable thresholds without performing any computation on the context
#' itself. Useful for pre-validation before calling
#' \code{\link{safe_compute_lattice}}.
#'
#' @param fc An \code{fcaR::FormalContext} R6 object.
#' @param max_attributes Integer threshold for the number of attributes.
#' @param max_density Numeric threshold for matrix density.
#'
#' @return A named list with four elements:
#' \describe{
#'   \item{safe}{Logical. \code{TRUE} when both thresholds are satisfied.}
#'   \item{n_attributes}{Integer number of attributes in the context.}
#'   \item{density}{Numeric density of the incidence matrix.}
#'   \item{reason}{Character string explaining the result. Empty when safe.}
#' }
#'
#' @examples
#' \donttest{
#' library(fcaR)
#' I <- matrix(sample(0:1, 30, replace = TRUE), nrow = 5, ncol = 6)
#' fc <- FormalContext$new(I)
#' check_lattice_safety(fc, max_attributes = 50, max_density = 0.85)
#' }
#'
#' @export
check_lattice_safety <- function(fc, max_attributes, max_density) {
  stopifnot(inherits(fc, "FormalContext"))

  # fc$I has attributes as rows, objects as columns
  m_count <- nrow(fc$I)
  total_cells <- length(fc$I)
  density <- sum(fc$I > 0) / total_cells

  if (m_count > max_attributes && density > max_density) {
    reason <- sprintf(
      "circuit breaker: %d attributes x density %.3f exceeds (%d, %.2f)",
      m_count, density, max_attributes, max_density
    )
    return(list(
      safe = FALSE,
      n_attributes = m_count,
      density = density,
      reason = reason
    ))
  }

  list(
    safe = TRUE,
    n_attributes = m_count,
    density = density,
    reason = ""
  )
}