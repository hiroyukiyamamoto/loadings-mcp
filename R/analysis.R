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

demo_data <- function(dataset = "fasting") {
  if (!is.character(dataset) || length(dataset) != 1L || !dataset %in% c("fasting", "whhl")) fail("dataset must be fasting or whhl")
  env <- new.env(parent = baseenv())
  utils::data(list = dataset, package = "loadings", envir = env)
  data <- env[[dataset]]
  common <- list(dataset = dataset, source = paste0("loadings::", dataset),
                 samples = nrow(data$Y), y = matrix_input(data$Y),
                 group_columns = as.list(colnames(data$Y)))
  if (dataset == "fasting") {
    X <- as.matrix(data$X)
    return(c(common, list(description = "Mouse liver metabolome: normal and 12-hour fasting, CE-TOFMS; 10 samples and 282 metabolites.",
      reference = "https://doi.org/10.1186/1471-2105-15-51", variables = as.list(colnames(X)),
      x = matrix_input(X), preprocessing = "None. Full packaged data; autoscaling is performed by analysis tools.")))
  }
  c(common, list(description = "Rabbit metabolomes across plasma, liver, heart and brain; 9 matched samples in three groups.",
    reference = "Ooga et al. (2011), Metabolomic Anatomy of Animal Model Revealing Homeostatic Imbalances in Dyslipidemia. Mol. BioSyst. 7:1217-1223.",
    blocks = list(sets = unname(lapply(names(data$X), function(name) list(name = name, data = matrix_input(data$X[[name]]))))),
    block_variables = lapply(data$X, function(x) as.list(colnames(x))),
    tau = matrix_input(data$tau), d = matrix_input(data$D),
    unsupervised_tau = matrix_input(data$tau[seq_along(data$X), seq_along(data$X)]),
    preprocessing = "None. Full packaged matrices and connection weights; blocks share the original sample order."))
}

analyze_multiset <- function(method, blocks, tau, y = list(), d = list(),
                              kappa = 0.999, components = 2L, max_rows = 100L) safe_analysis({
  if (!is.character(method) || length(method) != 1L || !method %in% c("multipls", "multipls_rog", "unsv_multipls")) fail("Unknown multiset method")
  if (!is.list(blocks) || !identical(names(blocks), "sets") || !is.list(blocks$sets) || length(blocks$sets) < 2L || length(blocks$sets) > 4L)
    fail("blocks must contain sets with 2-4 named data blocks")
  labels <- vapply(blocks$sets, function(block) {
    if (!is.list(block) || !is.character(block$name) || length(block$name) != 1L || !grepl("^[A-Za-z][A-Za-z0-9_-]{0,39}$", block$name)) fail("Each block needs a unique simple name and data")
    block$name
  }, character(1))
  if (anyDuplicated(labels)) fail("Block names must be unique")
  X <- lapply(blocks$sets, function(block) numeric_matrix(block$data, "block data", 4L))
  n <- nrow(X[[1]])
  if (any(vapply(X, nrow, integer(1)) != n)) fail("All blocks must have matching sample rows in the same order")
  if (any(vapply(X, function(x) any(apply(x, 2, stats::sd) == 0), logical(1)))) fail("A block contains constant variables")
  total <- sum(vapply(X, ncol, integer(1)))
  if (total > 800L || sum(vapply(X, length, integer(1))) > 100000L) fail("Multiset limit: 800 total variables and 100000 total cells")
  k <- scalar_integer(components, "components", 1L, min(10L, n - 1L, total))
  limit <- scalar_integer(max_rows, "max_rows", 1L, 500L)
  kappa <- scalar_number(kappa, "kappa", 0, 0.999999)
  supervised <- method != "unsv_multipls"
  expected <- length(X) + as.integer(supervised)
  weights <- numeric_matrix(tau, "tau")
  if (!identical(dim(weights), c(expected, expected)) || any(weights < 0) || any(diag(weights) != 0) || max(abs(weights - t(weights))) > 1e-10 || any(rowSums(weights) == 0))
    fail("tau must be symmetric, nonnegative, zero diagonal, connected at every block, and sized blocks+1 for supervised or blocks for unsupervised")
  if (supervised) {
    Y <- numeric_matrix(y, "y", 4L)
    if (nrow(Y) != n || ncol(Y) < 2 || any(!Y %in% c(0, 1)) || any(rowSums(Y) != 1) || any(colSums(Y) < 2)) fail("y must be matching one-hot groups with at least two samples per group")
  }
  # loadings 0.6.1's multiset loading helpers iterate through nrow(T).
  # Keep their input intact and reject dimensions unsupported by upstream.
  if (total + (if (supervised) ncol(Y) else 0L) < n) fail("The upstream loading tests require total variables plus supervised group columns >= samples")
  if (method == "multipls_rog") {
    D <- numeric_matrix(d, "d")
    if (ncol(D) != ncol(Y)) fail("d columns must match ordered y group columns")
  }
  fit <- switch(method, multipls = loadings::multipls_geigen(X, Y, weights),
    multipls_rog = loadings::multipls_rog(X, Y, weights, D, kappa = kappa),
    unsv_multipls = loadings::unsv_multipls(X, weights))
  tested <- switch(method, multipls = loadings::multipls_loading(fit),
    multipls_rog = loadings::multiplsrog_loading(fit),
    unsv_multipls = loadings::unsvmultipls_loading(fit))
  output <- lapply(seq_along(X), function(i) list(name = labels[i], variables = ncol(X[[i]]),
    scores = matrix_result(fit$T[[i]], limit, k), coefficients = matrix_result(fit$P[[i]], limit, k),
    loadings = matrix_result(tested$loading$R[[i]], limit, k),
    auxiliary_scores = matrix_result(tested$loading$Score[[i]], limit, k),
    p_values = matrix_result(tested$loading$p.value[[i]], limit, k)))
  list(schema_version = "1.0", method = method, package_version = as.character(utils::packageVersion("loadings")),
    conditions = list(samples = n, block_order = as.list(labels), total_variables = total, components = k,
      autoscale = TRUE, tau = matrix_input(weights), kappa = if (method == "multipls_rog") kappa else NULL),
    blocks = unname(output), group_scores = matrix_result(fit$U, limit, k),
    tests = list(adjustment = "none", interpretation = "Official exploratory multiset loading tests; sample rows must be aligned across blocks."),
    unavailable = "Eigenvalues and explained variance are not returned by these package functions.")
})
