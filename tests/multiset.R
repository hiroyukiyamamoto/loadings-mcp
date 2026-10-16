source("tests/pca.R")
demo <- demo_data("whhl")
X <- lapply(demo$blocks$sets, function(block) numeric_matrix(block$data, "block"))
Y <- numeric_matrix(demo$y,"y"); D <- numeric_matrix(demo$d,"d")
for (method in c("multipls", "multipls_rog", "unsv_multipls")) {
  tau <- if(method == "unsv_multipls") demo$unsupervised_tau else demo$tau
  r <- analyze_multiset(method, demo$blocks, tau, demo$y, demo$d, max_rows=5)
  stopifnot(r$ok, length(r$blocks)==4, r$blocks[[4]]$scores$returned_rows==5)
  w <- numeric_matrix(tau,"tau")
  ref <- switch(method, multipls=loadings::multipls_loading(loadings::multipls_geigen(X,Y,w)),
    multipls_rog=loadings::multiplsrog_loading(loadings::multipls_rog(X,Y,w,D)),
    unsv_multipls=loadings::unsvmultipls_loading(loadings::unsv_multipls(X,w)))
  stopifnot(isTRUE(all.equal(unlist(r$blocks[[4]]$loadings$values[[1]]),unname(ref$loading$R[[4]][1,1:2]))))
  cat(method,"official result and four-block output passed\n")
}
bad <- demo$blocks; bad$sets[[2]]$data$rows <- bad$sets[[2]]$data$rows[-1]
stopifnot(!analyze_multiset("multipls",bad,demo$tau,demo$y)$ok,
 !analyze_multiset("multipls",demo$blocks,demo$unsupervised_tau,demo$y)$ok,
 !analyze_multiset("multipls_rog",demo$blocks,demo$tau,demo$y,list(rows=list(c(1,2))))$ok)
duplicate <- demo$blocks; duplicate$sets[[2]]$name <- duplicate$sets[[1]]$name
invalid_tau <- demo$tau; invalid_tau$rows[[1]][[1]] <- 1
stopifnot(!analyze_multiset("multipls",duplicate,demo$tau,demo$y)$ok,
 !analyze_multiset("multipls",demo$blocks,invalid_tau,demo$y)$ok,
 !analyze_multiset("unknown",demo$blocks,demo$tau,demo$y)$ok)
