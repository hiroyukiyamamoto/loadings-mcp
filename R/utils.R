fail <- function(message) stop(message, call. = FALSE)
scalar_integer <- function(x, name, lo, hi) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x != floor(x) || x < lo || x > hi)
    fail(sprintf("%s must be an integer between %s and %s", name, lo, hi))
  as.integer(x)
}
scalar_number <- function(x, name, lo, hi) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < lo || x > hi)
    fail(sprintf("%s must be between %s and %s", name, lo, hi))
  x
}
numeric_matrix <- function(x, name, min_rows = 1L) {
  if (is.list(x) && identical(names(x), "rows")) x <- x$rows
  # ellmer converts nested numeric arrays to a matrix before invoking a tool.
  if (is.matrix(x)) {
    if (!is.numeric(x) || nrow(x) < min_rows || nrow(x) > 500L || ncol(x) < 1L || ncol(x) > 400L || length(x) > 50000L || any(!is.finite(x)))
      fail(paste(name, "must be a finite numeric matrix within the size limits"))
    return(x)
  }
  if (!is.list(x) || !length(x) || length(x) > 500L) fail(paste(name, "must be a row array with at most 500 rows"))
  sizes <- lengths(x)
  if (length(x) < min_rows || any(sizes < 1L) || length(unique(sizes)) != 1L || sizes[1] > 400L || sum(sizes) > 50000L)
    fail(paste(name, "has invalid dimensions; maximum 400 columns and 50000 cells"))
  rows <- lapply(x, function(row) {
    if (is.list(row)) {
      if (any(lengths(row) != 1L) || !all(vapply(row, is.numeric, logical(1)))) fail(paste(name, "must contain numbers"))
      row <- unlist(row, use.names = FALSE)
    }
    if (!is.numeric(row) || any(!is.finite(row))) fail(paste(name, "must contain finite numbers, without missing values"))
    row
  })
  do.call(rbind, rows)
}
matrix_input <- function(x) list(rows = lapply(seq_len(nrow(x)), function(i) unname(as.list(x[i, ]))))
matrix_result <- function(x, limit, components) {
  if (is.null(x)) return(NULL)
  x <- as.matrix(x)
  nr <- min(nrow(x), limit); nc <- min(ncol(x), components)
  value <- x[seq_len(nr), seq_len(nc), drop = FALSE]
  list(values = unname(lapply(seq_len(nr), function(i) unname(lapply(value[i, ], function(v) if (is.finite(v)) v else "not_finite")))),
       total_rows = nrow(x), total_columns = ncol(x), returned_rows = nr,
       returned_columns = nc, truncated = nr < nrow(x) || nc < ncol(x),
       nonfinite_values = sum(!is.finite(value)))
}
safe_analysis <- function(expr) {
  warnings <- character()
  tryCatch({
    result <- withCallingHandlers(expr, warning = function(w) {
      warnings <<- unique(c(warnings, conditionMessage(w)))
      invokeRestart("muffleWarning")
    })
    remove_null <- function(x) {
      if (!is.list(x)) return(x)
      lapply(Filter(Negate(is.null), x), remove_null)
    }
    result <- remove_null(result)
    result$warnings <- as.list(warnings)
    result$ok <- TRUE
    result
  }, error = function(e) list(ok = FALSE, error = list(code = "analysis_error", message = conditionMessage(e)), warnings = as.list(warnings)))
}
