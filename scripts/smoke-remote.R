if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
run_remote_smoke <- function() {
  url <- Sys.getenv("MCP_ENDPOINT")
  if (!grepl("^https://[^/]+/mcp$", url)) stop("Set MCP_ENDPOINT to the verified HTTPS /mcp URL")
  entry <- list(url = url, timeout = 120)
  token <- Sys.getenv("CLOUD_RUN_ID_TOKEN")
  if (nzchar(token)) entry$headers <- list(Authorization = "Bearer ${CLOUD_RUN_ID_TOKEN}")
  request <- httr2::request(url) |> httr2::req_timeout(120)
  if (nzchar(token)) request <- httr2::req_auth_bearer_token(request, token)
  initialize <- request |>
    httr2::req_headers(Accept = "application/json, text/event-stream") |>
    httr2::req_body_json(list(jsonrpc = "2.0", id = 1L, method = "initialize",
      params = list(protocolVersion = "2025-06-18", capabilities = structure(list(), names = character()),
                    clientInfo = list(name = "loadings-mcp-deployment-test", version = "1.0")))) |>
    httr2::req_perform() |>
    httr2::resp_body_json()
  stopifnot(is.null(initialize$error), nzchar(initialize$result$protocolVersion))
  config <- tempfile(fileext = ".json")
  on.exit(unlink(config), add = TRUE)
  jsonlite::write_json(list(mcpServers = list(loadings = entry)), config, auto_unbox = TRUE)
  tools <- mcptools::mcp_tools(config)
  names(tools) <- vapply(tools, function(tool) tool@name, character(1))
  stopifnot(setequal(names(tools), c("demo_data", "analyze_pca", "analyze_model", "analyze_multiset")))
  timings <- list()
  invoke <- function(name, arguments = list()) {
    elapsed <- system.time(result <- do.call(tools[[name]], arguments))[["elapsed"]]
    timings[[length(timings)+1L]] <<- list(tool=name,method=arguments$method,elapsed_seconds=elapsed)
    if (inherits(result, "ellmer::ContentToolResult")) {
      if (!is.null(result@error)) stop("Remote MCP tool execution failed")
      result <- result@value
    }
    if (is.character(result)) return(jsonlite::fromJSON(result, simplifyVector = FALSE))
    result
  }
  demo <- invoke("demo_data", list(dataset="fasting"))
  stopifnot(demo$samples == 10L, length(demo$x$rows) == 10L)
  packaged <- new.env(parent=baseenv())
  utils::data(list="fasting",package="loadings",envir=packaged)
  stopifnot(isTRUE(all.equal(do.call(rbind,lapply(demo$x$rows,unlist)),
    unname(as.matrix(packaged$fasting$X)),check.attributes=FALSE)))
  pca <- invoke("analyze_pca", list(x = demo$x, components = 2L, max_rows = 10L))
  if (!isTRUE(pca$ok)) stop(paste("Remote PCA failed:",jsonlite::toJSON(pca,auto_unbox=TRUE)))
  stopifnot(pca$ok, pca$scores$returned_rows == 10L, pca$scores$returned_columns == 2L)
  models <- list()
  for (method in c("os_pca", "pls_rog", "pls_da", "rcca_da")) {
    d <- if (method == "os_pca") list(rows=lapply(seq_len(9), function(i)
      as.list(replace(replace(numeric(10), i, -1), i+1, 1)))) else list(rows=list(c(-1,1)))
    result <- invoke("analyze_model", list(method = method, x = demo$x, y = demo$y, d = d,
      components = 2L, kappa = 0.999, lambda = 0.5, max_rows = 10L))
    stopifnot(result$ok, result$scores$returned_rows == 10L)
    models[[method]] <- list(ok = result$ok, score_rows = result$scores$returned_rows,
      components = result$scores$returned_columns, warnings = result$warnings)
  }
  multi <- invoke("demo_data",list(dataset="whhl"))
  multiset <- list()
  for(method in c("multipls","multipls_rog","unsv_multipls")) {
    weights <- if(method=="unsv_multipls") multi$unsupervised_tau else multi$tau
    result <- invoke("analyze_multiset",list(method=method,blocks=multi$blocks,tau=weights,y=multi$y,d=multi$d,components=2L,max_rows=10L,kappa=.999))
    stopifnot(result$ok,length(result$blocks)==4)
    multiset[[method]] <- list(ok=result$ok,blocks=length(result$blocks),warnings=result$warnings)
  }
  invalid <- invoke("analyze_pca", list(x = list(rows = rep(list(c(1, 1)), 4)), components = 2L, max_rows = 10L))
  stopifnot(identical(invalid$ok, FALSE), invalid$error$code == "analysis_error")
  report <- list(endpoint = url, checked_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    authentication = if (nzchar(token)) "Cloud Run identity token" else "anonymous HTTPS",
    initialize = list(ok = TRUE, protocol_version = initialize$result$protocolVersion),
    tools = as.list(names(tools)), demo = list(samples = demo$samples, variables = length(demo$variables)),
    pca = list(ok = pca$ok, score_rows = pca$scores$returned_rows,
      explained_variance_ratio = pca$explained_variance_ratio, warnings = pca$warnings),
    models = models, multiset = multiset, invalid_input = list(ok = TRUE, returned_error = invalid$error),
    demo_precision_preserved=TRUE, timings=timings)
  dir.create("test-results", showWarnings = FALSE)
  jsonlite::write_json(report, "test-results/remote-mcp.json", auto_unbox = TRUE, pretty = TRUE)
  cat(jsonlite::toJSON(report, auto_unbox = TRUE, pretty = TRUE), "\n")
}
run_remote_smoke()
