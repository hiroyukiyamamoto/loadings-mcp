make_tools <- function() {
  # Named object prevents upstream mcptools from flattening unnamed top-level arrays.
  matrix_type <- function(description, required = TRUE) ellmer::type_object(description, .required = required, rows = ellmer::type_array("Sample rows", items = ellmer::type_array("Row", items = ellmer::type_number("Finite value"))))
  list(ellmer::tool(analyze_pca,
    convert = FALSE,
    name = "analyze_pca", description = "Autoscaled PCA with loadings package loading hypothesis tests. Rows are samples; columns are variables. No missing or constant columns. Results are exploratory.", arguments = list(
    x = matrix_type("Object with numeric rows: 4-500 samples, 1-200 variables, at most 50000 cells."),
    components = ellmer::type_integer("Number of returned components, 1-10, bounded by data dimensions.", required = FALSE),
    max_rows = ellmer::type_integer("Maximum score and variable rows returned, 1-500.", required = FALSE))),
    ellmer::tool(analyze_model, convert = FALSE, name = "analyze_model", description = "OS-PCA, PLS-ROG, PLS-DA or RCCA-DA with official loadings hypothesis tests. Rows are samples. No prediction or cross-validation is performed.",
      arguments = list(method = ellmer::type_string("One of os_pca, pls_rog, pls_da, rcca_da."),
      x = matrix_type("Sample data: 4-500 rows, 1-200 variables, at most 50000 cells."),
      y = matrix_type("One-hot group rows for supervised methods; at least two samples per group. Omit for OS-PCA.", required = FALSE),
      d = matrix_type("Differential matrix for OS-PCA (columns=samples) or PLS-ROG (columns=ordered groups). Omit otherwise.", required = FALSE),
      components = ellmer::type_integer("Returned components: 1-10 within data dimensions.", required = FALSE),
      kappa = ellmer::type_number("Smoothing, 0 to 0.999999; OS-PCA and PLS-ROG only.", required = FALSE),
      lambda = ellmer::type_number("RCCA regularization, 0.000001 to 1.", required = FALSE),
      max_rows = ellmer::type_integer("Maximum rows per output matrix, 1-500.", required = FALSE))),
    ellmer::tool(demo_data, name = "demo_data", description = "Return built-in iris data as numeric sample rows and one-hot groups, without reading external files."))
}
