Feature: Beta-Binomial Analysis Pipeline
  As a research collaborator
  I want to run the full Bayesian analysis from raw data to results
  So that I can verify the statistical claims independently

  Scenario: Posterior update with observed data
    Given a Beta(2, 2) prior
    And 8 observed successes and 2 observed failures
    When I compute the posterior
    Then the posterior mean should be approximately 0.714
    And the posterior should have alpha = 10 and beta = 4

  Scenario: Uniform prior with no observations
    Given a Beta(1, 1) prior
    And 0 observed successes and 0 observed failures
    When I compute the posterior
    Then the posterior mean should be exactly 0.5

  Scenario: Data preparation from CSV format
    Given observation data with 8 successes and 2 failures
    When I prepare the observations
    Then the success count should be 8
    And the failure count should be 2

  Scenario: Results formatted as tidy data frame
    Given a computed posterior with mean 0.714
    When I format the results
    Then the output should be a data frame with 1 row
    And it should contain columns model mean variance lower_95 upper_95
