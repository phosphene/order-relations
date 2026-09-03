# test-bdd-scaffold.R
# BDD specs for the Foundry artifact scaffolding system.
# describe()/it() blocks map scaffolding requirements into executable specs.

describe("Foundry Scaffold", {

  describe("Directory structure generation", {
    it("creates all required directories for a standard artifact", {
      tmp <- file.path(tempdir(), paste0("bdd-dirs-", Sys.getpid()))
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      foundry_scaffold(tmp, name = "Dir Test")

      required_dirs <- c("R", "tests/testthat", "data", "data-raw",
                          "results", "man", ".github/workflows", "docs")
      for (d in required_dirs) {
        expect_true(dir.exists(file.path(tmp, d)),
          info = paste("Missing directory:", d))
      }
    })

    it("creates the inst/stan directory when use_brms = TRUE", {
      tmp <- file.path(tempdir(), paste0("bdd-brms-", Sys.getpid()))
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      foundry_scaffold(tmp, name = "Brms Dir Test", use_brms = TRUE)

      expect_true(dir.exists(file.path(tmp, "inst", "stan")))
    })

    it("does not create inst/stan when use_brms = FALSE", {
      tmp <- file.path(tempdir(), paste0("bdd-nobrms-", Sys.getpid()))
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      foundry_scaffold(tmp, name = "No Brms Test", use_brms = FALSE)

      expect_false(dir.exists(file.path(tmp, "inst", "stan")))
    })
  })

  describe("DESCRIPTION generation", {
    it("produces a valid DCF-parseable DESCRIPTION file", {
      tmp <- file.path(tempdir(), paste0("bdd-desc-", Sys.getpid()))
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      foundry_scaffold(tmp, name = "DCF Test")

      desc <- read.dcf(file.path(tmp, "DESCRIPTION"))
      expect_true("Package" %in% colnames(desc))
      expect_true("Title" %in% colnames(desc))
    })

    it("sets the artifact name as the Title field", {
      tmp <- file.path(tempdir(), paste0("bdd-title-", Sys.getpid()))
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      foundry_scaffold(tmp, name = "My Custom Analysis")

      desc <- read.dcf(file.path(tmp, "DESCRIPTION"))
      expect_equal(unname(desc[1, "Title"]), "My Custom Analysis")
    })

    it("includes brms in Imports when use_brms = TRUE", {
      tmp <- file.path(tempdir(), paste0("bdd-brms-desc-", Sys.getpid()))
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      foundry_scaffold(tmp, name = "Brms Desc Test", use_brms = TRUE)

      desc_text <- readLines(file.path(tmp, "DESCRIPTION"))
      expect_true(any(grepl("brms", desc_text)))
    })

    it("requires R >= 4.4.0", {
      tmp <- file.path(tempdir(), paste0("bdd-rver-", Sys.getpid()))
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      foundry_scaffold(tmp, name = "R Version Test")

      desc_text <- readLines(file.path(tmp, "DESCRIPTION"))
      expect_true(any(grepl("R \\(>= 4\\.4\\.0\\)", desc_text)))
    })
  })

  describe("CI workflow generation", {
    it("creates a GitHub Actions CI workflow file", {
      tmp <- file.path(tempdir(), paste0("bdd-ci-", Sys.getpid()))
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      foundry_scaffold(tmp, name = "CI Test")

      ci_path <- file.path(tmp, ".github", "workflows", "ci.yml")
      expect_true(file.exists(ci_path))
    })

    it("includes lint, test, and coverage stages in the workflow", {
      tmp <- file.path(tempdir(), paste0("bdd-stages-", Sys.getpid()))
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      foundry_scaffold(tmp, name = "Stages Test")

      ci_text <- readLines(file.path(tmp, ".github", "workflows", "ci.yml"))
      ci_blob <- paste(ci_text, collapse = "\n")
      expect_true(grepl("lint", ci_blob, ignore.case = TRUE))
      expect_true(grepl("test", ci_blob, ignore.case = TRUE))
      expect_true(grepl("coverage", ci_blob, ignore.case = TRUE))
    })

    it("uses Rocker container in the workflow", {
      tmp <- file.path(tempdir(), paste0("bdd-rocker-", Sys.getpid()))
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      foundry_scaffold(tmp, name = "Rocker Test")

      ci_text <- paste(readLines(file.path(tmp, ".github", "workflows", "ci.yml")),
                        collapse = "\n")
      expect_true(grepl("rocker/r-ver", ci_text))
    })
  })

  describe("Supporting files", {
    it("generates a .lintr configuration", {
      tmp <- file.path(tempdir(), paste0("bdd-lintr-", Sys.getpid()))
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      foundry_scaffold(tmp, name = "Lintr Test")

      lintr_text <- readLines(file.path(tmp, ".lintr"))
      expect_true(any(grepl("snake_case", lintr_text)))
    })

    it("generates an executable run_pipeline.sh", {
      tmp <- file.path(tempdir(), paste0("bdd-pipeline-", Sys.getpid()))
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      foundry_scaffold(tmp, name = "Pipeline Test")

      pipeline_path <- file.path(tmp, "run_pipeline.sh")
      expect_true(file.exists(pipeline_path))

      # Check it's executable (on Unix)
      if (.Platform$OS.type == "unix") {
        info <- file.info(pipeline_path)
        # mode includes execute bits
        expect_true(as.integer(info$mode) > 0)
      }
    })

    it("generates a README referencing the artifact name", {
      tmp <- file.path(tempdir(), paste0("bdd-readme-", Sys.getpid()))
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      foundry_scaffold(tmp, name = "Readme Name Test")

      readme_text <- paste(readLines(file.path(tmp, "README.md")), collapse = "\n")
      expect_true(grepl("Readme Name Test", readme_text))
    })
  })
})


describe("Foundry Validate", {

  describe("Detecting missing structure", {
    it("reports errors for empty directories", {
      tmp <- file.path(tempdir(), paste0("bdd-empty-", Sys.getpid()))
      dir.create(tmp, showWarnings = FALSE)
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      result <- foundry_validate(tmp)
      expect_false(result$valid)
      expect_true(length(result$errors) > 0)
    })

    it("lists all missing required files", {
      tmp <- file.path(tempdir(), paste0("bdd-missing-", Sys.getpid()))
      dir.create(tmp, showWarnings = FALSE)
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      result <- foundry_validate(tmp)
      expect_true(any(grepl("DESCRIPTION", result$errors)))
      expect_true(any(grepl("R/", result$errors)))
      expect_true(any(grepl("tests/", result$errors)))
    })
  })

  describe("Validating scaffolded artifacts", {
    it("passes validation on a freshly scaffolded artifact", {
      tmp <- file.path(tempdir(), paste0("bdd-valid-", Sys.getpid()))
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      foundry_scaffold(tmp, name = "Validation Test")
      writeLines("# auto", file.path(tmp, "NAMESPACE"))

      result <- foundry_validate(tmp)
      expect_true(result$valid)
    })

    it("warns about missing optional files in strict mode", {
      tmp <- file.path(tempdir(), paste0("bdd-strict-", Sys.getpid()))
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

      foundry_scaffold(tmp, name = "Strict Test")
      writeLines("# auto", file.path(tmp, "NAMESPACE"))
      unlink(file.path(tmp, "LICENSE"))  # remove optional file

      result <- foundry_validate(tmp, strict = TRUE)
      expect_true(result$valid)  # still valid
      expect_true(any(grepl("LICENSE", result$warnings)))
    })
  })
})
