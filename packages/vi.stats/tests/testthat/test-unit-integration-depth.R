# Unit tests for integration_depth_rank

test_that("integration_depth_rank classifies housekeeping genes as rank 1", {
  genes <- c("RPL5", "RPS10", "ACTB", "TUBA1A", "HSPA8", "UBB")
  ranks <- integration_depth_rank(genes)
  expect_true(all(ranks == 1L))
})

test_that("integration_depth_rank classifies core machinery as rank 2", {
  genes <- c("POLR2A", "GTF2B", "CDK7", "POLA1")
  ranks <- integration_depth_rank(genes)
  expect_true(all(ranks == 2L))
})

test_that("integration_depth_rank classifies cell cycle as rank 3", {
  genes <- c("CDK1", "CCNB1", "MKI67", "TOP2A", "BUB1", "AURKA")
  ranks <- integration_depth_rank(genes)
  expect_true(all(ranks == 3L))
})

test_that("integration_depth_rank classifies signaling as rank 4", {
  genes <- c("MAPK1", "AKT1", "PIK3CA", "KRAS", "STAT3")
  ranks <- integration_depth_rank(genes)
  expect_true(all(ranks == 4L))
})

test_that("integration_depth_rank classifies tissue/immune as rank 5", {
  genes <- c("KRT5", "COL1A1", "IGHG1", "IL6", "TLR4", "CXCL8")
  ranks <- integration_depth_rank(genes)
  expect_true(all(ranks == 5L))
})

test_that("integration_depth_rank returns 0 for unclassified", {
  genes <- c("UNKNOWN1", "FOOBAR", "XYZ123")
  ranks <- integration_depth_rank(genes)
  expect_true(all(ranks == 0L))
})

test_that("integration_depth_rank is case-insensitive", {
  lower <- integration_depth_rank(c("rpl5", "actb"))
  upper <- integration_depth_rank(c("RPL5", "ACTB"))
  expect_equal(lower, upper)
})

test_that("integration_depth_rank returns named vector", {
  genes <- c("RPL5", "MKI67", "KRT5")
  ranks <- integration_depth_rank(genes)
  expect_named(ranks, genes)
})

test_that("integration_depth_rank handles empty input", {
  expect_equal(integration_depth_rank(character(0)), integer(0))
})
