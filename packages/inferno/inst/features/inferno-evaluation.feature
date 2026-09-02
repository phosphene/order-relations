Feature: INFERNO 7-Layer Evaluation Pipeline
  As a research evaluator
  I want to run the full INFERNO protocol on a research artifact
  So that I get a reproducible, structured credibility assessment

  Scenario: Full evaluation of a model produces 7-layer result
    Given an evaluation target of type "model" with 3 claims
    And an axiom set with 3 objects and 4 attributes
    When I run the full INFERNO evaluation
    Then the result should have 7 layer results
    And the WCI should have 6 dimensions plus a composite score
    And all WCI scores should be between 0 and 1
    And the overall verdict should be a non-empty string

  Scenario: Evaluation with degenerate axiom set produces low WCI
    Given an evaluation target with 1 purely theoretical claim
    And an axiom set with an empty formal context
    When I run the full INFERNO evaluation
    Then the WCI composite should be below 0.5
    And layer 1 should report a gap diagnosis

  Scenario: Render produces valid JSON
    Given a completed INFERNO evaluation
    When I render the result as JSON
    Then the output should be parseable as JSON
    And the parsed JSON should contain the WCI scores
    And the parsed JSON should contain all 7 layer results

  Scenario: Render produces human-readable markdown
    Given a completed INFERNO evaluation
    When I render the result as markdown
    Then the output should contain "INFERNO Evaluation"
    And the output should contain "WCI"
    And the output should contain a layer summary table
