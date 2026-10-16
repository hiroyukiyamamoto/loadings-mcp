source("tests/pca.R")
demo <- demo_data()
for (method in c("os_pca", "pls_rog", "pls_da", "rcca_da")) {
  d <- if (method == "os_pca") lapply(seq_len(149), function(i) as.list(replace(replace(numeric(150), i, -1), i + 1, 1))) else list(c(-1, 1, 0), c(0, -1, 1))
  result <- analyze_model(method, demo$x, demo$y, d)
  stopifnot(result$ok, result$scores$returned_columns == 2L, result$loadings$total_rows == 4L)
  X <- numeric_matrix(demo$x, "x"); Y <- numeric_matrix(demo$y, "y"); D <- numeric_matrix(d, "d")
  ref <- switch(method,
    os_pca = loadings::ospca_loading(loadings::os_pca(X, D)),
    pls_rog = loadings::plsrog_loading(loadings::pls_rog(X, Y, D)),
    pls_da = loadings::plsda_loading(loadings::pls_da(X, Y, k = 2)),
    rcca_da = loadings::rcca_loading(loadings::rcca_da(X, Y, lambda = .5, k = 2)))
  stopifnot(isTRUE(all.equal(unlist(result$loadings$values[[1]]), unname(ref$loading$R[1,1:2]))))
  cat(method, "passed\n")
}
stopifnot(!analyze_model("unknown", demo$x)$ok,
          !analyze_model("pls_da", demo$x, list(c(1, 0)))$ok,
          !analyze_model("os_pca", demo$x, d = list(c(1, 2)))$ok,
          !analyze_model("rcca_da", demo$x, demo$y, lambda = 0)$ok)
stopifnot(!analyze_pca(list(rows = replicate(501, c(1, 2), simplify = FALSE)))$ok,
          !analyze_pca(list(rows = list(c("a", "b"))))$ok,
          !analyze_pca(list(rows = list(list(NULL, 1))))$ok,
          !analyze_pca(list(rows = list(c(Inf, 1))))$ok)
