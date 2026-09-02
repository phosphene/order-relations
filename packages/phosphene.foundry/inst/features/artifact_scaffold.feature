Feature: Artifact Scaffolding
  As a research scientist
  I want to scaffold a production-grade R analysis package
  So that I can focus on the science, not the engineering

  Scenario: Basic scaffold produces required structure
    Given I scaffold a new artifact called "basic-test"
    Then the artifact should contain a "DESCRIPTION" file
    And the artifact should contain a "R" directory
    And the artifact should contain a "tests/testthat" directory
    And the artifact should contain a ".github/workflows/ci.yml" file
    And the artifact should contain a "run_pipeline.sh" file
    And the artifact should contain a "run_tests.R" file
    And the artifact should contain a "README.md" file
    And the artifact should contain a ".lintr" file
    And the artifact should contain a ".gitignore" file

  Scenario: Scaffold sets the artifact name in DESCRIPTION
    Given I scaffold a new artifact called "named-test" with name "Custom Analysis Name"
    Then the DESCRIPTION Title should be "Custom Analysis Name"

  Scenario: Scaffold with brms includes Stan support
    Given I scaffold a new artifact called "brms-test" with use_brms enabled
    Then the artifact should contain a "inst/stan" directory
    And the DESCRIPTION should include "brms" in Imports

  Scenario: Scaffolded artifact passes foundry validation
    Given I scaffold a new artifact called "valid-test"
    And I add a NAMESPACE file to the artifact
    Then the artifact should pass foundry_validate
