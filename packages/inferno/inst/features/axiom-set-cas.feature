Feature: Axiom Set Content-Addressable Storage
  As a system architect
  I want axiom sets to be content-addressable and deduplicated
  So that identical formal contexts never produce conflicting evaluations

  Scenario: Identical incidence matrices produce the same hash
    Given an axiom set with a 3x4 incidence matrix
    When I compute the content hash
    And I create a second axiom set with the same matrix but permuted rows and columns
    And I compute its content hash
    Then both hashes should be identical

  Scenario: Different incidence matrices produce different hashes
    Given an axiom set with a specific incidence matrix
    And another axiom set with a different incidence matrix
    When I compute both content hashes
    Then the hashes should differ

  Scenario: Axiom set survives DuckDB round-trip
    Given an axiom set persisted to DuckDB
    When I load it back by context hash
    Then the incidence matrix should be identical
    And the domain mapping should be preserved
    And the metric should be preserved

  Scenario: Circuit breaker prevents combinatorial explosion
    Given a formal context with 100 attributes and 0.95 density
    When I attempt to compute the concept lattice
    Then an error should be raised containing "Circuit Breaker"

  Scenario: Empty context produces minimal lattice
    Given a formal context with all zeros
    When I compute the concept lattice safely
    Then at least 1 concept should exist
    And no error should occur

  Scenario: Full context produces single concept
    Given a formal context with all ones
    When I compute the concept lattice safely
    Then exactly 1 concept should exist
