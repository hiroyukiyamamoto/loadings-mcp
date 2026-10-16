if(dir.exists(".library")) .libPaths(c(normalizePath(".library"),.libPaths()))
source("R/utils.R")
url<-Sys.getenv("MCP_ENDPOINT")
if(!grepl("^https://[^/]+/mcp$",url)) stop("Set MCP_ENDPOINT")
# The official R client's schema conversion is slow for 100,000 cells. The demo
# suite covers that client; use raw HTTP calls here to measure server capacity.
req<-httr2::request(url) |> httr2::req_timeout(35) |>
  httr2::req_headers(Accept="application/json, text/event-stream",`MCP-Protocol-Version`="2025-06-18")
token<-Sys.getenv("CLOUD_RUN_ID_TOKEN")
if(nzchar(token)) req<-httr2::req_auth_bearer_token(req,token)
init<-req |> httr2::req_body_json(list(jsonrpc="2.0",id=0L,method="initialize",params=list(
  protocolVersion="2025-06-18",capabilities=structure(list(),names=character()),
  clientInfo=list(name="capacity-http-test",version="1")))) |> httr2::req_perform() |> httr2::resp_body_json()
stopifnot(nzchar(init$result$protocolVersion))
invisible(req |> httr2::req_body_json(list(jsonrpc="2.0",method="notifications/initialized")) |> httr2::req_perform())
set.seed(20261017)
X<-matrix_input(matrix(round(rnorm(50000),6),125,400))
Y<-matrix_input(diag(3)[rep(1:3,length.out=125),])
D<-matrix_input(diff(diag(3)))
blocks<-list(sets=lapply(1:4,function(i)list(name=paste0("block",i),data=matrix_input(matrix(round(rnorm(25000),6),125,200)))))
weights<-function(n)matrix_input(matrix(1,n,n)-diag(n))
out<-list()
invoke<-function(name,args,label) {
  elapsed<-system.time({
    result<-req |> httr2::req_body_json(list(jsonrpc="2.0",id=1L,method="tools/call",params=list(name=name,arguments=args))) |>
      httr2::req_perform() |> httr2::resp_body_json()
    if(!is.null(result$error))stop(jsonlite::toJSON(result$error,auto_unbox=TRUE))
    result<-jsonlite::fromJSON(result$result$content[[1]]$text,simplifyVector=FALSE)
  })[["elapsed"]]
  if(!isTRUE(result$ok)) stop(paste(label,jsonlite::toJSON(result,auto_unbox=TRUE)))
  out[[label]]<<-list(ok=TRUE,elapsed_seconds=elapsed)
  cat(label,"passed in",elapsed,"seconds\n")
}
invoke("analyze_pca",list(x=X,components=2L,max_rows=5L),"pca_50000_cells")
for(method in c("os_pca","pls_rog","pls_da","rcca_da")) {
  d<-if(method=="os_pca")matrix_input(diff(diag(125)))else D
  invoke("analyze_model",list(method=method,x=X,y=Y,d=d,max_rows=5L),paste0(method,"_50000_cells"))
}
for(method in c("multipls","multipls_rog","unsv_multipls"))invoke("analyze_multiset",
  list(method=method,blocks=blocks,tau=weights(if(method=="unsv_multipls")4 else 5),y=Y,d=D,max_rows=5L),paste0(method,"_100000_cells"))
dir.create("test-results",showWarnings=FALSE)
jsonlite::write_json(out,"test-results/capacity.json",auto_unbox=TRUE,pretty=TRUE)
cat(jsonlite::toJSON(out,auto_unbox=TRUE,pretty=TRUE),"\n")
