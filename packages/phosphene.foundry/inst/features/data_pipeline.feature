Feature: Data Pipeline Contract Enforcement
  As a data analyst
  I want my pipeline to validate inputs and outputs at every step
  So that bad data can never silently corrupt my results

  Scenario: Valid data frame passes contract
    Given a data frame with columns "id" and "value"
    When I validate the contract requiring columns "id" and "value"
    Then the validation should succeed

  Scenario: Missing columns fail fast with clear error
    Given a data frame with columns "id" only
    When I validate the contract requiring columns "id" and "value"
    Then the validation should fail with message "Missing required columns: value"

  Scenario: Type mismatch is caught at validation
    Given a data frame where column "value" has type "integer"
    When I validate the contract expecting column "value" to be type "double"
    Then the validation should fail with message "expected type"

  Scenario: NA values rejected when policy is strict
    Given a data frame with NA values in column "id"
    When I validate the contract for column "id" with allow_na disabled
    Then the validation should fail with message "NA values"

  Scenario: Pure transform enforces input contract
    Given a data frame with columns "x" only
    When I apply a pure transform requiring input column "y"
    Then the transform should fail with message "Missing required columns: y"

  Scenario: Pure transform enforces output contract
    Given a data frame with columns "a" and "b"
    When I apply a transform that drops column "b" but output requires "a" and "b"
    Then the transform should fail with message "Missing required columns: b"

  Scenario: Transform chain maintains contracts through composition
    Given a data frame with columns "value" containing numbers 1 to 5
    When I apply a transform that doubles the values
    And I apply a transform that labels values above 5 as "high"
    Then the final result should have a "label" column
    And values 1 and 2 should be labeled "low"
    And values 3 4 and 5 should be labeled "high"
