# Verified upstream APIs

Reviewed 2026-10-16 against official CRAN manual and upstream source, not inferred function names. Package source is unchanged.

## loadings 0.6.1

Sources: [CRAN](https://cran.r-project.org/package=loadings), [manual](https://cran.r-project.org/web/packages/loadings/loadings.pdf), [CRAN mirror source](https://github.com/cran/loadings/tree/3c0d746f728d35ff1a04a5c18f003ec902508358).

| Functions | Input | Principal output |
| --- | --- | --- |
| pca_loading(pca) | complete prcomp object with x/rotation | original PCA plus loading.R and loading.p.value |
| os_pca(X,D,kappa=0.999,M=diag(1,nrow(X))) | numeric data, differential matrix, smoothing, optional averaging | P,T,MT,Q,U |
| ospca_loading(ospca) | os_pca result | adds loading.R and p.value |
| pls_da(X,Y,k) | data, dummy group matrix, components | P,T |
| plsda_loading(plsda) | pls_da result | adds loading.R and p.value |
| pls_rog(X,Y,D,kappa=0.999) | data, dummy groups, group differential, smoothing | P,T,Q,U |
| plsrog_loading(plsrog) | pls_rog result | adds loading.R and p.value |
| rcca_da(X,Y,lambda,k) | data, dummy groups, regularization, components | P,T |
| rcca_loading(rcca) | rcca_da result | adds loading.R and p.value |
| pls_svd(X,Y) / pls_loading(pls) | paired matrices / fit | P,T,Q,U / loading tests |
| one_kpca(X,K) / onekpca_loading(onekpca) | data and centered kernel / fit | P,T,U / loading tests |
| multipls_geigen(X,Y,tau) / multipls_loading(multipls) | list of datasets, dummy groups, connection weights / fit | multiset P,T,Q,U,tau / loading tests |
| multipls_rog(X,Y,tau,D,kappa) / multiplsrog_loading(multiplsrog) | multiset data, groups, weights, differential, smoothing / fit | multiset fit / loading tests |
| unsv_multipls(X,tau) / unsvmultipls_loading(unsvmultipls) | multiset data and weights / fit | multiset fit / loading tests |

The first nine functions are used by this project; other documented algorithms are inventoried but not exposed in this MVP. The package also has a generalized eigenvalue helper; it is not an analysis tool here. Built-in datasets: antibiotic, covid19, fasting, greentea, turnover, whhl. No package function named PCA is invented: PCA uses base R stats::prcomp as in the package examples.

## mcptools

[Official repository](https://github.com/posit-dev/mcptools), [documentation](https://posit-dev.github.io/mcptools/). Pin: `ff94da04ccb5e6e86a56537c9d2dcb0e0532067b`, version 1.0.3.9000 at inspection.

Official source `R/server.R` defines `mcp_server(tools=NULL,...,type=c("stdio","http"),host="127.0.0.1",port=as.integer(Sys.getenv("MCPTOOLS_PORT","8080")),session_tools=TRUE)`. We pass `type="http"`, `host="0.0.0.0"`, validated Cloud Run PORT, an explicit ellmer tool list, and `session_tools=FALSE`. The upstream server accepts POST on any path; `/mcp` is the client endpoint used here. GET/SSE returns 405. HTTP handling, initialization, discovery, execution and serialization remain upstream responsibilities.

`ellmer::tool()` registers R functions; types use official `type_object`, `type_array`, `type_number`, `type_integer`, `type_string`, with `convert=FALSE` so our validation sees the original structures. mcptools flattens unnamed top-level array arguments before invocation, so each matrix is a named `{"rows": [...]}` object. This behavior was discovered and resolved in the real HTTP test. Official `mcptools::mcp_tools(config)` supports remote Streamable HTTP configurations using `url` and optional headers, and is used by the HTTP integration test. No API keys to an AI provider are needed for that test.

The pinned R client's recursive secret-redaction routine can fail on null-valued list elements. The wrapper omits unavailable fields and uses explicit `"not_finite"` matrix entries, with counts, to keep results usable by that client. No upstream code is modified.

## Runtime and clients

[Cloud Run runtime contract](https://cloud.google.com/run/docs/container-contract): bind 0.0.0.0 and listen on PORT. Container uses Rscript exec form, no persistent local storage or session affinity requirement.

[Claude Code](https://code.claude.com/docs/en/mcp): `claude mcp add --transport http NAME URL`.
[Claude Desktop remote connectors](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp): connector UI and account permissions apply.
[ChatGPT](https://help.openai.com/en/articles/12584461-connecting-custom-mcp-servers-in-chatgpt): custom MCP server connection via Plugins where available; account/workspace restrictions apply. Full MCP availability and UI can change. No client is described as already tested beyond the official R client.
