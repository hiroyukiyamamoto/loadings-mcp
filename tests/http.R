if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
run_http_test <- function() {
  port <- httpuv::randomPort()
  server <- callr::r_bg(function(root, lib, port) {
    setwd(root); .libPaths(lib); Sys.setenv(PORT = port); source("R/server.R")
  }, args = list(getwd(), .libPaths(), port), stdout = "|", stderr = "|")
  on.exit(server$kill(), add = TRUE)
  url <- sprintf("http://127.0.0.1:%d/mcp", port)
  for (i in seq_len(100)) {
    if (!server$is_alive()) stop(paste(server$read_all_error(), collapse = "\n"))
    ready <- tryCatch({ httr2::request(url) |> httr2::req_error(is_error = function(resp) FALSE) |> httr2::req_perform(); TRUE }, error = function(e) FALSE)
    if (ready) break
    Sys.sleep(0.1)
  }
  config <- tempfile(fileext = ".json")
  on.exit(unlink(config), add = TRUE)
  jsonlite::write_json(list(mcpServers = list(loadings = list(url = url))), config, auto_unbox = TRUE)
  # Official MCP client performs initialization, tools/list and tools/call.
  tools <- mcptools::mcp_tools(config)
  names(tools) <- vapply(tools, function(t) t@name, character(1))
  stopifnot(setequal(names(tools), c("analyze_pca", "analyze_model", "analyze_multiset", "demo_data")))
  decode <- function(result) {
    if(inherits(result,"ellmer::ContentToolResult")) result <- result@value
    if(is.character(result)) result <- jsonlite::fromJSON(result,simplifyVector=FALSE)
    result
  }
  demo <- decode(tools$demo_data(dataset="fasting"))
  source("R/utils.R"); source("R/analysis.R")
  # Regression: the old output serializer rounded 29 metabolite columns to zero.
  stopifnot(isTRUE(all.equal(numeric_matrix(demo$x,"remote"),numeric_matrix(demo_data()$x,"local"))))
  result <- do.call(tools$analyze_pca, list(x = demo$x, components = 2L, max_rows = 10L))
  parsed <- decode(result)
  if (!isTRUE(parsed$ok)) print(parsed)
  stopifnot(parsed$ok, parsed$scores$returned_rows == 10L, parsed$loadings$truncated)
  local_pca <- analyze_pca(demo_data()$x,components=2L,max_rows=10L)
  stopifnot(isTRUE(all.equal(unlist(parsed$scores$values),unlist(local_pca$scores$values),tolerance=1e-10)),
    isTRUE(all.equal(unlist(parsed$tests$p_values$values),unlist(local_pca$tests$p_values$values),tolerance=1e-10)))
  bad <- tools$analyze_pca(x = list(rows = list(c(1, 1), c(1, 1), c(1, 1), c(1, 1))), components = 2L, max_rows = 10L)
  bad <- decode(bad)
  stopifnot(!bad$ok, bad$error$code == "analysis_error")
  for (method in c("os_pca", "pls_rog", "pls_da", "rcca_da")) {
    d <- if (method == "os_pca") matrix_input(diff(diag(demo$samples))) else list(rows=list(c(-1,1)))
    result <- do.call(tools$analyze_model, list(method = method, x = demo$x, y = demo$y, d = d, components = 2L, kappa = 0.999, lambda = 0.5, max_rows = 10L))
    result <- decode(result)
    stopifnot(result$ok, result$scores$returned_rows == 10L)
  }
  multi <- tools$demo_data(dataset="whhl")
  multi <- decode(multi)
  local_multi <- demo_data("whhl")
  for(i in seq_along(multi$blocks$sets)) stopifnot(isTRUE(all.equal(
    numeric_matrix(multi$blocks$sets[[i]]$data,"remote"),numeric_matrix(local_multi$blocks$sets[[i]]$data,"local"))))
  for(method in c("multipls","multipls_rog","unsv_multipls")) {
    tau <- if(method=="unsv_multipls") multi$unsupervised_tau else multi$tau
    result <- do.call(tools$analyze_multiset,list(method=method,blocks=multi$blocks,tau=tau,y=multi$y,d=multi$d,components=2L,max_rows=5L,kappa=.999))
    result <- decode(result)
    stopifnot(result$ok,length(result$blocks)==4)
  }
  cat("Official MCP HTTP client: list and call passed on /mcp.\n")
}
run_http_test()
