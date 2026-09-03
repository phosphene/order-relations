# test-bdd-analysis.R
# BDD specs for the Beta-Binomial demo analysis.
# describe()/it() blocks map the statistical claims into executable specs.

source("../../R/posterior.R")

describe("Beta-Binomial Bayesian Analysis", {

  describe("Prior specification", {
    it("accepts a uniform Beta(1,1) prior representing no prior knowledge", {
      result <- beta_binomial_posterior(1, 1, 0, 0)
      expect_equal(result$mean, 0.5)
    })

    it("accepts an informative Beta(2,2) prior centered at 0.5", {
      result <- beta_binomial_posterior(2, 2, 0, 0)
      expect_equal(result$mean, 0.5)
      # But with tighter variance than uniform
      uniform <- beta_binomial_posterior(1, 1, 0, 0)
      expect_lt(result$variance, uniform$variance)
    })
  })

  describe("Conjugate updating", {
    it("shifts the posterior toward observed data", {
      # Prior centered at 0.5, but data is 8/10 successes
      result <- beta_binomial_posterior(2, 2, 8, 2)
      expect_gt(result$mean, 0.5)  # shifted toward success rate
    })

    it("gives more weight to data with larger sample sizes", {
      small_n <- beta_binomial_posterior(2, 2, 4, 1)
      large_n <- beta_binomial_posterior(2, 2, 40, 10)
      # Both have same success rate (80%), but large_n closer to 0.8
      expect_lt(abs(large_n$mean - 0.8), abs(small_n$mean - 0.8))
    })

    it("tightens the posterior with more data", {
      few_obs <- beta_binomial_posterior(2, 2, 3, 1)
      many_obs <- beta_binomial_posterior(2, 2, 30, 10)
      expect_lt(many_obs$variance, few_obs$variance)
    })
  })

  describe("Credible intervals", {
    it("produces a 95% credible interval containing the posterior mean", {
      result <- beta_binomial_posterior(2, 2, 8, 2)
      expect_gte(result$mean, result$lower_95)
      expect_lte(result$mean, result$upper_95)
    })

    it("narrows the credible interval with more data", {
      few <- beta_binomial_posterior(2, 2, 5, 2)
      many <- beta_binomial_posterior(2, 2, 50, 20)
      few_width <- few$upper_95 - few$lower_95
      many_width <- many$upper_95 - many$lower_95
      expect_lt(many_width, few_width)
    })
  })

  describe("Data preparation", {
    it("correctly counts successes and failures from binary data", {
      df <- data.frame(outcome = c(1, 1, 1, 0, 1, 1, 0, 1, 1, 1))
      obs <- prepare_observations(df)
      expect_equal(obs$successes, 8)
      expect_equal(obs$failures, 2)
    })

    it("handles missing values by excluding them", {
      df <- data.frame(outcome = c(1, NA, 0, 1, NA))
      obs <- prepare_observations(df)
      expect_equal(obs$successes + obs$failures, 3)
    })
  })

  describe("Result formatting", {
    it("produces a tidy single-row data frame suitable for export", {
      post <- beta_binomial_posterior(2, 2, 8, 2)
      result <- format_posterior(post)

      expect_s3_class(result, "data.frame")
      expect_equal(nrow(result), 1)
      expect_true(all(c("model", "mean", "variance", "lower_95", "upper_95") %in% names(result)))
    })
  })
})
