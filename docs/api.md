# MCP tool API, schema 1.0

Transport: official mcptools HTTP, POST `/mcp`. Session tools disabled. Each call runs in a separate, disposable R worker with a 20-second deadline; there is no persistence or model registry. The Docker entrypoint places nginx in front of the official transport: maximum body 2 MiB (HTTP 413), 60 requests/minute per instance shared by all users with burst 10 (HTTP 429), and 25-second upstream response timeout. Rate counters reset on instance replacement and are not a durable monthly usage cap. Direct `R/server.R` development startup omits the nginx HTTP limits; use Docker for public hosting.

## Tools

`demo_data(dataset="fasting")` returns the complete packaged mouse liver metabolome x (10 × 282), one-hot y (10 × 2), metabolite names, group-column codes and source reference. No filtering, imputation or synthetic values are used. Analyses perform their documented autoscaling.

`demo_data(dataset="whhl")` returns 9 matched rabbit samples in four tissue blocks (plasma 129, liver 170, heart 161, brain 159 variables), y, tau and d from the package, plus block-variable names and source metadata. `unsupervised_tau` is the four-block submatrix of packaged tau, excluding its group row/column. Treatment names are described by the source; group-code-to-treatment mapping is not guessed.

`analyze_pca(x, components=2, max_rows=100)` runs centered, unit-variance PCA and `pca_loading`. x is required as an object `{"rows":[[1,2],[3,4],...]}`. Every matrix parameter (x, y, d) uses this named rows envelope, preserving dimensions through mcptools' argument handling. components is an integer from 1 to min(10, variables, samples−1). The full PCA is computed before outputs are sliced.

`analyze_model(method, x, y=[], d=[], components=2, kappa=0.999, lambda=0.5, max_rows=100)` supports the following. Omit y or d when unused; when supplied, each uses the rows object:

| method | Required extra data | Official functions |
| --- | --- | --- |
| os_pca | d columns = x sample count | os_pca(X,D,kappa), ospca_loading |
| pls_rog | y and d; d columns = y group count | pls_rog(X,Y,D,kappa), plsrog_loading |
| pls_da | y | pls_da(X,Y,k), plsda_loading |
| rcca_da | y | rcca_da(X,Y,lambda,k), rcca_loading |

y must have the same sample rows as x, at least two group columns, exactly one 1 per row, and at least two samples per group. Group order is y column order. d is a finite rectangular differential matrix. An adjacent difference for three ordered groups is `{"rows":[[-1,1,0],[0,-1,1]]}`. OS-PCA currently uses the package default identity averaging matrix (repeated-measures M is not exposed). Because d has one column per sample, the matrix column cap limits OS-PCA to 400 samples.

kappa is bounded to [0, 0.999999], lambda to [0.000001, 1]. Both are validated; only relevant methods use each value. PLS-ROG returned components cannot exceed min(x columns, y columns). No fit/predict or cross-validation interface is exposed.

## Validation and limits

x: 4–500 samples, 1–400 variables, at most 50,000 cells. Every input matrix is capped at 500 rows, 400 columns, 50,000 cells. Reject ragged rows, strings, nested non-scalars, booleans, missing values, NaN/Inf and zero-variance x columns. Algorithms may still reject rank-deficient inputs; these errors are returned, not hidden. components ≤ 10, max_rows 1–500 (default 100), per output matrix. There is no paging; request a larger max_rows within the cap to retrieve more rows.

## Output

Success object: `schema_version`, `ok=true`, `method`, `package_version`, `conditions`, `scores`, `coefficients`, `loadings`, `tests`, `warnings`. PCA also supplies `eigenvalues`, `explained_variance_ratio`; other methods omit these fields with an `unavailable` explanation, and include `auxiliary_scores` if the package provides them. Unused condition fields are omitted.

Each matrix object contains `values` as row arrays; `total_rows`, `total_columns`, `returned_rows`, `returned_columns`, `truncated`, and `nonfinite_values` for the returned slice. Rows remain in input order; columns are component order. Variable names are external metadata in this MVP. Nonfinite entries use the explicit string `"not_finite"`, so downstream software must check metadata before treating a matrix as entirely numeric. The full covariance/SVD still uses all input data, even when outputs are truncated. Null entries are avoided for compatibility with the pinned mcptools client's redaction routine.

`coefficients` is PCA rotation or the package P matrix; `loadings` is the package's loading R matrix, a distinct statistic. tests.p_values are the package's two-sided tests; adjustment is `none`. For scientific inference, review assumptions and multiple testing independently.

Tool execution failures return `ok=false`, `error={code:"analysis_error",message:...}`, and warning strings. Protocol/schema failures can instead be MCP errors handled by mcptools. Each tool returns one standard MCP text content block containing a JSON object; parse `result.content[0].text` as JSON. The wrapper uses official `ellmer::ContentText` and full numeric precision because this pinned mcptools version rounds ordinary structured-content numbers to four decimal places. `structuredContent` is intentionally absent. This preserves low-abundance metabolites and small p-values without modifying mcptools or implementing a custom protocol envelope.

## Example

Call `demo_data(dataset="fasting")`, then `analyze_pca` with x from that response, components 2, max_rows 400. See [actual result](data/fasting-pca.json) and the repository's `examples/fasting-pca-input.json`. `examples/generate.R` regenerates the artifacts, including the four-block [whhl multiset result](data/whhl-multiset.json).

## Multiset analysis

`analyze_multiset(method, blocks, tau, y=[], d=[], kappa=0.999, components=2, max_rows=100)`:

| method | Official functions | Inputs |
| --- | --- | --- |
| multipls | multipls_geigen(X,Y,tau), multipls_loading | blocks, y, tau |
| multipls_rog | multipls_rog(X,Y,tau,D,kappa), multiplsrog_loading | blocks, y, tau, d |
| unsv_multipls | unsv_multipls(X,tau), unsvmultipls_loading | blocks, tau |

`blocks` uses `{"sets":[{"name":"plasma","data":{"rows":[[...],...] }}, ...]}`. The named envelope preserves nested arrays through upstream argument handling. Names must be unique simple identifiers (1–40 characters, starting with a letter). Supply 2–4 blocks with aligned sample rows, nonconstant variables, at most 800 combined variables and 100,000 cells. Each matrix also respects the general limits.

Tau is symmetric, finite, nonnegative, zero-diagonal, with at least one nonzero connection per row. Its size is (blocks+1)² for supervised methods; the final row/column corresponds to y. For unsupervised analysis its size is blocks². y uses the same one-hot validation as other supervised methods; d columns follow y group order. components is at most min(10, samples−1, total variables).

The package's 0.6.1 loading helpers iterate over sample-count components internally. Consequently, total variables plus group columns (supervised) must be at least sample count; unsupported shapes return a clear error before calling upstream. The complete upstream fits are passed to the tests without modification. The unsupervised helper omits the last block's original scores/coefficients in its returned fit, so this wrapper returns all original fit blocks and attaches the separately computed test results by matching block index. The package itself is unchanged.

Output `blocks` is an ordered list with each block's name, variable count, scores, coefficients, correlation loadings, auxiliary scores and p_values. Every matrix uses the existing truncation/nonfinite metadata. Conditions include the input block order, sample count, combined variables, tau and smoothing where applicable. Eigenvalues/variance ratios are unavailable because upstream does not return them. P-values are unadjusted and exploratory.
