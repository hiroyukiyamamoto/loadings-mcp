make_tools <- function() {
  # Named object prevents upstream mcptools from flattening unnamed top-level arrays.
  matrix_type <- function(description, required = TRUE) ellmer::type_object(description, .required = required, rows = ellmer::type_array("Sample rows", items = ellmer::type_array("Row", items = ellmer::type_number("Finite value"))))
  list(ellmer::tool(analyze_pca,
    convert = FALSE,
    name = "analyze_pca", description = "Autoscaled PCA with loadings package loading hypothesis tests. Rows are samples; columns are variables. No missing or constant columns. Results are exploratory.", arguments = list(
    x = matrix_type("Object with numeric rows: 4-500 samples, 1-400 variables, at most 50000 cells."),
    components = ellmer::type_integer("Number of returned components, 1-10, bounded by data dimensions.", required = FALSE),
    max_rows = ellmer::type_integer("Maximum score and variable rows returned, 1-500.", required = FALSE))),
    ellmer::tool(analyze_model, convert = FALSE, name = "analyze_model", description = "OS-PCA, PLS-ROG, PLS-DA or RCCA-DA with official loadings hypothesis tests. Rows are samples. No prediction or cross-validation is performed.",
      arguments = list(method = ellmer::type_string("One of os_pca, pls_rog, pls_da, rcca_da."),
      x = matrix_type("Sample data: 4-500 rows, 1-400 variables, at most 50000 cells."),
      y = matrix_type("One-hot group rows for supervised methods; at least two samples per group. Omit for OS-PCA.", required = FALSE),
      d = matrix_type("Differential matrix for OS-PCA (columns=samples) or PLS-ROG (columns=ordered groups). Omit otherwise.", required = FALSE),
      components = ellmer::type_integer("Returned components: 1-10 within data dimensions.", required = FALSE),
      kappa = ellmer::type_number("Smoothing, 0 to 0.999999; OS-PCA and PLS-ROG only.", required = FALSE),
      lambda = ellmer::type_number("RCCA regularization, 0.000001 to 1.", required = FALSE),
      max_rows = ellmer::type_integer("Maximum rows per output matrix, 1-500.", required = FALSE))),
    ellmer::tool(analyze_multiset, convert = FALSE, name = "analyze_multiset",
      description = "Official multiset PLS, multiset PLS-ROG or unsupervised multiset PLS with per-block loading tests. All blocks must have aligned sample rows. Use demo_data(dataset='whhl') for real matched metabolome blocks.",
      arguments = list(method = ellmer::type_string("multipls, multipls_rog or unsv_multipls"),
        blocks = ellmer::type_object("Named envelope containing 2-4 blocks", sets = ellmer::type_array("Blocks in tau order", items = ellmer::type_object("Block", name = ellmer::type_string("Unique simple block name"), data = matrix_type("Numeric sample rows")))),
        tau = matrix_type("Symmetric nonnegative connection weights, zero diagonal. Size blocks+1 for supervised; blocks for unsupervised."),
        y = matrix_type("Matching one-hot groups; omit for unsupervised", required = FALSE),
        d = matrix_type("Group differential matrix; multipls_rog only", required = FALSE),
        kappa = ellmer::type_number("Smoothing 0-0.999999", required = FALSE),
        components = ellmer::type_integer("Returned components 1-10, at most samples-1", required = FALSE),
        max_rows = ellmer::type_integer("Output rows per block matrix 1-500", required = FALSE))),
    ellmer::tool(demo_data, name = "demo_data", description = "Return real packaged metabolome data: fasting (default, 10 samples, 282 metabolites) or whhl (9 matched rabbit samples, four tissue blocks with tau and differential matrices).",
      arguments = list(dataset = ellmer::type_string("fasting or whhl; default fasting", required = FALSE))))
}
