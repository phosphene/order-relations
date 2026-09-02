# test-bdd-stdd-framework.R
# BDD specs for the Stochastic Test-Driven Development framework.
# describe()/it() blocks map STDD concepts into executable specifications.

describe("Seed Isolation", {

  describe("Reproducibility guarantee", {
    it("produces identical results from the same seed", {
      r1 <- stdd_seed_env(42, rnorm(100))
      r2 <- stdd_seed_env(42, rnorm(100))
      expect_identical(r1, r2)
    })

    it("produces different results from different seeds", {
      r1 <- stdd_seed_env(42, rnorm(100))
      r2 <- stdd_seed_env(99, rnorm(100))
      expect_false(identical(r1, r2))
    })
  })

  describe("State isolation", {
    it("does not leak seed state into the calling environment", {
      set.seed(7)
      before <- runif(1)

      stdd_seed_env(42, rnorm(1000))  # should not affect outer state

      set.seed(7)
      after <- runif(1)

      expect_equal(before, after)
    })

    it("allows nested seed environments without interference", {
      outer <- stdd_seed_env(10, {
        a <- rnorm(5)
        inner <- stdd_seed_env(20, rnorm(5))
        b <- rnorm(5)
        list(a = a, inner = inner, b = b)
      })

      # Reproduce — same outer seed should give same a and b
      outer2 <- stdd_seed_env(10, {
        a <- rnorm(5)
        inner <- stdd_seed_env(20, rnorm(5))
        b <- rnorm(5)
        list(a = a, inner = inner, b = b)
      })

      expect_identical(outer$a, outer2$a)
      expect_identical(outer$b, outer2$b)
      expect_identical(outer$inner, outer2$inner)
    })
  })

  describe("Cross-platform reproducibility", {
    it("specifies RNG kind explicitly for platform independence", {
      result <- stdd_seed_env(42, rnorm(10),
        .rng_kind = "Mersenne-Twister",
        .rng_normal_kind = "Inversion")

      expect_length(result, 10)
      expect_type(result, "double")
    })
  })
})


describe("Parameter Recovery Framework", {

  describe("Linear model recovery", {
    it("recovers intercept and slope from synthetic data", {
      result <- stdd_param_recovery(
        true_params = c(intercept = 5.0, slope = -2.0),
        generate_fn = function(params) {
          x <- rnorm(300)
          y <- params["intercept"] + params["slope"] * x + rnorm(300, sd = 0.5)
          data.frame(x = x, y = y)
        },
        fit_fn = function(data) lm(y ~ x, data = data),
        extract_fn = function(fit) {
          ci <- confint(fit, level = 0.95)
          data.frame(
            parameter = c("intercept", "slope"),
            mean = unname(coef(fit)),
            lower = ci[, 1],
            upper = ci[, 2],
            stringsAsFactors = FALSE
          )
        },
        seed = 42
      )

      expect_true(result$all_recovered)
    })
  })

  describe("Return structure", {
    it("returns a list with recovered, summary, and all_recovered components", {
      result <- stdd_param_recovery(
        true_params = c(mu = 0),
        generate_fn = function(p) data.frame(x = rnorm(100, mean = p["mu"])),
        fit_fn = function(d) list(mean = mean(d$x), se = sd(d$x) / sqrt(nrow(d))),
        extract_fn = function(f) {
          data.frame(
            parameter = "mu",
            mean = f$mean,
            lower = f$mean - 1.96 * f$se,
            upper = f$mean + 1.96 * f$se,
            stringsAsFactors = FALSE
          )
        },
        seed = 42
      )

      expect_type(result, "list")
      expect_true("recovered" %in% names(result))
      expect_true("summary" %in% names(result))
      expect_true("all_recovered" %in% names(result))
      expect_s3_class(result$summary, "data.frame")
    })
  })

  describe("Input validation", {
    it("rejects unnamed parameter vectors", {
      expect_error(
        stdd_param_recovery(
          true_params = c(1, 2),
          generate_fn = identity, fit_fn = identity, extract_fn = identity
        )
      )
    })

    it("rejects extract functions missing required columns", {
      expect_error(
        stdd_param_recovery(
          true_params = c(a = 1),
          generate_fn = function(p) data.frame(x = 1:10),
          fit_fn = function(d) lm(x ~ 1, data = d),
          extract_fn = function(f) data.frame(parameter = "a", mean = 1)
        ),
        "extract_fn must return columns"
      )
    })
  })
})


describe("Convergence Diagnostics", {

  describe("Passing diagnostics", {
    it("reports all_converged = TRUE when all parameters pass", {
      check <- stdd_convergence_check(
        rhat_values = c(1.00, 1.01, 1.02),
        ess_values = c(1500, 1200, 900),
        param_names = c("alpha", "beta", "sigma")
      )
      expect_true(check$all_converged)
      expect_true(all(check$report$converged))
    })
  })

  describe("Failing diagnostics", {
    it("flags parameters with R-hat above threshold", {
      check <- stdd_convergence_check(
        rhat_values = c(1.01, 1.15),
        ess_values = c(1000, 1000),
        param_names = c("good", "bad")
      )
      expect_false(check$all_converged)
      expect_true(check$rhat_ok[1])
      expect_false(check$rhat_ok[2])
    })

    it("flags parameters with ESS below threshold", {
      check <- stdd_convergence_check(
        rhat_values = c(1.01, 1.01),
        ess_values = c(800, 50),
        param_names = c("good", "bad")
      )
      expect_false(check$all_converged)
      expect_true(check$ess_ok[1])
      expect_false(check$ess_ok[2])
    })
  })

  describe("Report structure", {
    it("returns a data frame with per-parameter diagnostics", {
      check <- stdd_convergence_check(
        rhat_values = c(1.01, 1.02),
        ess_values = c(800, 600),
        param_names = c("a", "b")
      )

      report <- check$report
      expect_s3_class(report, "data.frame")
      expect_equal(names(report), c("parameter", "rhat", "rhat_ok", "ess", "ess_ok", "converged"))
      expect_equal(nrow(report), 2)
    })
  })
})
