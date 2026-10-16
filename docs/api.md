# MCP tool API, schema 1.0

Transport: official mcptools HTTP, POST `/mcp`. Session tools disabled. All data remain in the serving R process for computation; there is no persistence or model registry.

## Tools

`demo_data()` returns Iris x (150 × 4), y (150 × 3 one-hot), variable names and group-column names. No arguments.

`analyze_pca(x, components=2, max_rows=100)` runs centered, unit-variance PCA and `pca_loading`. x is required as an object `{"rows":[[1,2],[3,4],...]}`. Every matrix parameter (x, y, d) uses this named rows envelope, preserving dimensions through mcptools' argument handling. components is an integer from 1 to min(10, variables, samples−1). The full PCA is computed before outputs are sliced.

`analyze_model(method, x, y=[], d=[], components=2, kappa=0.999, lambda=0.5, max_rows=100)` supports the following. Omit y or d when unused; when supplied, each uses the rows object:

| method | Required extra data | Official functions |
| --- | --- | --- |
| os_pca | d columns = x sample count | os_pca(X,D,kappa), ospca_loading |
| pls_rog | y and d; d columns = y group count | pls_rog(X,Y,D,kappa), plsrog_loading |
| pls_da | y | pls_da(X,Y,k), plsda_loading |
| rcca_da | y | rcca_da(X,Y,lambda,k), rcca_loading |

y must have the same sample rows as x, at least two group columns, exactly one 1 per row, and at least two samples per group. Group order is y column order. d is a finite rectangular differential matrix. An adjacent difference for three ordered groups is `{"rows":[[-1,1,0],[0,-1,1]]}`. OS-PCA currently uses the package default identity averaging matrix (repeated-measures M is not exposed). Because d has one column per sample, the matrix column cap limits OS-PCA to 200 samples.

kappa is bounded to [0, 0.999999], lambda to [0.000001, 1]. Both are validated; only relevant methods use each value. PLS-ROG returned components cannot exceed min(x columns, y columns). No fit/predict or cross-validation interface is exposed.

## Validation and limits

x: 4–500 samples, 1–200 variables, at most 50,000 cells. Every input matrix is capped at 500 rows, 200 columns, 50,000 cells. Reject ragged rows, strings, nested non-scalars, booleans, missing values, NaN/Inf and zero-variance x columns. Algorithms may still reject rank-deficient inputs; these errors are returned, not hidden. components ≤ 10, max_rows 1–500 (default 100), per output matrix. There is no paging; request a larger max_rows within the cap to retrieve more rows.

## Output

Success object: `schema_version`, `ok=true`, `method`, `package_version`, `conditions`, `scores`, `coefficients`, `loadings`, `tests`, `warnings`. PCA also supplies `eigenvalues`, `explained_variance_ratio`; other methods omit these fields with an `unavailable` explanation, and include `auxiliary_scores` if the package provides them. Unused condition fields are omitted.

Each matrix object contains `values` as row arrays; `total_rows`, `total_columns`, `returned_rows`, `returned_columns`, `truncated`, and `nonfinite_values` for the returned slice. Rows remain in input order; columns are component order. Variable names are external metadata in this MVP. Nonfinite entries use the explicit string `"not_finite"`, so downstream software must check metadata before treating a matrix as entirely numeric. The full covariance/SVD still uses all input data, even when outputs are truncated. Null entries are avoided for compatibility with the pinned mcptools client's redaction routine.

`coefficients` is PCA rotation or the package P matrix; `loadings` is the package's loading R matrix, a distinct statistic. tests.p_values are the package's two-sided tests; adjustment is `none`. For scientific inference, review assumptions and multiple testing independently.

Tool execution failures return `ok=false`, `error={code:"analysis_error",message:...}`, and warning strings. Protocol/schema failures can instead be MCP errors handled by mcptools. The pinned upstream server supplies `structuredContent` for named-list results when supported by the negotiated protocol, with a JSON text content fallback for older protocols. No custom protocol envelope is implemented here.

## Example

Call `demo_data`, then `analyze_pca` with x from that response, components 2, max_rows 150. See [actual result](data/iris-pca.json) and the repository's `examples/iris-pca-input.json`. `examples/generate.R` regenerates both and the SVG plots from the same implementation.
