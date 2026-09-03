Feature: Stochastic Test-Driven Development
  As a Bayesian researcher
  I want deterministic test infrastructure for stochastic code
  So that my MCMC tests are reproducible and meaningful

  Scenario: Seed isolation produces reproducible results
    Given a seed value of 42
    When I generate 100 normal random draws under seed isolation
    And I generate another 100 draws under the same seed
    Then both draw vectors should be identical

  Scenario: Different seeds produce different results
    Given seeds 42 and 99
    When I generate 100 draws under each seed
    Then the two draw vectors should differ

  Scenario: Seed isolation does not leak into calling environment
    Given the outer RNG state is set to seed 7
    When I run a computation under isolated seed 42
    Then the outer RNG state should be unchanged

  Scenario: Parameter recovery succeeds with known linear model
    Given true parameters intercept 2.0 and slope 0.5
    When I generate 500 synthetic data points and fit a linear model
    Then all parameters should fall within the 95 percent confidence interval

  Scenario: Convergence check passes with good diagnostics
    Given R-hat values of 1.01 and 1.00 and 1.02
    And ESS values of 1200 and 800 and 950
    When I run stdd_convergence_check
    Then all parameters should be flagged as converged

  Scenario: Convergence check flags bad R-hat
    Given R-hat values of 1.01 and 1.15
    And ESS values of 1200 and 800
    When I run stdd_convergence_check
    Then the second parameter should be flagged as not converged
