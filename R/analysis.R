analyze_pca <- function(x, components = 2L, max_rows = 100L) safe_analysis({
  X <- numeric_matrix(x, "x", 4L)
  k <- scalar_integer(components, "components", 1L, min(10L, ncol(X), nrow(X) - 1L))
  limit <- scalar_integer(max_rows, "max_rows", 1L, 500L)
  if (any(apply(X, 2, stats::sd) == 0)) fail("x contains a constant column")
  # Full prcomp is required: pca_loading uses the complete importance vector.
  fit <- loadings::pca_loading(stats::prcomp(X, center = TRUE, scale. = TRUE))
  list(schema_version = "1.0", method = "pca", package_version = as.character(utils::packageVersion("loadings")),
       conditions = list(samples = nrow(X), variables = ncol(X), components = k, center = TRUE, scale = TRUE),
       scores = matrix_result(fit$x, limit, k), coefficients = matrix_result(fit$rotation, limit, k),
       loadings = matrix_result(fit$loading$R, limit, k),
       tests = list(p_values = matrix_result(fit$loading$p.value, limit, k), adjustment = "none", interpretation = "Exploratory, two-sided loading tests; no multiple-testing correction."),
       eigenvalues = as.list(head(fit$sdev^2, k)), explained_variance_ratio = as.list(head(fit$sdev^2 / sum(fit$sdev^2), k)))
})

analyze_model <- function(method, x, y = list(), d = list(), components = 2L,
                          kappa = 0.999, lambda = 0.5, max_rows = 100L) safe_analysis({
  if (!is.character(method) || length(method) != 1L || !method %in% c("os_pca", "pls_rog", "pls_da", "rcca_da")) fail("Unknown method")
  X <- numeric_matrix(x, "x", 4L)
  if (any(apply(X, 2, stats::sd) == 0)) fail("x contains a constant column")
  k <- scalar_integer(components, "components", 1L, min(10L, ncol(X), nrow(X) - 1L))
  limit <- scalar_integer(max_rows, "max_rows", 1L, 500L)
  kappa <- scalar_number(kappa, "kappa", 0, 0.999999)
  lambda <- scalar_number(lambda, "lambda", 0.000001, 1)
  if (method != "os_pca") {
    Y <- numeric_matrix(y, "y", 4L)
    if (nrow(Y) != nrow(X) || ncol(Y) < 2L || any(!Y %in% c(0, 1)) || any(rowSums(Y) != 1) || any(colSums(Y) < 2))
      fail("y must be one-hot groups, matching x rows, with at least two samples in each of at least two groups")
    if (method == "pls_rog" && k > min(ncol(X), ncol(Y))) fail("components exceeds PLS-ROG dimensions")
  }
  if (method %in% c("os_pca", "pls_rog")) {
    D <- numeric_matrix(d, "d")
    if (ncol(D) != if (method == "os_pca") nrow(X) else ncol(Y)) fail("d columns must match samples for OS-PCA or groups for PLS-ROG")
  }
  fit <- switch(method,
    os_pca = loadings::ospca_loading(loadings::os_pca(X, D, kappa = kappa)),
    pls_rog = loadings::plsrog_loading(loadings::pls_rog(X, Y, D, kappa = kappa)),
    pls_da = loadings::plsda_loading(loadings::pls_da(X, Y, k = k)),
    rcca_da = loadings::rcca_loading(loadings::rcca_da(X, Y, lambda = lambda, k = k)))
  list(schema_version = "1.0", method = method,
    package_version = as.character(utils::packageVersion("loadings")),
    conditions = list(samples = nrow(X), variables = ncol(X), components = k, autoscale = TRUE,
                      kappa = if (method %in% c("os_pca", "pls_rog")) kappa else NULL,
                      lambda = if (method == "rcca_da") lambda else NULL,
                      group_columns = if (method != "os_pca") ncol(Y) else NULL),
    scores = matrix_result(fit$T, limit, k), coefficients = matrix_result(fit$P, limit, k),
    auxiliary_scores = matrix_result(fit$U, limit, k), loadings = matrix_result(fit$loading$R, limit, k),
    tests = list(p_values = matrix_result(fit$loading$p.value, limit, k), adjustment = "none", interpretation = "Exploratory loading tests; no multiple-testing correction. Group order follows y columns."),
    eigenvalues = NULL, explained_variance_ratio = NULL,
    unavailable = "Eigenvalues and explained variance are not returned by this loadings function.")
})

demo_data <- function() {
  list(dataset = "iris", source = "R datasets::iris", samples = 150L, variables = as.list(names(iris)[1:4]),
       x = list(rows = lapply(seq_len(nrow(iris)), function(i) unname(as.list(as.numeric(iris[i, 1:4]))))),
       y = list(rows = lapply(as.integer(iris$Species), function(g) as.list(as.integer(seq_len(3) == g)))),
       group_columns = as.list(levels(iris$Species)))
}
