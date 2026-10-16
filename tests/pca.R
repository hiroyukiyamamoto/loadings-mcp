if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
source("R/utils.R"); source("R/analysis.R")
x <- lapply(seq_len(nrow(iris)), function(i) unname(as.numeric(iris[i, 1:4])))
result <- analyze_pca(x)
stopifnot(result$ok, result$scores$returned_rows == 100L, result$scores$truncated,
          length(result$eigenvalues) == 2L)
reference <- loadings::pca_loading(prcomp(iris[, 1:4], scale. = TRUE))
stopifnot(isTRUE(all.equal(unlist(result$loadings$values[[1]]), unname(reference$loading$R[1, 1:2]))))
stopifnot(!analyze_pca(list(c(1, 1), c(1, 1), c(1, 1), c(1, 1)))$ok,
          !analyze_pca(list(c(1, 2), c(3)))$ok,
          !analyze_pca(x, components = 0)$ok,
          !analyze_pca(x, max_rows = 501)$ok,
          !analyze_pca(list(c(NA, 2)))$ok)
cat("PCA MVP: reference comparison, truncation and invalid inputs passed.\n")
