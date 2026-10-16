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
  stopifnot(setequal(names(tools), c("analyze_pca", "analyze_model", "demo_data")))
  demo <- tools$demo_data()
  source("R/utils.R"); source("R/analysis.R")
  result <- tools$analyze_pca(x = demo_data()$x, components = 2L, max_rows = 10L)
  parsed <- result@value
  if (!isTRUE(parsed$ok)) print(parsed)
  stopifnot(parsed$ok, parsed$scores$returned_rows == 10L, parsed$scores$truncated)
  bad <- tools$analyze_pca(x = list(rows = list(c(1, 1), c(1, 1), c(1, 1), c(1, 1))), components = 2L, max_rows = 10L)
  bad <- bad@value
  stopifnot(!bad$ok, bad$error$code == "analysis_error")
  for (method in c("os_pca", "pls_rog", "pls_da", "rcca_da")) {
    demo <- demo_data()
    d <- if (method == "os_pca") list(rows = lapply(seq_len(149), function(i) as.list(replace(replace(numeric(150), i, -1), i + 1, 1)))) else list(rows = list(c(-1, 1, 0), c(0, -1, 1)))
    result <- do.call(tools$analyze_model, list(method = method, x = demo$x, y = demo$y, d = d, components = 2L, kappa = 0.999, lambda = 0.5, max_rows = 10L))
    stopifnot(result@value$ok, result@value$scores$returned_rows == 10L)
  }
  cat("Official MCP HTTP client: list and call passed on /mcp.\n")
}
run_http_test()
