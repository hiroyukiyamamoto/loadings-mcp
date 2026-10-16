if(dir.exists(".library")) .libPaths(c(normalizePath(".library"),.libPaths()))
source("R/utils.R")
url<-Sys.getenv("MCP_ENDPOINT")
if(!grepl("^https://[^/]+/mcp$",url)) stop("Set MCP_ENDPOINT")
entry<-list(url=url,timeout=35)
if(nzchar(Sys.getenv("CLOUD_RUN_ID_TOKEN"))) entry$headers<-list(Authorization="Bearer ${CLOUD_RUN_ID_TOKEN}")
config<-tempfile(fileext=".json")
jsonlite::write_json(list(mcpServers=list(loadings=entry)),config,auto_unbox=TRUE)
tools<-mcptools::mcp_tools(config);unlink(config)
names(tools)<-vapply(tools,function(t)t@name,character(1))
set.seed(20261017)
X<-matrix_input(matrix(round(rnorm(50000),6),125,400))
Y<-matrix_input(diag(3)[rep(1:3,length.out=125),])
D<-matrix_input(diff(diag(3)))
blocks<-list(sets=lapply(1:4,function(i)list(name=paste0("block",i),data=matrix_input(matrix(round(rnorm(25000),6),125,200)))))
weights<-function(n)matrix_input(matrix(1,n,n)-diag(n))
out<-list()
invoke<-function(name,args,label) {
  elapsed<-system.time(result<-do.call(tools[[name]],args))[["elapsed"]]
  if(inherits(result,"ellmer::ContentToolResult"))result<-result@value
  if(is.character(result))result<-jsonlite::fromJSON(result,simplifyVector=FALSE)
  if(!isTRUE(result$ok)) stop(paste(label,jsonlite::toJSON(result,auto_unbox=TRUE)))
  out[[label]]<<-list(ok=TRUE,elapsed_seconds=elapsed)
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
