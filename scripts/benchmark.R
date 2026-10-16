if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
# Run each real demo in a fresh R process; sample total process RSS, not only R heap.
methods <- c("pca", "os_pca", "pls_rog", "pls_da", "rcca_da", "multipls", "multipls_rog", "unsv_multipls")
results <- lapply(methods, function(method) {
  child <- callr::r_bg(function(root, lib, method) {
    setwd(root); .libPaths(lib)
    source("R/utils.R"); source("R/analysis.R")
    elapsed <- system.time({
      if (method %in% c("multipls", "multipls_rog", "unsv_multipls")) {
        demo <- demo_data("whhl")
        tau <- if (method == "unsv_multipls") demo$unsupervised_tau else demo$tau
        result <- analyze_multiset(method, demo$blocks, tau, demo$y, demo$d)
      } else {
        demo <- demo_data("fasting")
        d <- if (method == "os_pca") matrix_input(diff(diag(demo$samples))) else list(rows=list(c(-1,1)))
        result <- if (method == "pca") analyze_pca(demo$x) else analyze_model(method, demo$x, demo$y, d)
      }
      stopifnot(result$ok)
      encoded <- jsonlite::toJSON(result, auto_unbox=TRUE)
    })[["elapsed"]]
    list(method=method, elapsed_seconds=elapsed, response_bytes=nchar(encoded, type="bytes"))
  }, args=list(getwd(), .libPaths(), method))
  peak <- 0
  handle <- ps::ps_handle(child$get_pid())
  while (child$is_alive()) {
    rss <- tryCatch(ps::ps_memory_info(handle)[["rss"]], error=function(e) 0)
    peak <- max(peak, rss)
    Sys.sleep(.02)
  }
  result <- child$get_result()
  result$sampled_peak_rss_mib <- round(peak / 1024^2, 1)
  result
})
report <- list(platform=R.version$platform, r_version=R.version.string,
  caveat="Demo measurements only; sampled RSS can miss peaks. Excludes HTTP transport. Not a Cloud Run memory/latency guarantee.",
  methods=results)
dir.create("test-results", showWarnings=FALSE)
jsonlite::write_json(report, "test-results/benchmark.json", auto_unbox=TRUE, pretty=TRUE)
cat(jsonlite::toJSON(report, auto_unbox=TRUE, pretty=TRUE), "\n")
