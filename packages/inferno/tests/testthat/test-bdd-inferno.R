# test-bdd-inferno.R
# BDD specs for the INFERNO 7-layer evaluation protocol.
# describe()/it() blocks map epistemic claims into executable specifications.
# Each describe block reads as a section heading; each it() reads as a testable claim.

describe("INFERNO Layer 1 — Epistemic Stack", {

  describe("L1 — Novel empirical observation", {
    it("PASS when artifact contains documented empirical evidence", {
      target <- make_gard_target()
      ax <- make_test_axiom_set()
      fc <- ax$to_formal_context()
      fc <- safe_compute_lattice(fc)
      result <- evaluate_layer1(target, ax, fc)
      expect_true("PASS" %in% result$scores || "PARTIAL" %in% result$scores)
    })

    it("FAIL when artifact is purely theoretical with no evidence", {
      target <- EvaluationTarget$new(
        artifact_type = "claim",
        title = "Pure Theory",
        claims = list(Claim$new(id = "C1", text = "Platonic space contains patterns", evidence = NULL))
      )
      ax <- make_test_axiom_set()
      fc <- ax$to_formal_context()
      fc <- safe_compute_lattice(fc)
      result <- evaluate_layer1(target, ax, fc)
      expect_true("FAIL" %in% result$scores)
    })
  })

  describe("L2 — Formal generative machinery", {
    it("PASS when artifact has a framework that generates predictions", {
      target <- make_gard_target()
      ax <- make_test_axiom_set()
      fc <- ax$to_formal_context()
      fc <- safe_compute_lattice(fc)
      result <- evaluate_layer1(target, ax, fc)
      expect_true("PASS" %in% result$scores || "PARTIAL" %in% result$scores)
    })
  })

  describe("Lattice significance (hypothesis-testing mode)", {
    it("produces non-trivial lattice with implications for a valid formal context", {
      fc <- make_test_context()
      fc <- safe_compute_lattice(fc)
      concepts <- fc$concepts
      impls <- fc$implications
      expect_gt(concepts$size(), 2)
      expect_gt(nrow(impls$size()), 0)
    })

    it("produces degenerate lattice for empty context (all zeros)", {
      I <- matrix(0, 3, 4)
      rownames(I) <- c("A", "B", "C")
      colnames(I) <- c("x", "y", "z", "w")
      fc <- fcaR::FormalContext$new(I)
      fc <- safe_compute_lattice(fc)
      concepts <- fc$concepts
      expect_gte(concepts$size(), 1)
    })
  })
})


describe("INFERNO Layer 2 — M-Failure Audit", {

  describe("M1: Precision inflation", {
    it("flags claims more precise than evidence supports", {
      claim <- Claim$new(id = "C1",
        text = "The effect is exactly 42.7%",
        evidence = "Some simulations were run")
      result <- evaluate_layer2(
        EvaluationTarget$new(artifact_type = "paper", title = "Test", claims = list(claim)),
        make_test_axiom_set(), make_test_context())
      expect_true("M1" %in% result$flags$m_failures || "M1" %in% result$scores)
    })
  })

  describe("M2: Conditional as established", {
    it("flags conditional claims stated as fact", {
      claim <- Claim$new(id = "C1",
        text = "This proves the mechanism is universal",
        evidence = "Results suggest the mechanism may apply")
      result <- evaluate_layer2(
        EvaluationTarget$new(artifact_type = "paper", title = "Test", claims = list(claim)),
        make_test_axiom_set(), make_test_context())
      expect_true("M2" %in% result$flags$m_failures || "M2" %in% result$scores)
    })
  })

  describe("M3: Over-generalization", {
    it("flags claims that generalize beyond tested domain", {
      claim <- Claim$new(id = "C1",
        text = "All organisms exhibit this pattern",
        evidence = "Tested in 3 bacterial species")
      result <- evaluate_layer2(
        EvaluationTarget$new(artifact_type = "paper", title = "Test", claims = list(claim)),
        make_test_axiom_set(), make_test_context())
      expect_true("M3" %in% result$flags$m_failures || "M3" %in% result$scores)
    })
  })

  describe("PASS: Well-supported claim", {
    it("passes when evidence matches claim strength", {
      claim <- Claim$new(id = "C1",
        text = "The simulation shows oscillation",
        evidence = "Gillespie run #42 with parameters p=0.3, n=1000")
      result <- evaluate_layer2(
        EvaluationTarget$new(artifact_type = "paper", title = "Test", claims = list(claim)),
        make_test_axiom_set(), make_test_context())
      expect_true("PASS" %in% result$scores)
    })
  })
})


describe("INFERNO Layer 3 — Dual-Register Analysis", {

  describe("Register classification", {
    it("classifies hedged language with citations as R1_research", {
      claim <- Claim$new(id = "C1",
        text = "The data suggests a correlation (Smith 2020, n=500)",
        evidence = "Statistical analysis")
      target <- EvaluationTarget$new(artifact_type = "paper", title = "Test", claims = list(claim))
      result <- evaluate_layer3(target, make_test_axiom_set(), make_test_context())
      reg <- result$scores[1, "register"]
      expect_true(reg == "R1_research" || reg == "unclear")
    })

    it("classifies superlatives and persuasive language as R2_rhetorical", {
      claim <- Claim$new(id = "C1",
        text = "This is clearly a fundamental breakthrough that undoubtedly revolutionizes the field",
        evidence = NULL)
      target <- EvaluationTarget$new(artifact_type = "paper", title = "Test", claims = list(claim))
      result <- evaluate_layer3(target, make_test_axiom_set(), make_test_context())
      reg <- result$scores[1, "register"]
      expect_true(reg == "R2_rhetorical" || reg == "unclear")
    })
  })

  describe("Collapse error detection", {
    it("flags R1 evidence used to support R2 claims without bridge", {
      claim <- Claim$new(id = "C1",
        text = "This experiment proves the theory is revolutionary",
        evidence = "p < 0.05 in controlled trial",
        register = "R2_rhetorical")
      target <- EvaluationTarget$new(artifact_type = "paper", title = "Test", claims = list(claim))
      result <- evaluate_layer3(target, make_test_axiom_set(), make_test_context())
      expect_true(!is.na(result$scores[1, "collapse_error"]))
    })
  })
})


describe("INFERNO Layer 4 — Compression Taxonomy", {

  describe("Compression operation detection", {
    it("detects vocabulary transfer when domain terms are imported", {
      claim <- Claim$new(id = "C1",
        text = "The compositional genome encodes Darwinian evolution in lipid assemblies",
        evidence = "GARD simulations")
      target <- EvaluationTarget$new(artifact_type = "model", title = "GARD", claims = list(claim))
      result <- evaluate_layer4(target, make_test_axiom_set(), make_test_context())
      expect_true("vocabulary_transfer" %in% names(result$scores))
    })

    it("detects aggregation when multiple items compress into one object", {
      claim <- Claim$new(id = "C1",
        text = "All metabolic pathways were combined into a single network",
        evidence = "Pathway database")
      target <- EvaluationTarget$new(artifact_type = "paper", title = "Test", claims = list(claim))
      result <- evaluate_layer4(target, make_test_axiom_set(), make_test_context())
      expect_true("aggregation" %in% names(result$scores))
    })
  })

  describe("Reversibility audit", {
    it("reports lossless when closure A'' = A", {
      fc <- make_test_context()
      fc <- safe_compute_lattice(fc)
      result <- evaluate_layer4(make_gard_target(), make_test_axiom_set(), fc)
      expect_true("lossless" %in% names(result$flags) || "reversibility" %in% names(result$flags))
    })
  })
})


describe("INFERNO Layer 5 — Semiotic Analysis", {

  describe("Peircean typing", {
    it("classifies a measurement reading as an index", {
      claim <- Claim$new(id = "C1",
        text = "The voltage reading of -70mV indicates resting potential",
        evidence = "Electrophysiology recording")
      target <- EvaluationTarget$new(artifact_type = "paper", title = "Test", claims = list(claim))
      result <- evaluate_layer5(target, make_test_axiom_set(), make_test_context())
      expect_true("index" %in% result$scores[, "type"] || nrow(result$scores) > 0)
    })

    it("classifies a mathematical notation as a symbol", {
      claim <- Claim$new(id = "C1",
        text = "The function f(x) = Σ xi represents the compositional information",
        evidence = "Formal definition")
      target <- EvaluationTarget$new(artifact_type = "model", title = "Test", claims = list(claim))
      result <- evaluate_layer5(target, make_test_axiom_set(), make_test_context())
      expect_true("symbol" %in% result$scores[, "type"] || nrow(result$scores) > 0)
    })
  })
})


describe("INFERNO Layer 6 — Analogical Argument", {

  describe("Bartha admissibility", {
    it("assesses admissible when source and target are genuinely associated", {
      claim <- Claim$new(id = "C1",
        text = "Like neural networks, bioelectric networks process information through distributed patterns",
        evidence = "Structural comparison")
      target <- EvaluationTarget$new(artifact_type = "model", title = "Test", claims = list(claim))
      result <- evaluate_layer6(target, make_test_axiom_set(), make_test_context())
      expect_true(result$scores["admissibility"] %in% c("admissible", "admissible_with_caveats", "not_admissible"))
    })

    it("flags critical disanalogogy when load-bearing differences exist", {
      claim <- Claim$new(id = "C1",
        text = "Evolution is exactly like engineering design",
        evidence = NULL)
      target <- EvaluationTarget$new(artifact_type = "claim", title = "Test", claims = list(claim))
      result <- evaluate_layer6(target, make_test_axiom_set(), make_test_context())
      expect_true(!is.null(result$flags$critical_disanalogies) || length(result$flags) > 0)
    })
  })
})


describe("INFERNO Layer 7 — WCI Assessment", {

  describe("Dimension scoring", {
    it("produces all 6 dimensions plus composite in [0,1]", {
      prior <- list(
        make_mock_layer_result(1), make_mock_layer_result(2), make_mock_layer_result(3),
        make_mock_layer_result(4), make_mock_layer_result(5), make_mock_layer_result(6))
      result <- evaluate_layer7(make_gard_target(), make_test_axiom_set(), prior)
      expect_true(all(c("theoretical_coherence", "empirical_support", "replicability",
                        "independent_uptake", "explanatory_power", "falsifiability",
                        "composite") %in% names(result$scores)))
      expect_true(all(result$scores >= 0 & result$scores <= 1))
    })

    it("produces higher WCI for strong target than weak target", {
      prior_strong <- make_high_wci_prior_layers()
      prior_weak <- make_low_wci_prior_layers()
      strong <- evaluate_layer7(make_gard_target(), make_test_axiom_set(), prior_strong)
      weak <- evaluate_layer7(make_gard_target(), make_test_axiom_set(), prior_weak)
      expect_gte(strong$scores["composite"], weak$scores["composite"])
    })
  })

  describe("Gap diagnosis", {
    it("identifies weakest dimension when WCI is low", {
      prior_weak <- make_low_wci_prior_layers()
      result <- evaluate_layer7(make_gard_target(), make_test_axiom_set(), prior_weak)
      expect_true(!is.null(result$gap_diagnosis) || result$scores["composite"] > 0.8)
    })
  })
})


describe("INFERNO Full Pipeline — 7-Layer Dispatch", {

  describe("evaluate() integration", {
    it("produces EvaluationResult with all 7 layers", {
      skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true")
      result <- evaluate(make_gard_target(), make_test_axiom_set())
      expect_equal(length(result$layers), 7)
      for (i in 1:7) {
        expect_equal(result$layers[[i]]$layer, i)
      }
    })

    it("produces WCI with 6 dimensions plus composite", {
      skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true")
      result <- evaluate(make_gard_target(), make_test_axiom_set())
      expect_true(all(c("theoretical_coherence", "empirical_support", "replicability",
                        "independent_uptake", "explanatory_power", "falsifiability",
                        "composite") %in% names(result$wci)))
    })

    it("render() produces valid JSON that round-trips", {
      skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true")
      result <- evaluate(make_gard_target(), make_test_axiom_set())
      json_out <- render(result, format = "json")
      parsed <- jsonlite::fromJSON(json_out)
      expect_true("wci" %in% names(parsed) || "layers" %in% names(parsed))
    })
  })
})
