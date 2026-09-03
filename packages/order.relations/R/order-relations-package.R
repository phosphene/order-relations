#' order.relations: Synergetics Abstraction Program
#'
#' Substrate-free implementations of the synergetics abstraction inventory:
#' two-variable systems, direction-free slaving, adiabatic elimination,
#' bi-exponential relaxation, threshold windows, critical slowing down.
#'
#' Design law (Ed Phil, 2026-09-02): order-relations is a place for the
#' *abstract*. Every object here must be stateable with zero biological
#' nouns. Biology enters only at instantiation time, via the mapping
#' table in `flytrap.R`.
#'
#' @keywords internal
"_PACKAGE"

## Package-level constants (pure, no state)
## Published flytrap anchors (Di Palma et al.; Yokawa et al. 2018)
FLYTRAP_TAU1 <- 8.0        # s  — Ca2+ integrator relaxation
FLYTRAP_TAU2 <- 3.0 * 86400  # s  — digestion program timescale (~3 d)
FLYTRAP_A_THETA <- 0.952   # a/theta at zero dose
FLYTRAP_BRACKET <- c(20, 30)  # s  — published integration window bracket
