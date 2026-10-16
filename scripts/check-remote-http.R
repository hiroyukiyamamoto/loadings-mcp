if(dir.exists(".library")) .libPaths(c(normalizePath(".library"),.libPaths()))
url <- Sys.getenv("MCP_ENDPOINT")
if(!grepl("^https://[^/]+/mcp$",url)) stop("Set the actual MCP_ENDPOINT")
base <- httr2::request(url) |> httr2::req_timeout(35) |>
  httr2::req_headers(Accept="application/json, text/event-stream") |>
  httr2::req_error(is_error=function(resp) FALSE)
token <- Sys.getenv("CLOUD_RUN_ID_TOKEN")
authenticated <- base
if(nzchar(token)) authenticated <- httr2::req_auth_bearer_token(base,token)
payload <- list(jsonrpc="2.0",id=1L,method="initialize",params=list(protocolVersion="2025-06-18",
  capabilities=structure(list(),names=character()),clientInfo=list(name="loadings-http-check",version="1")))
anonymous <- base |> httr2::req_body_json(payload) |> httr2::req_perform()
if(nzchar(token)) stopifnot(httr2::resp_status(anonymous)==403L)
bad_json <- authenticated |> httr2::req_body_raw("{",type="application/json") |> httr2::req_perform()
stopifnot(httr2::resp_status(bad_json)==400L)
unknown <- authenticated |> httr2::req_body_json(list(jsonrpc="2.0",id=2L,method="unknown_method")) |>
  httr2::req_perform() |> httr2::resp_body_json()
stopifnot(unknown$error$code == -32601)
recovery <- authenticated |> httr2::req_body_json(payload) |> httr2::req_perform() |> httr2::resp_body_json()
stopifnot(nzchar(recovery$result$protocolVersion))
report <- list(endpoint=url,anonymous_status=httr2::resp_status(anonymous),invalid_json_status=httr2::resp_status(bad_json),
  unknown_method_error=unknown$error$code,recovery_initialize=TRUE)
dir.create("test-results",showWarnings=FALSE)
jsonlite::write_json(report,"test-results/remote-http.json",auto_unbox=TRUE,pretty=TRUE)
cat(jsonlite::toJSON(report,auto_unbox=TRUE,pretty=TRUE),"\n")
