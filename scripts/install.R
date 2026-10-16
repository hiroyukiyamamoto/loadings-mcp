dir.create(".library", showWarnings = FALSE)
.libPaths(c(normalizePath(".library"), .libPaths()))
options(repos = c(CRAN = "https://cloud.r-project.org"))
install.packages(c("remotes", "jsonlite", "testthat", "callr"))
remotes::install_version("ellmer", version = "0.5.0", upgrade = "never")
remotes::install_version("httr2", version = "1.3.0", upgrade = "never")
remotes::install_version("loadings", version = "0.6.1", upgrade = "never")
# HTTP and session_tools APIs verified against this exact upstream revision.
archive <- tempfile(fileext = ".tar.gz")
download.file("https://codeload.github.com/posit-dev/mcptools/tar.gz/ff94da04ccb5e6e86a56537c9d2dcb0e0532067b", archive, mode = "wb")
remotes::install_local(archive, upgrade = "never")
unlink(archive)
stopifnot(as.character(packageVersion("loadings")) == "0.6.1", as.character(packageVersion("ellmer")) == "0.5.0",
          as.character(packageVersion("mcptools")) == "1.0.3.9000")
