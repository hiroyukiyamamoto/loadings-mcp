if(dir.exists(".library")) .libPaths(c(normalizePath(".library"),.libPaths()))
url <- Sys.getenv("MCP_ENDPOINT")
if(!grepl("^https?://[^/]+/mcp$",url)) stop("Set MCP_ENDPOINT")
req <- httr2::request(url) |> httr2::req_timeout(30) |> httr2::req_error(is_error=function(resp) FALSE)
token <- Sys.getenv("CLOUD_RUN_ID_TOKEN")
if(nzchar(token)) req <- httr2::req_auth_bearer_token(req,token)
large <- req |> httr2::req_body_raw(charToRaw(strrep("x",2*1024^2+1)),type="application/json") |> httr2::req_perform()
stopifnot(httr2::resp_status(large)==413L)
statuses <- integer()
for(i in seq_len(30)) {
  resp <- req |> httr2::req_body_raw("{",type="application/json") |> httr2::req_perform()
  statuses <- c(statuses,httr2::resp_status(resp))
  if(tail(statuses,1)==429L) break
}
stopifnot(429L %in% statuses,all(statuses %in% c(400L,429L)))
# The limiter's burst debt must expire before recovery is tested.
Sys.sleep(12)
recovery <- req |> httr2::req_body_json(list(jsonrpc="2.0",id=1L,method="initialize",
  params=list(protocolVersion="2025-06-18",capabilities=structure(list(),names=character()),
    clientInfo=list(name="limits-test",version="1")))) |> httr2::req_perform()
stopifnot(httr2::resp_status(recovery)==200L,nzchar(httr2::resp_body_json(recovery)$result$protocolVersion))
report <- list(endpoint=url,oversize_status=413L,burst_statuses=as.list(statuses),recovery=TRUE)
dir.create("test-results",showWarnings=FALSE)
jsonlite::write_json(report,"test-results/limits.json",auto_unbox=TRUE,pretty=TRUE)
cat(jsonlite::toJSON(report,auto_unbox=TRUE,pretty=TRUE),"\n")
