isolated_worker <- function(fn, args, timeout) {
  tryCatch(callr::r(fn, args=args, timeout=timeout, show=FALSE, supervise=TRUE),
    error = function(e) list(ok = FALSE, warnings = list(), error = list(
      code = if(inherits(e,"callr_timeout_error")) "computation_timeout" else "analysis_error",
      message = if(inherits(e,"callr_timeout_error")) "Analysis exceeded the 20-second computation limit" else "Analysis worker failed")))
}
run_bounded_analysis <- function(name, arguments, timeout = 20) {
  allowed <- c("demo_data", "analyze_pca", "analyze_model", "analyze_multiset")
  if (!name %in% allowed) stop("Unknown analysis worker")
  isolated_worker(function(root, lib, name, arguments) {
    setwd(root); .libPaths(lib)
    source("R/utils.R"); source("R/analysis.R")
    fn <- switch(name, demo_data = demo_data, analyze_pca = analyze_pca,
      analyze_model = analyze_model, analyze_multiset = analyze_multiset)
    do.call(fn, arguments)
  }, args = list(getwd(), .libPaths(), name, arguments), timeout = timeout)
}
